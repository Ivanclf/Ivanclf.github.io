---
title: 常见业务模型 - OSS 、操作系统集成与 FFmpeg
date: 2026-02-04 14:03:33
tags: [java]
category: 业务
---

## 阿里云 OSS

### 创建配置类

使用以下方法，创建 OSS 的内网或外网客户端, 并将其统一注册到 spring 里.

```java
@Configuration
@Slf4j
public class OssConfig {

    @Value("${aliyun.oss.endpoint:}")
    private String endpoint;

    @Value("${aliyun.oss.publicEndpoint:}")
    private String publicEndpoint;

    @Value("${aliyun.oss.accessKeyId:}")
    private String accessKeyId;

    @Value("${aliyun.oss.accessKeySecret:}")
    private String accessKeySecret;

    /**
     * 内网OSS客户端Bean
     */
    @Bean("internalOssClient")
    @Primary
    public OSS internalOssClient() {
        log.info("创建内网OSS客户端Bean: endpoint={}", endpoint);
        return new OSSClientBuilder().build(endpoint, accessKeyId, accessKeySecret);
    }

    /**
     * 外网OSS客户端Bean
     */
    @Bean("publicOssClient")
    public OSS publicOssClient() {
        String publicEndpointToUse = StringUtils.hasText(publicEndpoint) ? publicEndpoint : endpoint;
        log.info("创建外网OSS客户端Bean: endpoint={}", publicEndpointToUse);
        return new OSSClientBuilder().build(publicEndpointToUse, accessKeyId, accessKeySecret);
    }

    /**
     * 应用关闭时清理资源
     */
    @PreDestroy
    public void cleanup() {
        // Spring会自动调用Bean的destroy方法，OSS客户端会自动shutdown
        log.info("OSS客户端资源清理完成");
    }
}
```

### 一次传输

#### 上传文件

上传文件时的入参为 `MultipartFile` 文件对象, 传输路径 `path`. 步骤如下

##### 参数校验

```java
// 文件非空校验
if (file == null || file.isEmpty()) // 抛异常或返回错误信息
// 校验路径参数
if (!StringUtils.hasText(path)) // 抛异常或使用默认路径
```

##### 生成对象唯一键

代码处的规则是 `path/yyyyMMdd/uuid_原始文件名`

```java
String dateFolder = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")); // 日期
String uuid = UUID.randomUUID().toString().replace("-", ""); // uuid 部分
String key = String.format("%s/%s/%s_%s", path, dateFolder, uuid, file.getOriginalFilename()); // 最后的键
```

##### 执行上传

```java
// 上传文件流
try (InputStream inputStream = file.getInputStream()) {
    PutObjectRequest putObjectRequest = new PutObjectRequest(
        bucketName,
        key,
        inputStream
    );
    ossClient.putObject(putObjectRequest);
}
```

##### 获取文件 url

```java
fileUrl = url + "/api/oss/url/get?objectKey=" + key;
log.info("文件上传成功: objectKey={}, fileUrl={}", key, fileUrl);
```

##### 关闭资源

无论如何，在打开 OSS 配置类后，都要注意关闭资源。但如果注册在 Bean 中，只需要打相关注释就好了。

```java
finally {
    if (ossClient != null) {
        ossClient.shutdown();
    }
}
```

#### 下载文件

入参为文件的 `key` 和响应体。步骤如下

##### 检查文件是否存在

```java
if (!ossClient.doesObjectExist(bucketName, objectKey)) {
    log.warn("文件不存在: objectKey={}", objectKey);
    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
    response.getWriter().write("文件不存在");
    return;
}
```

##### 获取 OSS 文件流

```java
OSSObject ossObject = ossClient.getObject(bucketName, objectKey);
```

##### 写入响应流

```java
// 设置下载响应头
String fileName = objectKey.substring(objectKey.lastIndexOf("/") + 1);
response.setContentType(MediaType.APPLICATION_OCTET_STREAM_VALUE);
response.setHeader(HttpHeaders.CONTENT_DISPOSITION,
    "attachment; filename=" + URLEncoder.encode(fileName, StandardCharsets.UTF_8));

// 流拷贝
try (InputStream inputStream = ossObject.getObjectContent();
        OutputStream outputStream = response.getOutputStream()) {

    byte[] buffer = new byte[1024];
    int bytesRead;
    while ((bytesRead = inputStream.read(buffer)) != -1) {
        outputStream.write(buffer, 0, bytesRead);
    }
    outputStream.flush();
}
log.info("文件下载成功: objectKey={}", objectKey);
```

