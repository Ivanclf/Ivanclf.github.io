---
title: 常见业务模型 - 企业系统部分外连接口
date: 2026-01-24 12:48:49
tags: [java]
category: 客服质检
---

## OAuth 2

传统的账密登录需要用户记住天量的账号密码，很不方便，而且对 SSO 的支持很不友好。其解决方案是 OAuth2 协议，即通过跨应用的授权层协议，实现对账户的精细化管理。
1. 用户在授权服务器完成身份认证（可使用传统账密、免密、生物识别等任何方式）。
2. 用户明确授权第三方应用获取「有限权限」（如仅获取昵称头像、仅读取相册、不可修改数据）。
3. 第三方应用仅能拿到对应权限的令牌，只能访问用户授权的资源，且全程无需获取用户的账密。
4. 资源服务器仅对「有对应权限的令牌」提供服务。

### 向第三方要授权

其实现首先需要实现一个可以跳转其他页面的实现接口。用于发起 OAuth2 授权请求。

```java
@GetMapping("/oauth2/authorize")
public String authorize() {
    String url = oauth2Properties.getAuthorizeUrl() +
        "?redirect_uri=" + oauth2Properties.getRedirectUrl() +
        "&state=123&client_id=" + oauth2Properties.getClientId() +
        "&response_type=code";
    log.info("授权url:{}", url);
    return "redirect:" + url;
}
```

然后实现一个回调接口，用于在授权成功后，通过授权码 code 获取访问令牌，并提取 token 和用户相关信息，然后将用户的令牌放 redis 上放 6 小时，最后重定向到 SSO 登录页面。

```java
@GetMapping("/oauth2/callback")
public void callback(@RequestParam("code") String code, HttpServletResponse response) throws IOException {
    // 用code获取token
    JSONObject tokenResponse = getAccessToken(code);
    if (ObjectUtil.isNotEmpty(tokenResponse)) {
        String accessToken = tokenResponse.getString("access_token");
        String uid = tokenResponse.getString("uid");

        if(!oauth2Properties.getUserIdKey().equals("uid")) {
            uid = getUserInfo(oauth2Properties.getClientId(), accessToken, uid);
        }

        String redirectUrl = ssoUrl + "/login.html?" + "token=" + accessToken + "tenantId=default&userId=" + uid;
        redisTemplate.opsForValue().set(REDIS_KEY + accessToken, "true", 6, TimeUnit.HOURS);
        log.info("获取到access_token: {},重定向到login.html, {}", accessToken, redirectUrl);
        response.sendRedirect(redirectUrl);
    } else {
        response.getWriter().write("获取token失败");
    }
}
```

授权接口和回调接口的请求方法强制为 GET。

其中需要的获取 token 的方法，通过授权码获取访问令牌。

```java
private JSONObject getAccessToken(String code) {
    String url = oauth2Properties.getAccessTokenUrl() +
        "?client_id=" + oauth2Properties.getClientId() +
        "&grant_type=authorization_code" +
        "&code=" + code +
        "&client_secret=" + oauth2Properties.getClientSecret();
    // 构建请求头
    HttpHeaders requestHeaders = new HttpHeaders();
    // 指定响应返回json格式
    requestHeaders.add("accept", "application/json");
    // 构建请求实体
    HttpEntity<String> requestEntity = new HttpEntity<>(requestHeaders);
    // post 请求方式
    ResponseEntity<JSONObject> response = restTemplate.postForEntity(url, requestEntity, JSONObject.class);

    // 解析响应json字符串
    return response.getBody();
}
```

通过访问令牌获取用户信息。

```java
private String getUserInfo(String clientId, String accessToken, String uid) {
    String url = String.format(oauth2Properties.getUserInfoUrl(), clientId, accessToken, uid);
    // get 请求方式
    ResponseEntity<JSONObject> response = restTemplate.getForEntity(url, JSONObject.class);
    if(response.getStatusCode().is2xxSuccessful()) {
        // 解析响应json字符串
        return response.getBody().getString(oauth2Properties.getUserIdKey());
    }
    return StringConstants.EMPTY;
}
```

用户授权后，授权服务器拿到的首先是有效时间只有几分钟的**授权码**。授权码只能使用一次。然后服务器通过授权码向授权服务器请求获得用户的**访问令牌**。访问令牌的生效时间则比较长，从几小时到几天不等。

