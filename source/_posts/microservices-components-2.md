---
title: 微服务系统组件 - 2
date: 2025-11-11 14:51:08
tags: [java, spring, 分布式, spring-cloud]
categories: web
---

参考文献

- [https://javaguide.cn/distributed-system/api-gateway.html](https://javaguide.cn/distributed-system/api-gateway.html)
- [https://javabetter.cn/sidebar/sanfene/weifuwu.html](https://javabetter.cn/sidebar/sanfene/weifuwu.html)
- [https://www.bilibili.com/video/BV1LQ4y127n4](https://www.bilibili.com/video/BV1LQ4y127n4)
- [https://zhuanlan.zhihu.com/p/715997276](https://zhuanlan.zhihu.com/p/715997276)

## 服务网关

API 网关是一种中间层服务器，用于集中管理、保护和路由对后端服务的访问。其功能主要包括请求转发+请求过滤，但小型要求不少，包括 请求转发、负载均衡、安全认证（对客户端请求进行身份验证并仅允许可新用户访问 api，并且还能够使用类似 RBAC 等方式来授权）、参数校验（支持参数映射和校验逻辑）、日志记录、监控告警、流量控制、熔断降级、响应缓存、响应聚合、灰度发布、异常处理、API 文档、协议转换、协议转换、证书管理，等等。

![参考链路层](up-35e102c633bbe8e0dea1e075ea3fee5dcfb.png)

### Netflix Zuul

Zuul 是 Netflix 开发的一款提供动态路由、监控、弹性、安全的网关服务，可以和 Eureka、Ribbon、Hystrix 等组件组合使用。Zuul 主要通过过滤器来过滤请求，从而实现网关的各种功能。

Zuul 1.x 基于同步 IO，性能较差，而 Zuul 基于 Netty 实现了异步 IO，性能得到了大幅改进。

### Spring Could Gateway

这是属于 Spring Cloud 系统中的网关，基于 Spring WebFlux。Spring WebFlux 使用 Reactor 库实现响应式编程，底层是基于 Netty 实现的同步非阻塞 IO。

一般在网关服务中的配置类文件如下

```yaml
spring:
    cloud:
        gateway:
            routes:
                - id: user-service # 路由标示，必须唯一
                  uri: lb:// userservice # 路由的目标地址
                  predicates: # 路由断言，判断请求是否符合规则
                    - Path=/user/** # 路径断言，判断路径是否是以 /user 开头，如果是则符合
```

具体的流程为
1. 路由判断，客户端的请求结束后，先经过 Gateway Handler Mapping 处理，在这里做断言判断，以映射后端的某个服务
2. 请求过滤，请求到达 Gateway Web Handler，这里面有很多过滤器，组成过滤器链，这些过滤器可以对请求进行拦截和修改，比如添加请求头，参数校验等等
3. 服务处理，后端服务器对请求进行处理
4. 响应过滤，后端处理完结果后，返回给 Gateway 的过滤器再次处理
5. 响应返回，经过过滤处理的结果返回给客户端

{% note info %}
断言是指对某个表达式的真假判断，若为真则跳转到某个路由。基本的 Predicate 工厂为
|名称|说明|实例|
|-|-|-|
|After|某个时间点后的请求|`After=2037-01-20T17:42:47`|
|Before|某个时间点前的请求|`Before=2037-01-20T17:42:47`|
|Between|某个时间段内的请求|`Between=2037-01-20T17:42:47, 2038-01-20T17:42:47`|
|Cookie|请求必须包括某些 Cookie|`Cookie=chocolate,ch.p`|
|Header|请求必须包括某些 header|`Header=X-request-id,\d+`|
|Host|请求必须是访问某个 Host|`Host=**.somehost.org`|
|Method|请求必须是某种方式|`Method=GET,POST`|
|Path|请求路径必须符合指定规则|`Path=/red/**`|
|Query|请求参数必须包含某些参数|`Query=name`|
|RemoteAddr|请求者的 IP 必须是指定范围|`RemoteAddr=192.168.1.1/24`|
|Weight|权重处理|/|

{% endnote %}

要实现网关的动态路由，一般是通过 Nacos 动态配置来做。

网关过滤器有三种，分别是 默认过滤器、路由过滤器、全局过滤器。每一个过滤器都必须指定一个 int 类型的 order 值（可以是负数），order 值最小，优先级越高，执行顺序约靠前。在全局过滤器中，这个 order 可以通过[注解](https://ivanclf.github.io/2025/10/29/spring/#%E9%80%9A%E7%9F%A5)或者实现接口的方式指定；而路由过滤器的顺序由 Spring 指定，默认是按照声明顺序从1指定。当过滤器的 order 值一样时，会按照 默认过滤器 > 路由过滤器 > 全局过滤器的顺序进行。

在 Spring Boot 项目中我们捕获全局异常只需要在项目中配置 `@RestControllerAdvice` 和 `ExceptionHandler` 即可。而在 Spring Cloud Gateway 中，比较常用的是实现 `ErrorWebExceptionHandler` 并重写其中的 `handle` 方法。

### OpenResty

这个基于 Nginx + Lua，并发能力较好，但二次开发门槛较高。

### Kong

这个基于 OpenResty，支持多种插件和扩展，可以满足不同的 API 管理需求。

### APISIX

APISIX 是基于 OpenResty 和 etcd (使用 go 语言开发的分布式 key-value 存储系统，使用 Raft 协议做分布式共识) 的网关系统。与传统的 API 网关相比，APISIX 具有动态路由和插件热加载，特别适合微服务下的 API 管理。

## 链路追踪

通过链路追踪服务可以可视化追踪请求从一个微服务到另一个微服务的调用情况。常用的工具有
|工具|特点|数据存储|适用场景|
|-|-|-|-|
|Zipkin|Twitter 开源，轻量级|内存、MySQL、Elasticsearch 等|需要快速搭建、功能直接的分布式追踪|
|Jaeger|Uber 开源，云原生项目|Cassandra、Elasticsearch|云原生环境，需要强大监控和事务分析能力的复杂微服务架构|
|SkyWalking|专为微服务混合云原生设计|Elasticsearch、MySQL 等|以 Java 技术栈为主，希望获得全方位应用性能监控场景|
|Spring Cloud Sleuth|Spring Cloud 生态的客户端工具，无缝整合 Zipkin / Jaeger|需要依赖后端系统（如 Zipkin）|Spring Cloud 技术栈，简化代码中追踪信息的追踪和上报|

## Elasticsearch

Elasticsearch 用于在海量的数据中快速找到需要的内容，Elasticsearch 结合 kibana、Logstash、Beats，形成 elastic stack (ELK)，广泛应用于日志分析，实时监控领域。

{% note info %}
ES 的底层基于倒排索引实现。

我们使用**文档**表示关系型数据库的每一条数据，使用**词条** (term) 表示文档按照语义分成的词语（类似 Python 中 jieba 分词后的词语集合）。在关系型数据库中，文档中存储的是关键词列表，而在倒排索引中，我们用关键词存储文档列表。

例如，假设数据库中的数据为

|武将 id|武将名|武将描述|
|-|-|-|
|001|"董卓"|"辅助型英雄，为自己的武将增伤并对敌人的武将减防"|
|002|"吕布"|"输出型英雄，主要打单体伤害"|

现在需要建立武将描述的倒排索引。因此此处的文本首先会被分析器处理

001: ["辅助", "英雄", "自己", "武将", "增伤", "敌人", "减防"]
002: ["输出", "英雄", "主要", "单体", "伤害"]

于是开始构建倒排索引

| 词条 | 文档频率 (df) | 倒排表（文档ID: [位置序号]） |
| - | -: | - |
| "辅助" | 1 | 001: [1] |
| "英雄" | 2 | 001: [2], 002: [2] |
| "自己" | 1 | 001: [3] |
| "武将" | 1 | 001: [4] |
| "增伤" | 1 | 001: [5] |
| "敌人" | 1 | 001: [6] |
| "减防" | 1 | 001: [7] |
| "输出" | 1 | 002: [1] |
| "主要" | 1 | 002: [3] |
| "单体" | 1 | 002: [4] |
| "伤害" | 1 | 002: [5] |

查询 "辅助的英雄"，分词为 ["辅助", "英雄"]，于是分条查找。"辅助" 的结果为 001，"英雄" 的结果为 001 和 002。最后按照搜索的筛选取其交集或并集即可。
{% endnote %}

ES 中正常的文档数据会被序列化成 json 格式后存储在 ES 中。而**索引**是相同类型的文档的集合，而在表中一般是一个表。在数据库中称为约束的，在 ES 中称为**映射**。数据库中的列在 ES 中称为**字段** (Field)。ES 使用 **DSL** 这种 json 风格的请求语句来操作，实现 CRUD。ES 的调用通过发 HTTP 请求实现。

### DSL 查询语法

ES DSL 查询通常由以下几部分组成
- 查询类型 如 `match` `term` `range` 等
- 查询条件 如关键词、数值范围等
- 聚合 对查询结果进行聚合分析，如总数、平均值、分组统计等
- 排序 对指定结果进行排序
- 分页 控制返回结果的数量和起始位置

以下是一些实例：

查询所有作者为 `F.Scott Fitzgerald` 的书籍
```json
{
  "query": {
    "term": {
      "author.keyword": "F. Scott Fitzgerald"
    }
  }
}
```

查询标题中包含 `gatsby` 的书籍
```json
{
  "query": {
    "match": {
      "title": "gatsby"
    }
  }
}
```

查询 1920 至 1930 间出版的书籍
```json
{
  "query": {
    "range": {
      "year": {
        "gte": 1920,
        "lte": 1930
      }
    }
  }
}
```

查询作者为 `F.Scott Fitzgerald` 且出版年份在 1920 到 1930 之间的书籍
```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "author": "F. Scott Fitzgerald" } },
        { "range": { "year": { "gte": 1920, "lte": 1930 } } }
      ]
    }
  }
}
```

计算所有书籍的销售总额
```json
{
  "aggs": {
    "total_sales": {
      "sum": {
        "field": "sales"
      }
    }
  }
}
```

按年份统计书籍数量
```json
{
  "aggs": {
    "by_year": {
      "date_histogram": {
        "field": "publication_date",
        "calendar_interval": "year"
      }
    }
  }
}
```

按出版年份升序排列书籍
```json
{
  "query": {
    "match_all": {}
  },
  "sort": [
    { "year": { "order": "asc" } }
  ]
}
```