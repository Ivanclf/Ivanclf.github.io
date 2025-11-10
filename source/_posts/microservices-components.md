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

## 配置中心

### Nacos

## 远程调用

## 服务容灾

## 服务网关

## 链路追踪

## 服务监控

## 分布式事务
