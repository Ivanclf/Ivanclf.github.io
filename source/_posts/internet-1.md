---
title: 计网协议杂记
date: 2024-08-01 22:20:04
tags: [碎片知识]
---

## URL

URL(Uniform Resource Locators)是统一资源定位器的简称，Web浏览器通过URL从Web服务器请求页面。其一般格式为：

```leaf
protocol :// hostname[:port] / path / [;parameters][?query]#fragment([]中内容可省略)
```

|类型名|说明|
|-|-|
|protocol (协议)|指定使用的传输协议|
|hostname (主机名)|存放资源的DNS(域名服务器)主机名或IP地址|
|port (端口号)|省略时使用协议的默认端口号|
|path (路径)|表示文件地址或者响应的接口|
|;parameters (参数)|指定特定参数的可选项|
|?query (查询)|给一些动态网页传递多个参数，参数间一般用”&”隔开，参数的名和值用”=”隔开|
|fragment|信息片段|

{% note info %}
常用的传输协议有

- `file`本地计算机文件
- `http`超文本传输协议，不加密的普通网页
- `https`在SSL证书的加持下的安全网页
- `ftp`文件传输协议
{% endnote %}

## MIME简述

媒体类型（也通常称为多用途互联网邮件扩展或 MIME 类型）是一种标准，用来表示文档、文件或一组数据的性质和格式。浏览器通常通过MIME类型而非文件扩展名来决定如何处理URL。
其格式为：`type/subtype` ，即一个类型和一个子类型。类型分为独立类型和多部粉类型，多部份类型可分成不同部分的独立文件。以下是一些常用的类型。

### application

不明确类型

|类型名|说明|
|-|-|
|`application/octet-stream`|二进制文件的默认值，浏览器一般不会自动执行|
|`application/pks8`|密钥|
|`application/pdf`|略|
|`application/zip`|略|

### text

纯文本数据

|类型名|说明|
|-|-|
|`text/plain`|文本文件的默认值|
|`text/css`|略|
|`text/html`|略|
|`text/javascript`|略|

### image

图像数据

|类型名|说明|
|-|-|
|`image/apng`|略|
|`image/gif`|略|
|`image/svg+xml`|矢量图|
|`image/...`|...|

### audio / video

音视频数据

|类型名|说明|
|-|-|
|`audio/wave`<br>`audio/wav`<br>`audio/x-wav`<br>`audio/x-pn-wav`|使用WAVE容器的音频文件|
|`audio/webm`<br>`video/webm`|使用WebM容器的音视频文件|
|`audio/ogg`<br>`video/ogg`<br>`application/ogg`|使用OGG容器的音视频文件|

### mutipart

由多个部件组成的数据

|类型名|说明|
|-|-|
|`mutipart/form-data`|通过HTML表单从浏览器发送信息给服务器|
|`mutipart/byteranges`|把部分响应报文发送回浏览器|

## HTTP方法

HTTP 定义了一组请求方法，以表明要对给定资源执行的操作。指示针对给定资源要执行的期望动作。

|方法名|说明|
|-|-|
|`GET`|获取资源，请求一个指定资源的表示形式。用于请求已被URL识别的资源，常用于向服务器查询信息|
|`POST`|传输实体文本|
|`HEAD`|获得报文首部。获取和`GET`请求相同的响应，但没有响应体|
|`PUT`|传输文件|
|`DELETE`|删除文件|
|`OPTION`|询问支持的方法|
|`TRACE`|追踪路径|
|`CONNECT`|使用隧道协议进行TCP通信|