#### 通过文件 key 获取临时访问 url (带签名, 1 小时过期)

客户端配置为: 开启了 CNAME, 使用 V4 签名, 用完关闭客户端.

```java
public String getFileUrl(String objectKey) {
    // 创建公网客户端
    OSS ossClient = createPublicOssClient();

    // 创建客户端配置
    ClientBuilderConfiguration clientBuilderConfiguration = new ClientBuilderConfiguration();
    clientBuilderConfiguration.setSupportCname(true);
    clientBuilderConfiguration.setSignatureVersion(SignVersion.V4);

    try {
        // 指定生成的预签名URL过期时间，1 小时
        Date expiration = new Date(new Date().getTime() + 3600 * 1000L);
        GeneratePresignedUrlRequest request = new GeneratePresignedUrlRequest(bucketName, objectKey, HttpMethod.GET);
        request.setExpiration(expiration);

        // 通过HTTP GET请求生成预签名URL
        URL signedUrl = ossClient.generatePresignedUrl(request);
        return signedUrl.toString();
    } catch (Exception e) {
        log.error("获取 URL 数据异常", e);
    } finally {
        if (ossClient != null) {
            ossClient.shutdown();
        }
    }
    return null;
}
```

### 断点重传

断点重传的核心在于给文件分片，并提供相应的合并和提示机制。

## 系统

### 系统属性信息

通过 `System.getProperties()` 获取操作系统, JVM, 用户等基础环境信息. 直接通过键名取值即可.

```java
Properties props = System.getProperties();
// 常用系统属性
System.out.println("操作系统名称: " + props.getProperty("os.name"));
System.out.println("操作系统版本: " + props.getProperty("os.version"));
System.out.println("操作系统架构: " + props.getProperty("os.arch"));
System.out.println("Java版本: " + props.getProperty("java.version"));
System.out.println("Java安装路径: " + props.getProperty("java.home"));
System.out.println("用户名称: " + props.getProperty("user.name"));
System.out.println("用户工作目录: " + props.getProperty("user.dir"));
```

### 运行时信息

通过 `Runtime` 获取 JVM 内存使用, CPU 核心数等运行时信息（内存、CPU 等）

```java
Runtime runtime = Runtime.getRuntime();
long totalMemory = runtime.totalMemory() / 1024 / 1024; // 总内存（JVM初始分配的内存）
long maxMemory = runtime.maxMemory() / 1024 / 1024;     // 最大可用内存（JVM能申请的最大内存）
long freeMemory = runtime.freeMemory() / 1024 / 1024;   // 空闲内存
long usedMemory = totalMemory - freeMemory;             // 已使用内存
int processors = runtime.availableProcessors();         // CPU核心数
```

### 执行系统命令

一般使用 `Runtime.getRuntime().exec(command)` 函数执行系统命令, 并使用一个 `Precess` 对象来接收执行的结果.

以 `ping` 命令为例。

```java
String command = "ping www.baidu.com";
Process process = Runtime.getRuntime().exec(command);
```

然后通过这个 Process 对象，我们可以
- 获取该进程的输出流
- 获取该进程的错误流
- 等待进程执行完成
- 获取进程的退出码

输出流和错误流均为 `InputStream`，注意一定要及时读取，否则新进程的输出缓冲区可能会被占满，从而导致进程阻塞, 直接卡死, 无法结束

```java
BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
BufferedReader errorReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));

// 读取标准输出
String line;
while ((line = reader.readLine()) != null) {
    // ...
}

// 读取错误输出
String errorLine;
while ((errorLine = errorReader.readLine()) != null) {
    // ...
}
```

其他两种操作为

```java
process.waitFor();                  // 等待命令执行完成
int exitCode = process.exitValue(); // 获取执行退出码
```

### 正则表达式匹配

Java 中的正则必须先编译为 NFA/DFA 结构才能匹配, 若单纯使用 `String.matches()` 方法, 则每次调用都需要重新编译, 在大量匹配的场景下性能极差. 因此推荐提前编译 Patten 并复用.