这种授权码和访问令牌分离的设计，可以避免访问令牌通过浏览器重定向传递，从而避免在 URL 中暴露，从而被各种手段捕获。并且，即使授权码被截获，攻击者仍然需要密钥才能获取访问令牌。从而防止中间人攻击。

### 授权给第三方

此处的写法就比较多样了。此处列举使用 GET 方法和 POST 方法的情况。

GET 方法

```java
@Operation(summary = "第三方token校验接口")
@GetMapping(value = "/check")
public ApiResponse<ThdLoginResponse> checkLogin(@RequestParam(name = "userId", required = false) String userId,
                                                @RequestParam(name = "tenantId", required = false) String tenantId,
                                                @RequestParam("sessionId") String sessionId,
                                                @RequestParam("state") String state) {
    ApiResponse<ThdLoginResponse> apiResponse = ApiResponse.successResponse();
    ThdLoginResponse map = thdLoginCheck.checkToken(tenantId, userId, sessionId, state);
    apiResponse.setData(map);
    return apiResponse;
}
```

POST 方法

```java
@Operation(summary = "第三方token校验接口")
@PostMapping(value = "/check")
public ApiResponse<ThdLoginResponse> checkLoginPost(@RequestBody ThdLoginRequest requestBody) {
    ApiResponse<ThdLoginResponse> apiResponse = ApiResponse.successResponse();
    String tenantId = requestBody.getTenantId();
    String userId = requestBody.getUserId();
    String sessionId = requestBody.getSessionId();
    String state = requestBody.getState();
    ThdLoginResponse map = thdLoginCheck.checkToken(tenantId, userId, sessionId, state);
    apiResponse.setData(map);
    return apiResponse;
}
```

令牌的申请、校验和吊销都必须使用 POST 方法。

注意到此处需要的请求都可以使用 resttemplate 实现，oauth-starter 依赖的注入不是必要的。

## 邮件收发

电子邮件的上传由 SMTP 协议实现，而发送由 IAMP 或 POP3 协议实现。作为服务器，需要在合适的时候发送合适的协议，从而有效发送信息。而在发送时，可以按照邮件及其附件的类型，调用不同的接口。

要实现邮件收发的功能，需要注入 javamail 依赖。

相关配置信息如下

```yaml
spring:
  flyway:
    enabled: false
  mail:
    # 邮件服务器地址
    host: smtp.qq.com
    # 协议 默认就是smtp
    protocol: smtps
    # 编码格式 默认就是utf-8
    default-encoding: utf-8
    # 邮箱
    username: example@qq.com
    # 16位授权码 不是邮箱密码
    password: 1145141919815000
    # smtp的指定端口 25端口默认不启用ssl 也就是protoc为smtp, 使用465要将protocol改为smtps并且开启ssl为true
    port: 465   #465
    # 设置开启ssl
    properties:
      mail:
        stmp:
          ssl:
            enable: false
        # 收邮件配置
        receive:
          enable: false
          protocol: pop3
          ssl:
            enable: true
          port: 995     #997
```

### 文字信息

如果信件只是简单的文字信息，则只需要配置好相关信息，直接抄送即可。

```java
public void sendNormalEmailMessage(TextEmailVO mail) {
    // 创建简单邮件消息
    SimpleMailMessage message = new SimpleMailMessage();
    // 发件箱
    message.setFrom(mailUserName);
    // 谁要接收
    message.setTo(mail.getTo());
    // 邮件标题
    message.setSubject(mail.getSubject());
    // 邮件内容
    message.setText(mail.getContent());
    // 抄送的人
    message.setCc(mail.getCc());
    // 发送邮件
    javaMailSender.send(message);
    operatorOfEmail.insert(EmailEntityUtil.convertVo2Do(mail));
}
```

注意，在发送的同时也要在数据库中同步一份数据记录。数据库中应该存放其租户 id、邮件发送时间、消息类型、发送者邮箱、主题、邮件内容、接收者、发送人姓名、发送人用户 id、邮件的附件 OSS 存储地址（或其比特流）、邮件的传输方向、邮件的系统来源这些信息。

### 富文本

富文本相比纯文字多出了图片、表格等信息。此处假设发送的是 HTML 文本文件（足够丰富了），而走的也是纯粹的比特流而非文件流。

