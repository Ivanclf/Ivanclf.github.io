---
title: 常见业务模型 - OSS 、操作系统集成与 FFmpeg
date: 2026-02-04 14:03:33
tags: [java]
category: 业务
---

## 阿里云 OSS

### 创建配置类

使用以下方法，创建 OSS 的内网或外网客户端

```java
/**
 * 创建OSS客户端（用于外网访问）
 */
private OSS createPublicOssClient() {
    String publicEndpointToUse = StringUtils.hasText(publicEndpoint) ? publicEndpoint : endpoint;
    log.debug("创建外网OSS客户端: endpoint={}, accessKeyId={}, bucketName={}", publicEndpointToUse, accessKeyId, bucketName);
    return new OSSClientBuilder().build(publicEndpointToUse, accessKeyId, accessKeySecret);
}

/**
 * 创建OSS客户端（用于内网操作）
 */
private OSS createOssClient() {
    log.debug("创建内网OSS客户端: endpoint={}, accessKeyId={}, bucketName={}", endpoint, accessKeyId, bucketName);
    return new OSSClientBuilder().build(endpoint, accessKeyId, accessKeySecret);
}
```

{% note info %}
但这里没有注册到 Bean 里，而是每次请求都新建一个 OSS 对象，显然比较浪费。因此比较好的做法是将内网和外网的 OSS 统一注册到 Spring 里。

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
{% endnote %}

### 一次传输

#### 上传文件

上传文件的方法中，需要指明文件本身（即 `MultipartFile` 对象）和传输路径。首先需要进行校验

```java
if (file == null || file.isEmpty()) {
    // 抛异常或返回错误信息
}

// 校验路径参数
if (!StringUtils.hasText(path)) {
    // 抛异常或使用默认路径
}
```

然后生成对象的键

```java
// 生成对象键: path/yyyyMMdd/uuid_原始文件名
String originalFilename = file.getOriginalFilename();
String dateFolder = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
String uuid = UUID.randomUUID().toString().replace("-", "");
String key = String.format("%s/%s/%s_%s", path, dateFolder, uuid, originalFilename);
```

上传文件流本身

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

获取文件 url

```java
String fileUrl = "";
try {
    fileUrl = idpUrl + "/api/oss/url/get?objectKey=" + key;
} catch (Exception e) {
    log.error("获取文件访问URL失败", e);
}
log.info("文件上传成功: objectKey={}, fileUrl={}", key, fileUrl);
```

无论如何，在打开 OSS 配置类后，都要注意关闭资源。但如果注册在 Bean 中，只需要打注释就好了。

```java
finally {
    if (ossClient != null) {
        ossClient.shutdown();
    }
}
```

#### 下载文件

传入的参数为文件的 key 和响应体。

首先需要检查文件是否存在

```java
// 检查文件是否存在
if (!ossClient.doesObjectExist(bucketName, objectKey)) {
    log.warn("文件不存在: objectKey={}", objectKey);
    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
    response.getWriter().write("文件不存在");
    return;
}
```

下载的流程比上传的简单很多，不需要完整拼接全部的 url

```java
// 下载OSS文件
OSSObject ossObject = ossClient.getObject(bucketName, objectKey);
```

然后包装请求体，将其变成特定的格式