```java
// 定义正则表达式模式
final String hz = "(?<=,)[0-9]+(?=Hz)";         // 提取采样率
final String bit_rate = "(?<=,)[0-9]+(?=kb)";   // 提取比特率
Pattern bit_rate_pattern = Pattern.compile(bit_rate);
Pattern hz_pattern = Pattern.compile(hz);
```

各个 pattern 就是已经编译好的结果了，然后再直接匹配即可。

```java
// 解析错误输出中的音频信息
String errorLine;
while ((errorLine = errorReader.readLine()) != null) {
    errorLine = errorLine.replace(" ", "");
    
    // 检测声道
    if (errorLine.contains("mono")) {
        map.put(STR_CHANNELS, 1);
    }
    
    // 提取比特率
    Matcher bit_matcher = bit_rate_pattern.matcher(errorLine);
    if (bit_matcher.find()) {
        map.put(STR_BIT, bit_matcher.group());
    }
    
    // 提取采样率
    Matcher hz_matcher = hz_pattern.matcher(errorLine);
    if (hz_matcher.find()) {
        map.put(STR_HZ, hz_matcher.group());
    }
}
```

## FFmepg

FFmpeg 通过命令行调用，整个调用过程及其考验其命令拼接能力

### 转换文件格式

以 `.mp3` 转换为 `wav` 文件为例

```java
public static String convertMp3ToWav(String tempPath, String fileName, boolean isDelFile) {
    String name1 = fileName.split(".mp3")[0];
    String from = tempPath + File.separator + fileName;
    String to = tempPath + File.separator + name1 + ".wav";
    try {
        String command = ffmpegPath + File.separator + "ffmpeg -i " + from + " " + to;
        log.info("Executing command: {}", command);
        Process proc = Runtime.getRuntime().exec(command);
        proc.waitFor();
        
        // 根据参数决定是否删除源文件
        if (isDelFile) {
            FileUtil.del(new File(from));
        }
    } catch (Exception ex) {
        log.error("Error converting MP3 to WAV: {}", fileName, ex);
    }
    return to;
}
```

### 从视频文件提取中音频

```java
public static String decodeVideo(File videoFile, String outPath) {
    try {
        if (!videoFile.exists()) {
            return null;
        }
        // 生成输出文件名
        String fileName = videoFile.getName();
        String name = fileName.substring(0, fileName.lastIndexOf("."));
        String outFile = outPath + name + "_" + DateUtil.current() + ".wav";
        
        String command =  ffmpegPath + File.separator + "ffmpeg -i " + videoFile.getAbsolutePath() + " -c:a pcm_s16le " + outFile;
        Process proc = Runtime.getRuntime().exec(command);
        handleProcessOutput(proc);
        proc.waitFor();
        return outFile;

    } catch (Exception e) {
        log.error("视频音频提取失败", e);
        return null;
    }
}
```

### 从视频中截取图片帧

```java
public static String extractFrames(File videoFile, String outPath) {
    try {
        if (!videoFile.exists()) {
            return null;
        }
        String outFile = outPath + "%05d.png";
        String command =  ffmpegPath + File.separator + "ffmpeg -i " + videoFile.getAbsolutePath() + " -r 1/5 " + outFile;
        Process proc = Runtime.getRuntime().exec(command);
        handleProcessOutput(proc);
        proc.waitFor();
        return outPath;
    } catch (Exception e) {
        log.error("视频截图失败", e);
        return null;
    }
}
```

### 剪辑视频

```java
public static boolean cropVideo(String inputVideoPath, String outputVideoPath,
                                int x, int y, int width, int height) {
    try {
        // 构建FFmpeg命令
        String[] command = {
                ffmpegPath + File.separator + "ffmpeg",
                "-i", inputVideoPath,           // 输入文件
                "-filter:v", "crop=" + width + ":" + height + ":" + x + ":" + y,
                "-c:a", "copy",
                "-y",                           // 覆盖输出文件
                outputVideoPath                 // 输出文件
        };

        Process process = new ProcessBuilder(command).start();
        handleProcessOutput(process);
        int exitCode = process.waitFor();
        return exitCode == 0;
    } catch (Exception e) {
        log.error("视频裁剪失败: {}", e.getMessage(), e);
        return false;
    }
}
```