```java
public String sendMimeMessage(EmailVO mail, MultipartFile multipartFile) throws MessagingException, IOException {
    MimeMessage message = javaMailSender.createMimeMessage();

    MimeMessageHelper helper = new MimeMessageHelper(message, true);
    helper.setFrom(mailUserName);
    // 谁要接收
    helper.setTo(mail.getTo());
    // 邮件标题
    helper.setSubject(mail.getSubject());
    // 抄送的人
    helper.setCc(mail.getCc());
    // 邮件内容   true 表示带有附件或html
    helper.setText(mail.getContent(), true);

    // 直接走二进制流，不走文件流，上传的是文件流，不是文件服务器的文件地址
    if (!ObjectUtils.isEmpty(multipartFile)) {
        log.info("send email: store email attachment file stream to database");
        byte[] bytes = multipartFile.getBytes();
        String fileName = Optional.ofNullable(multipartFile.getOriginalFilename()).orElse("");
        mail.setBinaryEmailAttachment(bytes);
        mail.setFileName(fileName);
        helper.addAttachment(fileName, new ByteArrayResource(bytes));
    } else {
        if (StringUtils.hasText(mail.getFileAddress())){
            try {
                // 以流的形式下载文件服务器文件
                InputStream fis = new BufferedInputStream(Files.newInputStream(Paths.get(mail.getFileAddress())));
                byte[] buffer = new byte[fis.available()];
                fis.read(buffer);
                fis.close();
                mail.setBinaryEmailAttachment(buffer);
                helper.addAttachment(mail.getFileName(), new ByteArrayResource(buffer));
            } catch (IOException ex) {
                log.error("Error:  {}", ex.getMessage(),ex);
            }
        }
    }
    javaMailSender.send(message);
    EmailDO emailDO = EmailEntityUtil.convertVo2Do(mail);
    operatorOfEmail.insert(emailDO);
    // 查询该邮件的id
    return operatorOfEmail.getEmailId(emailDO);
}
```

其中的 `MultipartFile` 是 Spring Web 中用于处理客户端上传文件的核心接口。用于接收用户上传的文件并封装其元信息（如文件名、大小、字节流等）。

### 附件

单纯传附件的话就更简单了，就是正常的将文件上传到 OSS 或本地存储二进制文件流的操作。

```java
@PostMapping(value ="/uplode/file")
@ResponseBody
public ApiResponse<String> upFileToFileServer(
    @Parameter(description= "文件名") @RequestParam String fileName,
    @Parameter(description= "文件流") @RequestParam(required = false) MultipartFile multipartFile) {
    ApiResponse<String> apiResponse = ApiResponse.successResponse();
    try {
        String url = "http://fileserver/fileserver/put?filechannel=wechat&filetype=doc";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        RestTemplateUtil.postMessage(restTemplate, url,fileName , headers);
        apiResponse.setMessage("文件上传成功");
    } catch (Exception e) {
        apiResponse.setCode(HttpStatus.INTERNAL_SERVER_ERROR.value());
        apiResponse.setStatus("fail");
        apiResponse.setMessage(e.getMessage());
        log.error("upload file failed {}", e.getMessage(), e);
    }
    return apiResponse;
}
```

若文件中既有附件又有富文本，则需要两者共同上传，这考验数据库表的设计能力。

```java
@Operation(summary = "发送富文本含附件邮件")
@PostMapping(value = "/mime/send")
@ResponseBody
public ApiResponse<String> sendAttachmentsMail(
    @Parameter(description= "消息体", required = true) @RequestParam String mail,
    @Parameter(description= "消息附件") @RequestParam(required = false) MultipartFile multipartFile) {
    ApiResponse<String> apiResponse = ApiResponse.successResponse();
    try {
        EmailVO eMailVO = JSONObject.parseObject(mail, EmailVO.class);
        String emailId = mailSendService.sendMimeMessage(eMailVO, multipartFile);
        apiResponse.setData(emailId);
        apiResponse.setMessage("邮件发送成功");
    } catch (Exception e) {
        apiResponse.setCode(HttpStatus.INTERNAL_SERVER_ERROR.value());
        apiResponse.setStatus("fail");
        apiResponse.setMessage(e.getMessage());
        log.error("send attachments mail {}", e.getMessage(), e);
    }
    return apiResponse;
}
```