---
title: 计网协议杂记
date: 2024-08-01 22:20:04
tags: [碎片知识]
category: 计网
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

{% note success %}
除了 URL，还有 **URI** 的概念，URI (Uniform Resource Identifier) 是统一资源标识符的简称，用于唯一标识一个资源，但 URL 不仅标识一个资源，还指明了如何 locate 这个资源。
{% endnote %}

参考文献

- [https://javaguide.cn/system-design/basis/RESTfulAPI.html](https://javaguide.cn/system-design/basis/RESTfulAPI.html)

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

## RestFul API

RestFul API 也叫 REST API，REST 是 `REpresentational State Transfer` 的缩写，或者简单点，是 **Resource Representational State Transfer** 的缩写

- Resource 一个资源可以是一个集合，也可以是单个个体，每一种资源都有特定的 URI 与之对应
- Representational 资源是一种信息实体，其具体呈现出来的形式，如 `json`、`xml`、`image`、`txt` 等等称为其“表现形式”
- State Transfer 通过 REST 中的状态转移（如 crud）来描述服务器资源端的状态和相关操作

### HTTP 方法

REST API 定义了一组请求方法，以表明要对给定资源执行的操作。指示针对给定资源要执行的期望动作。

|方法名|说明|
|-|-|
|`GET`|获取特定资源，常用于向服务器查询信息|
|`POST`|传输实体文本，在服务器上创建一个新的资源|
|`HEAD`|获得报文首部。获取和`GET`请求相同的响应，但没有响应体|
|`PUT`|传输文件，更新服务器上的资源|
|`DELETE`|删除资源|
|`OPTION`|询问支持的方法|
|`TRACE`|追踪路径|
|`CONNECT`|使用隧道协议进行TCP通信|
|`PATCH`|更新服务器上的资源|

### 状态码

|2xx 成功|3xx 重定向|4xx 客户端错误|5xx 服务器错误|
|-|-|-|-|
|200 **OK**|301 **永久移动**到新 URL|400 **不良请求**|500 **服务器错误**|
|201 已**创建**资源|302 **找到**|401 **未授权**|502 **网关错误**|
|202 **已接受**，但未完成创建资源|303 *见其他*，发送对资源的引用但不强制客户端下载状态|403 **禁止**访问|504 **网关超时**|
|204 **无内容**|304 资源**未修改**，与 204 类似|404 **未找到**|
||307 *临时重定向*，不会处理客户端的请求|405 **方法不允许**|
|||406 响应*不可接受*|
|||412 *前提条件失败*，这里的前提条件通常是客户端要求的|
|||415 *不支持的媒体类型*|

### 命名规范

- 网址和接口中不能有动词，只能有名词，API 中的名词也应该用复数
- 不用大写字母，建议用 `-` 而不是 `_`
- 善用版本化 API