```java
// 设置响应头
String fileName = objectKey.substring(objectKey.lastIndexOf("/") + 1);
response.setContentType(MediaType.APPLICATION_OCTET_STREAM_VALUE);
response.setHeader(HttpHeaders.CONTENT_DISPOSITION,
    "attachment; filename=" + URLEncoder.encode(fileName, StandardCharsets.UTF_8));

// 写入响应流
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

#### 检查是否存在

这个人家包装好了

```java
boolean exists = ossClient.doesObjectExist(bucketName, objectKey);
```

#### 删除文件

```java
ossClient.deleteObject(bucketName, objectKey);
```

#### 通过文件 key 获取 url

```java
public String getFileUrl(String objectKey) {
    // 创建公网客户端
    OSS ossClient = createPublicOssClient();

    // 创建客户端配置
        ClientBuilderConfiguration clientBuilderConfiguration = new ClientBuilderConfiguration();
        // 请注意，设置true开启CNAME选项
        clientBuilderConfiguration.setSupportCname(true);
        // 显式声明使用 V4 签名算法
        clientBuilderConfiguration.setSignatureVersion(SignVersion.V4);

    try {
        // 指定生成的预签名URL过期时间，单位为毫秒
        Date expiration = new Date(new Date().getTime() + 3600 * 1000L);
        // 生成预签名URL
        GeneratePresignedUrlRequest request = new GeneratePresignedUrlRequest(bucketName, objectKey, HttpMethod.GET);
        // 设置过期时间
        request.setExpiration(expiration);

        // 通过HTTP GET请求生成预签名URL
        URL signedUrl = ossClient.generatePresignedUrl(request);
        // 打印预签名URL
        log.info("{}预签名URL: {}", objectKey, signedUrl);
        return signedUrl.toString();
    } catch (OSSException oe) {
        log.error("获取OSS数据异常", oe);
    } catch (ClientException ce) {
        log.error("连接OSS异常", ce);
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

若不使用 Hutool 之类的工具，则使用 JDK 内置的方法获取系统内置信息

### 属性信息

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

运行时信息（内存、CPU 等）

```java
Runtime runtime = Runtime.getRuntime();
// 总内存（JVM初始分配的内存）
long totalMemory = runtime.totalMemory() / 1024 / 1024;
// 最大可用内存（JVM能申请的最大内存）
long maxMemory = runtime.maxMemory() / 1024 / 1024;
// 空闲内存
long freeMemory = runtime.freeMemory() / 1024 / 1024;
// 已使用内存
long usedMemory = totalMemory - freeMemory;
// CPU核心数
int processors = runtime.availableProcessors();

```

### 执行系统命令

一般使用 `Runtime.getRuntime().exec(command)` 函数执行系统命令。以下以 `ping` 命令为例。首先我们需要一个 `Precess` 对象来接收执行的结果

```java
String command = "ping www.baidu.com";
Process process = Runtime.getRuntime().exec(command);
```

然后通过这个 Process 对象，我们可以
- 获取该进程的输出流
- 获取该进程的错误流
- 等待进程执行完成
- 获取进程的退出码

输出流和错误流均为 `InputStream`，注意一定要及时读取，否则新进程的输出缓冲区可能会被占满，从而导致进程阻塞，无法结束

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

通过逐行读取，并且查询每一行中有没有特定的字符串，有则设置对应的参数

```java
if (line.contains("mono")) {
    map.put(STR_CHANNELS, 1);
    break;
}
```

### 正则表达式匹配

正则表达式作为一种3型文法，在使用时不能直接用于匹配。在 Java 中，对正则表达式有一个编译的过程，该过程中，JVM 会将正则表达式转换为 NFA，然后简化为 DFA，以数组-哈希表的方式存储。当然，为了支持反向引用、零宽断言等复杂语法，Java 中放着的是尽量 DFA 简化过的 NFA。

因此面对一个新的正则表达式，Java 都会尝试编译一遍。因此使用最简单的 `String.matches()` 在大量匹配的场景中极为低效。更好的办法就是提前编译。这个需要定义一个 `Patten` 类。

```java
// 定义正则表达式模式
final String hz = "(?<=,)[0-9]+(?=Hz)";
final String bit_rate = "(?<=,)[0-9]+(?=kb)";
Pattern bit_rate_pattern = Pattern.compile(bit_rate);
Pattern hz_pattern = Pattern.compile(hz);
```

各个 pattern 就是已经编译好的结果了，然后再直接匹配即可。

```java
// 解析错误输出中的音频信息
String errorLine;
while ((errorLine = errorReader.readLine()) != null) {
    log.info("debug-->{}", errorLine);
    System.out.println("ff" + errorLine);
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
    String result = null;
    try {
        log.info("音频提取-->视频地址路径-->{}", videoFile.getAbsolutePath());
        if (!videoFile.exists()) {
            log.error("视频文件不存在-->{}",videoFile.getAbsolutePath());
            return result;
        }
        
        // 生成输出文件名
        String fileName = videoFile.getName();
        String name = fileName.substring(0, fileName.lastIndexOf("."));
        String outFile = outPath + name + "_" + DateUtil.current() + ".wav";
        
        String command =  ffmpegPath + File.separator + "ffmpeg -i " + videoFile.getAbsolutePath() + " -c:a pcm_s16le " + outFile;
        log.info("音频提取-->转换命令-->{}", command);
        Process proc = Runtime.getRuntime().exec(command);
        handleProcessOutput(proc);
        proc.waitFor();
        log.debug("解码文件 {}", outFile);
        result = outFile;

    } catch (Exception e) {
        log.error("视频音频提取失败", e);
        result = null;
    }
    return result;
}
```

### 从视频中截取图片帧

```java
public static String extractFrames(File videoFile, String outPath) {
    String result = null;
    try {
        log.info("截取图片-->视频地址路径-->{}", videoFile.getAbsolutePath());
        if (!videoFile.exists()) {
            log.error("视频文件不存在-->{}",videoFile.getAbsolutePath());
            return result;
        }
        
        String outFile = outPath + "%05d.png";
        String command =  ffmpegPath + File.separator + "ffmpeg -i " + videoFile.getAbsolutePath() + " -r 1/5 " + outFile;
        log.info("截取图片-->转换命令-->{}", command);
        Process proc = Runtime.getRuntime().exec(command);
        handleProcessOutput(proc);
        proc.waitFor();
        log.debug("截取图片 {}", outPath);
        result = outPath;

    } catch (Exception e) {
        log.error("视频截图失败", e);
        result = null;
    }
    return result;
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
        log.info("视频裁剪命令: {}", String.join(" ", command));
        
        // 执行命令
        Process process = new ProcessBuilder(command).start();
        
        // 处理命令输出
        handleProcessOutput(process);
        
        // 等待进程执行完成
        int exitCode = process.waitFor();
        
        // 退出码为0表示成功
        return exitCode == 0;
    } catch (Exception e) {
        log.error("视频裁剪失败: {}", e.getMessage(), e);
        return false;
    }
}
```