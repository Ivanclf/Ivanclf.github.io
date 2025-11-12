---
title: 微服务系统组件 - 1
date: 2025-11-10 15:46:42
tags: [java, spring, 分布式, spring-cloud]
categories: web
---

参考文献

- [https://javabetter.cn/sidebar/sanfene/weifuwu.html](https://javabetter.cn/sidebar/sanfene/weifuwu.html)
- [https://javaguide.cn/distributed-system/distributed-process-coordination/zookeeper/zookeeper-intro.html](https://javaguide.cn/distributed-system/distributed-process-coordination/zookeeper/zookeeper-intro.html)

- [https://javaguide.cn/distributed-system/distributed-lock-implementations.html#redis-%E5%A6%82%E4%BD%95%E8%A7%A3%E5%86%B3%E9%9B%86%E7%BE%A4%E6%83%85%E5%86%B5%E4%B8%8B%E5%88%86%E5%B8%83%E5%BC%8F%E9%94%81%E7%9A%84%E5%8F%AF%E9%9D%A0%E6%80%A7](https://javaguide.cn/distributed-system/distributed-lock-implementations.html#redis-%E5%A6%82%E4%BD%95%E8%A7%A3%E5%86%B3%E9%9B%86%E7%BE%A4%E6%83%85%E5%86%B5%E4%B8%8B%E5%88%86%E5%B8%83%E5%BC%8F%E9%94%81%E7%9A%84%E5%8F%AF%E9%9D%A0%E6%80%A7)

- [https://www.bilibili.com/video/BV1LQ4y127n4](https://www.bilibili.com/video/BV1LQ4y127n4)

目前流行的微服务解决方案有三种：`Dubbo`、`Spring Cloud Netflix`、`Spring Cloud Alibaba`。它们之间存在许多区别

|特点|Dobbo|Spring Cloud Netflix|Spring Cloud Alibaba|
|-|-|-|-|
|服务治理|提供完整的服务治理功能|提供部分服务治理功能|提供完整的服务治理功能|
|服务注册和发现|ZooKeeper / Nacos|Eureka / Consul|Nacos|
|负载均衡|自带策略|Ribbon|Ribbon / Dubbo 自带|
|服务调用|RPC|RestTemplate / Feign|Feign / RestTemplate / Dubbo|
|熔断器|Sentinel|Hystrix|Sentinel / Resilience4j|
|配置中心|Apollo|Spring Cloud Config|Nacos Config|
|API 网关|Higress / APISIX|Zuul / Gateway|Spring Cloud Gateway|
|分布式事务|Seata|不支持|Seata|
|限流和降级|Sentinel|Hystrix|Sentinel|
|分布式追踪和监控|Skywalking|Spring Cloud Sleuth + Zipkin|SkyWalking / Sentinel Dashboard|
|微服务网格|Dobbo Mesh|不支持|Service Mesh (Nacos + Dubbo Mesh)|
|社区活跃度|相对较高|目前较低|相对较高|

## 服务注册

注册中心用于管理和维护分布式系统中各个服务的地址和元数据组件。它主要用于实现 **服务发现** 和 **服务注册** 功能。
1. 服务注册：各个服务启动时向注册中心注册自己的网络地址、服务实例信息和其他相关元数据。这样，其他服务就可以通过注册中心获取当前可用的服务列表
2. 服务发现：客户端通过向注册中心查询特定服务的注册信息，获得可用的服务示例列表。这样客户端就可以根据需要选择合适的服务进行调用
3. 负载均衡：注册中心可以对统一服务的多个实例进行负载均衡，将请求分发到不同的实例上，提高整体的系统性能和可用性
4. 故障恢复：注册中心能监测和检测服务的状态，当服务实例发生故障或下线时，可以及时更新注册信息，从而保证服务正常工作
5. 服务治理：通过注册中心可以进行服务的配置管理、动态扩缩容、服务路由、灰度发布这些操作，从而实现对服务的动态管理和控制

目前常用的注册中心有三种

|特点|Eureka|ZooKeeper|Nacos|
|-|-|-|-|
|CAP|AP|CP|AP 或 CP|
|功能|服务注册和发现|分布式协调、配置管理、分布式锁|服务注册和发现、配置管理、服务管理|
|访问协议|HTTP|TCP|HTTP / DNS|
|自我保护|支持|不支持|支持|
|数据存储|内嵌数据库，多个实例形成集群|ACID 特性的分布式文件系统 ZAB 协议|内嵌数据库，其他数据库等|
|健康检查|Client Beat|Keep Alive|TCP / HTTP / MySQL / Client Beat|

{% note info %}
这些注册中心在构建集群时，注意一般会构建奇数个集群。因为保证不过半的情况下 $2n$ 和 $2n-1$ 是一样的。

这些注册中心的选举机制同样能防止[脑裂](https://ivanclf.github.io/2025/09/25/redis-3/#%E8%84%91%E8%A3%82)
{% endnote %}

### Eureka

一个典型的 Eureka 组件包含两个组件：Eureka Server 和 Eureka Client。

一个微服务，作为 Eureka Client，启动后，会向 Eureka Server 发送一个 REST 请求，Server 收到请求后，会将这个信息存储在一个双层 Map 注册表中，第一层 key 是服务名，第二层 key 是具体的实例 id。

注册成功后，Eureka Client 会每隔30秒向 Eureka Server 发送一次心跳，证明自己还“活着”，这个过程称为续约。Server 收到心跳后，会更新其最后续约时间。如果90秒后还没有收到某个实例的心跳，Server 会认为该实例已宕机，会将其从服务注册表删除。

Eureka Client 启动时，会从 Eureka Server 拉取一份完整的服务注册表到本地缓存。然后每隔30秒重新拉取一次。而服务消费者（即 Eureka Client）在需要调用某个服务时，可以直接使用服务名。它可以从自己本地缓存的服务器列表中，通过负载均衡算法选取一个实例地址，发起实际的 RESTful 调用。

Eureka Client 关闭时，它会向 Eureka Server 发送一个取消注册的 REST 请求，Server 收到后会立即将该实例从注册表中删除。

当 Eureka Server 在短时间内（15 分钟）丢失过多客户端（85% 以上的客户端都没有心跳），它就会进入自我保护模式。此时 Server 不会删除任何实例，及时这些实例实际上已经宕机。

为了保证高可用性，可以同时部署多个 Eureka Server 实例。同时，在一个服务实例向 Eureka Server 注册时，每个 Eureka Server 实例都会复制其他实例的注册信息。

### ZooKeeper

ZooKeeper 的内存数据模型是一个类似于文件系统的树形结构，其节点称为 ZNode。每个 ZNode 都可以存储少量数据，通常以 kb 为单位，适用于存储配置，状态等元信息。每个 ZNode 都有一个唯一路径，以此作为唯一标识。

节点分为三种：
- 持久节点：一旦创建，除非主动删除，否则一直存在
- 临时节点：和客户端会话绑定，当创建接待你的客户端会话无效（断开链接）时，节点被自动删除
- 顺序节点：除了具有持久或临时的的特性之外，创建时 ZooKeeper 会在节点名后追加一个单调递增的序列号

![ZooKeeper 的文件结构](znode-structure.png)

ZooKeeper 通常以集群模式部署，其高可用和数据一致性的核心是 ZAB 协议。在该协议中，节点有三种角色：Leader、Follower、Observer（不参与投票，只为了扩展系统的读性能）。该协议主要干两件事
1. 消息广播
    进行数据同步。客户端发起一个写请求时，leader 将这个写操作转换为一个事务提案，闭关分配给每个 Follower。只有超半数的 Follower 持久化该提案成功后，Leader 才会提交这个事务，并向所有 Follower 发送 commit 数据。[其实就是 2PC](https://ivanclf.github.io/2025/11/08/distributed/#2PC-%E4%BA%8C%E9%98%B6%E6%AE%B5%E6%8F%90%E4%BA%A4)
2. 崩溃恢复
    Leader 节点宕机时，ZAB 协议会进入恢复模式，并选举产生新 Leader 服务器。选举的算法是 [Paxos 算法](https://ivanclf.github.io/2025/11/08/distributed/#Basic-Paxos-%E7%AE%97%E6%B3%95)。选举完成后 ZAB 协议会退出恢复模式。

虽然 ZooKeeper 本身不是专门的服务发现工具，但可以利用其特性轻松构建出来
- 服务注册
    1. 服务提供者启动后，和 ZooKeeper 集群建立一个会话
    2. 然后在某个持久节点下，创建一个临时的子 ZNode，并在该 ZNode 中存储自己的地址信息
- 服务发现和健康检查
    1. 服务消费者链接到 ZooKeeper
    2. 它获取某个目录下的所有子节点列表，就得到了所有可用的服务实例地址
    3. 消费者在这个父节点上设置一个 Watch 监听。当任意一个服务实例宕机时，其对应的临时节点会被 ZooKeeper 自动删除。这个删除事件会触发 Watch，从而通知所有的监听者，从而重新拉取新的服务列表。

ZooKeeper 也能实现一个[分布式锁](https://ivanclf.github.io/2025/09/24/redis-2/#%E5%88%86%E5%B8%83%E5%BC%8F%E9%94%81)

获取锁
1. 创建一个持久节点 `/locks`，所有的锁都是通过在这上面放临时节点实现的
2. 假设客户端创建了 `/locks/lock1` 节点，创建成功后，会判断 `lock1` 是否是 `/locks` 的最小节点
3. 如果是，则获取锁成功，否则，获取锁失败
4. 如果获取锁失败，则说明有其他的客户端已经成功获取锁。客户端会在前一个节点如 `/locks/lock0` 上注册一个事件监听器。这个监听器会在其他节点释放锁后通知客户端，从而避免了无效自旋

释放锁
1. 成功获取锁的客户端在执行完业务端后将对应的子节点删除
2. 即使该客户端出现故障，对应的子节点由于是临时顺序节点，也会被自动删除
3. 子节点删除就意味着锁释放，也就被 Watch 监听到

其中的可重入锁有另一种实现，即直接在客户端判断当前线程有没有获取锁，有就将锁次数加1即可。

实际项目中通常使用 Curator 实现 ZooKeeper 分布式锁。

## 配置中心 Nacos

Spring Cloud 可以选择的配置中心有 Spring Could Config、ZooKeeper、Consul、Apollo、Nacos 等。其中常用的是 Nacos

Nacos 也提供服务注册功能，其服务注册的原理和 Eureka 差不多。当一个服务提供者启动时，它会向 Nacos Server 发送一个 REST 请求，包含自己的元数据。Nacos Server 将这些信息存储在一个内置、分布式的数据存储中（早期版本用 Derby，集群版本使用 Raft）。

服务实例每5秒向 Nacos Server 发送一个“心跳”来证明自己还活着。如果 Nacos Server 15秒后仍没有收到某个实例的心跳，就会认为该实例已挂机，并将其从服务列表中删除。除了这个方式，Nacos Sercer 还可以主动向服务实例发送探测型请求。如果连续失败，则将其标记为不健康或直接删除。

当服务消费者需要调用远程服务时，它有两种方式从 Nacos Server 获取可用的服务实例列表
- 拉取模式，消费者每30秒向 Nacos Server 拉取它关心的服务列表并缓存在本地
- 推送模式，消费者订阅了某个服务。当该服务列表发生变化时，Nacos Server 会主动推送一个变更事件给消费者，消费者理科更新本地缓存

可以结合 Ribbon 或 Spring Could LoadBalancer 对拉取的列表实现某种策略实现负载均衡。

当 Nacos 作为配置中心时，可以集中化、动态地管理所有环境的配置，实现配置和代码分离。其配置文件分组命名规范如下
- Data id 一份配置文件的唯一标识，通常格式是 `{spring-application.name}-{profile}.(file-extension)`，例如 `user-service-dev.yaml`
- Group 对配置的分组，用于区分不同的项目或模块
- Namespace 用于进行多配置隔离，常用于区分不同的环境（如开发、配置、生产）

应用启动时，会根据配置的 `spring.application.name` `spring.profiles.active` 等信息，确定一个唯一的 Data id，然后根据这个 id 向 Nacos Server 发送请求，拉取对应的 Data id 和 Group 的配置内容，然后返回其配置信息，和本地配置（如 `application.yml` 进行合并，完成 spring 容器的启动。

应用成功从 Nacos 获取配置后，会在本地缓存一份配置，并同时向 Nacos Server 注册一个监听器。放开发者在 Nacos 修改配置时，Nacos Server 会找到所有监听了这个 Data id 的应用实例，并进行推送（通过长连接或 gRPC 流）。实例收到通知后会重新拉取内容，并更新本地缓存。此时，若使用 `@Value` 注入，则需要在类上面调用 `@RefreshScope` 动态刷新。若使用 `@ConfigurationProperties(prefix = "")`，则不需要额外处理。

## 远程调用

常用的远程调用方式有 HTTP 和 [RPC](https://ivanclf.github.io/2025/09/26/java/#Socket%E5%A5%97%E6%8E%A5%E5%AD%97)

### Feign

Feign 是一个声明式的 Web Service 客户端，它通过注解和接口定义的方式来调用 HTTP API，就能像调用本地方法一样调用远程服务。Feign 是在 RestTemplate 和 Ribbon 的基础上进一步封装，使用 RestTemplate 实现 HTTP 调用，使用 Ribbon 实现负载均衡。

首先在启动类打注解 `@EnableFeignClient`，然后定义声明式 API

```java
@FeignClient(name = "example", url = "https://api.example.com")
 public interface ExampleService {
     @GetMapping("/endpoint")
     String getEndpointData();
 }
```

这样就可以正常使用了。

{% note info %}
一个 `@FeignClient` 包含以下参数

```java
@FeignClient(
    name = "payment-service",           // 服务名称（用于服务发现）
    url = "http://api.payment.com",     // 直接指定URL（可选）
    path = "/api/v1",                   // 所有请求的统一前缀
    configuration = FeignConfig.class,  // 自定义配置
    fallback = PaymentServiceFallback.class  // 熔断降级类
)
```

{% endnote %}

{% note info %}
可以发现这里 `@FeignClient` 的接口样式和 `@RestController` 的方法样式一摸一样，因此可以用以下两种方式进行抽象
1. 让 Controller 和 FeignClient 继承同一接口。
    不推荐，因为会导致高耦合，并且 Spring MVC 的部分方法参数映射（如 `@PathVariable`，接口写过了子类还得写，继承不了）不能继承下来。
2. 将 FeignClient 抽取作为独立模块，并且将接口有关的 POJO、默认的 Feign 配置都放到这个模块中，提供给所有消费者使用。

{% endnote %}

由于 Feign 中内嵌的 Ribbon 默认懒加载。当第一次调用发生时，Feign 会触发 Ribbon 的加载过程，包括从服务注册中心获取服务列表、建立连接池等操作，这些操作会导致第一次调用 Feign 的耗时很长。为了解决这个问题，得让 Ribbon 启用饿加载

```yaml
ribbon:
    eager-load:
        enable: true
        client: # 指定饿加载时的服务名称
            - exampleService
```

Feign 作为 HTTP 客户端，也可以实现拦截功能，在某个 Bean 中实现 `@RequestInterceptor` 接口并实现 `apply` 方法，可以进行拦截并对该 HTTP 请求进行加加请求头、认证传递等操作。

Feign 作为 HTTP 客户端，其底层的客户端实现有三种方式
- URLConnection 默认实现，不支持连接池
- Apache HttpClient 支持连接池
- OKHttp 支持连接池

而每次 HTTP 请求都会新建一次会话线程，开销较大，因此建立连接池是比较比较经济的选择。添加 feign-httpclient 依赖，然后配置好连接池

```yaml
feign:
    httpclient:
        enable: true
        max-connection: 200 # 最大连接数
        max-connection-pre-route: 50 # 每个路径的最大连接数
```

## 负载均衡

目前常见的负载均衡组件是 Ribbon。Ribbon 运行在消费者端，通过算法从服务列表中选择一个合适的服务实例进行调用。

目前常用的负载均衡算法有以下几种
- 轮询算法，循环往复找服务器
- 加权轮询算法，权重值越高，被选中的概率越大
- 随机算法，随机分配
- 加权随机算法，权重值越高，被选中的概率越大
- 最少链接算法，选择当前链接最少的服务器进行分配
- 哈希算法，计算哈希值

## 服务容灾

容灾主要解决服务雪崩的问题，**服务雪崩**指在微服务中，若有一个或多个服务出现故障，此时依赖的服务还在不断发起请求或重试，那么这些请求的压力会不断在下游堆积，导致下游服务的负载急剧增加。不断累积之下，可能会导致故障的进一步加剧，从而导致级联式的失败，从而导致整个系统崩溃。

对策一般有三种：冗余部署、限流和熔断、缓存和降级

目前常用的容灾方案有以下三种

|方案|核心特点|实现原理|适用场景|
|-|-|-|-|
|Sentinel|功能丰富，支持多种熔断策略（慢调用比例、异常比例、异常数），集成度高|基于熔断器状态机，通过自定义资源规则进行熔断降级|Spring Cloud Alibaba 场景，对熔断降级有细粒度控制的场景|
|Resilience4j|轻量级，对函数式编程友好，提供熔断器、限流、重试等多种容错模块|提供 `@CircuitBreaker` 注解，通过配置失败率，满调用阈值等参数实现熔断|需要轻量级、可组合容错模块的现代 Java 应用|
|Hystrix|早期流行的熔断方案，提供线程池和信号量隔离机制|通过 `@HystrixCommand` 注解配置熔断降级方法，当调用失败时执行降级逻辑|旧版 Spring Cloud Netflix 项目，现在已停止更新|

### 限流控制

在 Sentinel 中，资源可以是 URL、方法等，用于标识需要进行限流的请求。可以在 Sentinel 的配置文件中定义资源的限流规则。规则可以包括资源名称、限流阈值、限流模式（令牌桶或漏桶）等。

```java
private static void initFlowQpsRule() {
     List<FlowRule> rules = new ArrayList<>();
     FlowRule rule1 = new FlowRule();
     rule1.setResource(resource);
     // Set max qps to 20
     rule1.setCount(20);
     rule1.setGrade(RuleConstant.FLOW_GRADE_QPS);
     rule1.setLimitApp("default");
     rules.add(rule1);
     FlowRuleManager.loadRules(rules);
 }
```

{% note info %}
Sentinel 的限流和 GateWay 的限流还是有一些区别的。GateWay 采用了基于 redis 实现的令牌桶算法，而 Sentinel [可以使用多种算法](https://ivanclf.github.io/2025/11/08/distributed/#%E9%99%90%E6%B5%81)，比如内部默认使用滑动时间窗口算法，排队等待则基于漏桶算法，热点参数限流基于令牌桶算法，等等。
{% endnote %}

### 服务熔断

当某个服务出现故障或者异常时，服务熔断可以快速隔离该服务。确保系统稳定可用。它通过监控服务的调用情况，当错误率或响应时间超过阈值时，触发熔断机制，后续请求将返回默认值或错误信息，避免发生雪崩现象。

Hystrix 中的服务熔断和上面所述的原理差不多。当错误率或响应时间超过预设的阈值时，熔断器将会打开。后续的请求不再发送到实际的服务提供方。

### 服务降级

当系统出现异常情况时，服务降级会主动屏蔽一些非核心或可选的功能，而只提供最基本的功能，以确保系统的稳定运行。

Hystrix 中的服务降级也和上面所述的原理差不多。服务器熔断打开时，Hystrix 可以提供一个备用的降级方法或返回默认值，以保证系统继续正常运行。开发者可以定义降级逻辑，以提供有限但可用的功能。

### 请求缓存

Hystrix 中可以缓存对同一请求的响应结果，以避免重复的网络请求带来的开销

### 请求合并

Hystrix 可以将多个并发的请求合并为一个批量请求，减少网络开销和资源占用。对于一些高并发的场景，可以有效减少请求次数。

### 实时监控和度量

Hystrix 提供对服务的执行情况进行监控和统计功能，以监控错误率、响应时间、并发量等指标。

而 Sentinel 可以监控每个资源的流量情况，包括请求的 QPS、线程数、响应时间等，还提供了类似 Nacos 一样的可视化网页界面。

### 线程隔离

Hystrix 将每个依赖的服务都放在独立的线程池中执行，避免因某个服务的故障导致整个系统的线程资源耗尽。这样的隔离性虽然更强，但每一个被隔离的业务都要创建一个独立的线程池，县城过多会带来额外的 CPU 开销，性能一般。

Sentinel 使用信号量进行隔离。维护一个计数器，当有线程进入时数量-1，到0后即停止进入。该方法不需要创建线程池，性能较好，但是隔离性一般。