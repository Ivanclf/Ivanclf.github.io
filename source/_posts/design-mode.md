---
title: 设计模式
date: 2025-11-08 00:04:07
tags: [java, spring, spring-boot, 设计模式]
categories: web
---

参考文献
- [https://javabetter.cn/sidebar/sanfene/shejimoshi.html](https://javabetter.cn/sidebar/sanfene/shejimoshi.html)
- [https://javaguide.cn/java/basis/java-basic-questions-03.html#%E2%AD%90%EF%B8%8Fspi](https://javaguide.cn/java/basis/java-basic-questions-03.html#%E2%AD%90%EF%B8%8Fspi)
- [https://javaguide.cn/java/basis/spi.html](https://javaguide.cn/java/basis/spi.html)

## 责任链模式

这是一种行为设计模式，允许你将请求沿着处理器链进行传递。收到请求后，每个处理器均可以对请求进行处理，或将其传递给链上的下一个处理者。

### 工作流程

1. 客户端 client 发送一个请求到处理链的第一个节点，请求包含要处理的数据和上下文信息
2. 处理者 handler 接收到请求后，进行判断
    - 如果自己能处理，就处理请求（并决定是否能传递）
    - 如果自己不能处理，就直接传递给下一个处理者
3. 过程重复，直到链上某个处理器能处理该请求或链上没有更多的处理者

### 优缺点

**优点**
- 降低耦合度，将请求的发送者和接收者解耦
- 增加灵活性，可以将处理者动态添加、删除或重排，在不影响现有代码的情况下扩展功能
- 责任分离，避免了庞大的判断语句

**缺点**
- 性能问题，请求可能经过多个处理者才能被处理
- 调试困难，请求在链中传递，调试比较麻烦
- 请求可能不会被处理

### 应用

web 过滤器链（如网关，安全相关等）、审批流程、游戏开发、权限验证等

## 工厂模式

这是一种创建型设计模式，提供了一种创建对象的最佳方式。

### 工作流程

1. 定义产品接口，创建一个抽象的产品接口，定义产品应该具备的基本方法和属性
2. 实现具体的产品，根据接口实现多个具体产品类
3. 建立一个工厂类，负责根据输入条件（即参数）创建具体产品
4. 客户端不直接使用 new 关键字创建对象，卫视调用工厂方法，传入响应参数，工厂返回适当的产品实例给客户端使用

### 优缺点

**优点**
- 封装了创建逻辑，将复杂的对象创建隐藏在工厂内部
- 降低了耦合度，将客户端代码和具体产品类解耦
- 易于扩展，添加新产品时只需新增具体产品类和修改工厂，实现开闭原则
- 统一管理，可以在工厂中统一管理对象的创建过程，实现对象的复用、缓存等优化

### 应用场景

- 数据库的链接，如不同数据库间的链接和动态切换，连接池的管理等
- 日志系统、支付系统、游戏对象创建等的实现
- 在 spring boot 中，常见于 Bean 工厂的实现，还有 RestTemplate 工厂、数据源工厂、mq 工厂等工厂实现

### 其它

- 可以通过工厂模式来创建线程，并在工厂方法中设置其前缀名

## 单例模式

这是一种创建型设计模式，确保一个类只有一个实例，并提供一个全局访问点来访问这个唯一实例

### 处理流程

1. 私有化构造函数
2. 提供静态实例变量，在类内部定义一个静态的私有变量来保存唯一的实例
3. 提供公共的静态访问方法，该方法负责返回类的唯一实例，在方法内部空值实例的创建时间和条件
4. 常见的单例模式有三种：饿汉式（类加载时就创建实例）、懒汉式（在实际使用时才创建实例，需考虑线程安全问题）、双重检查锁（在懒汉式的基础上增加了双重检查锁）
5. 静态内部类的加载则利用 Java 内部的静态内部类和类加载机制来实现线程安全的延迟初始化
6. 枚举类直接初始化就行，不用担心线程安全问题

{% note success %}
双重检查锁用 [`synchronized (Singleton.class)`](https://ivanclf.github.io/2025/09/30/concurrent-2/#synchronized%E5%85%B3%E9%94%AE%E5%AD%97%E4%B8%8EReentrantLock)替代了同步方法，这样锁定的不是方法而是整个类的 Class 对象，并且在 `instance` 实例前加上 [`volatile` 关键字](https://ivanclf.github.io/2025/09/30/concurrent-2/#volatile%E5%85%B3%E9%94%AE%E5%AD%97)防止[指令重排](https://ivanclf.github.io/2025/09/30/concurrent-2/#as-if-serial%E8%AF%AD%E4%B9%89)。
{% endnote %}

### 优缺点

**优点**
- 严格控制实例数量，避免因多个实例导致的资源冲突或状态不一致
- 通过提供统一的访问入口简化管理和控制
- 减少频繁创建和销毁对象的开销
- 单例对象的状态在整个系统中都是共享的，适合用作配置信息、缓存数据等全局数据的存储

**缺点**
- 单例类既要负责业务逻辑，又要控制实例数量，不符合单一职责原则
- 单例的全局状态会影响单元测试的独立性
- 可能会导致线程安全问题

### 应用场景

- 配置管理
- 日志系统、数据库连接池、缓存系统等
- spring boot 中默认的 Bean 都是单例模式

## 策略模式

这是一种行为设计模式，将每个算法都封装起来，并使它们可以相互替换。

### 处理流程

1. 创建一个策略接口，生命所有具体策略必须实现的方法
2. 创建多个具体策略类实现其接口
3. 创建上下文类，定义一个接口让策略访问数据，将客户端的请求委托给当前策略对象
4. 客户端根据具体需求选择合适的策略

优缺点和工厂模式其实差不多，此处略过

### 应用场景

- 支付系统的切换、导航系统的算法切换、排序算法、压缩工具等
- spring boot 中用于消息通知系统或文件解析器

### 其它

- 与工厂模式的核心不同在于，策略模式关注对象的使用，工厂模式关注对象的创建
- 实际开发时也可以和工厂模式混用，主要用于动态选择和执行不同策略的场景

## 模板模式

这是一种行为型设计模式，在父类中定义一个算法的框架，而将一些步骤的实现延迟到子类中

### 处理流程

1. 定义抽象模板类，将可变步骤声明为抽象方法
2. 具体子类继承抽象模板类

### 优缺点

**优点**
- 代码复用，提高扩展性
- 实现控制反转，由父类控制算法流程

**缺点**
- 继承固有的局限性，即限制其灵活性
- 不适合需要频繁改变算法的场景

### 应用场景

- 数据处理的流程与相似的业务操作
- spring 中的 JdbcTemplate、StringRedisTemplate、RestTemplate 等等

## SOA

SOA (**Service-Oriented Architecture** 面向服务架构) 是一种软件架构设计原则。它强调将应用程序拆分成相互独立的服务，通过标准化的接口进行通信。SOA 关注于服务的重用性和组合性，但并没有具体规定服务的大小。微服务则是 SOA 思想的一种具体实践方式。

## SPI

我们一般用到的都是 API（Application Programming Interface），即他人已经实现好的功能。而 SPI（Service Provider Interface）是服务提供者接口，主要用于框架扩展。SPI 的核心思想是面向接口编程 + 策略模式 + 配置文件，框架定义接口，由第三方服务提供者来实现这些接口，从而实现框架的扩展性。

一般 SPI 需要实现以下要素

**服务接口**：由框架或调用方去定义。

```java
public interface MessageService {
    String getMessage();
}
```

**服务实现类**：由第三方或插件方提供，必须提供无参构造

```java
public class HelloService implements MessageService {
    public String getMessage() { return "Hello SPI"; }
}

public class HiService implements MessageService {
    public String getMessage() { return "Hi SPI"; }
}
```

**配置文件**：在 `META-INF/services/` 目录下创建以服务接口全限定名命名的文件，每行写一个实现类全限定名

```text
com.example.spi.impl.HelloService
com.example.spi.impl.HiService
```

**`ServiceLoader`**：JDK 提供的加载器，运行时解析配置并反射实例化

```java
ServiceLoader<MessageService> loader = ServiceLoader.load(MessageService.class);
for (MessageService service : loader) {   // 懒加载，迭代到才实例化
    System.out.println(service.getMessage());
}
```

其实现过程如下
1. 发现阶段，ServiceLoader 根据服务接口的全限定名，在类路径的 `META-INF/services/` 目录下查找对应的文件，并读取其中的实现类全限定名列表。
2. 加载阶段，使用指定的类加载器或按双亲委派模型去加载每个实现类（通过 `Class.forName(className, false, loader)`），如果类加载失败（如类未找到或不是接口的实现，会抛出异常）。
3. 实例化和缓存阶段，通过反射调用无参构造函数实例化每个实现类，并将实例缓存到 `LinkedHashMap` 中，确保每个实力类只实例化一次。
4. 迭代使用阶段，通过 `ServiceLoader.iterator()` 获取迭代器，按需懒加载下一个实现类实例，并基于缓存机制避免重复返回同一实现类。

常见的 SPI 有 JDBC 的 `java.sql.Driver`、 SLF4J 的 Binding 等。

## 装饰器模式

通过组合替代继承来扩展原始类的功能。适合处理继承关系比较复杂的场景，如 IO 流等。