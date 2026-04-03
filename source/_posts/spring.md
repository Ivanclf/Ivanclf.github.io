---
title: spring 特性
date: 2025-10-29 22:57:43
tags: [java, spring]
category: web
---

参考文献
- [https://javabetter.cn/sidebar/sanfene/spring.html](https://javabetter.cn/sidebar/sanfene/spring.html)
- [https://javaguide.cn/system-design/framework/spring/spring-knowledge-and-questions-summary.html](https://javaguide.cn/system-design/framework/spring/spring-knowledge-and-questions-summary.html)

Spring 框架一般指 Spring Framework，它是多模块的集合，讲究开箱即用。其最核心的两个特性为
- [IoC 控制反转](#ioc-机制)
    以前用一个对象要自己 new 出来，现在只需要告诉 spring 需要什么对象就行
- [AOP 面向切面编程](#aop)
    在某些通用步骤（如鉴权、事务管理、日志记录）提供统一的代码

## 包含模块

![spring 5.x中的模块](20200831175708.png)

- Core Container 核心模块，提供IoC依赖注入功能的支持
    - spring-core 
        基本的核心工具类，包括IoC和DI功能，关键组件是 `BeanFactory` ，它是工厂模式的实现，负责创建和管理 Bean 对象
    - spring-beans 
        提供对 `BeanFactory` 的实现，负责创建、配置和管理 Bean 及其之间的依赖关系
    - spring-context 
        在前两者的基础上构建，以一种更面向框架的方式访问对象，类似于 JNDI 注册表。`ApplicationContext` 接口是 Context 模块的焦点。它增加了企业级功能，如国际化、事件传播、资源加载等
    - spring-expression 
        提供对表达式语言（Spring Expression Language） SpEL 的支持。用于在运行时查询和操作对象图。它支持在 Bean 中设置属性值和执行方法
- AOP 
    - spring-aop
        提供了面向切面的编程实现，允许将横切关注点与业务逻辑分离。它基于代理模式实现
    - spring-aspects
        提供了与 AspectJ （一个更成熟的AOP框架）的继承支持
    - spring-instrumentation
        提供类植入和类加载器实现，主要用于应用服务器
- Data Access/Integration 提供与数据库交互和数据集成的支持
    - spring-JDBC
        提供一个 JDBC 抽象层，极大简化了 JDBC 编码和错误处理，不需要再编写繁琐的 `try-catch` 语句来处理链接了
    - spring-ORM
        提供与主流对象关系映射框架的继承支持，如 Hibernate、 JPA、 Mybatis 等。spring还可以统一这些ORM框架的配置和事务管理
    - spring-OXM
        提供对 Object/XML 映射实现的抽象层支持，如 JAXB、 Castor、 XStream 等
    - spring-Transactions
        支持编程式和声明式事务管理，是 spring 数据访问层的核心功能
- Web
    - spring-web
        面向 Web 的基本的集成功能。如多部份文件上传、初始化IoC容器等
    - spring-web-MVC
        包含了 spring 的 MVC 实现，用于构建 Web 应用程序
    - spring-websocket
        提供了 WebSocket 通信的全双工协议支持
    - spring-webflux
        spring 5 引入的响应式 web 框架，用于构建非阻塞、异步、事件驱动的服务。与 spring MVC 不同，它不需要 Servlet API，是完全异步的
- test
    - spring-test
        支持使用 JUnit 或 TestNG 对 spring 组件进行单元测试和集成测试。还提供了用于测试 web 应用的 `Mock` 对象

spring 旨在简化 Java EE 开发，而 spring boot 旨在简化 spring 开发，大大减少了配置文件。

## IoC 机制

IoC (`Inversion of Control`) 机制带来的好处是显而易见的，它使得对象之间的耦合度或者依赖程度降低，资源也变得更加容易管理。

{% note success %}
而 DI，也就是依赖注入，是实现 IoC 这种思想的具体技术手段，在 spring 里使用 `@Autowired` 注解就是在用 DI 的字段注入方式。DI 可以实现字段注入、构造方法注入、Setter 方法注入三种方式。除了 DI，IoC 还能通过 Service Locator （实现 `ApplicationContextAware` 接口）模式获取 spring 容器中的 Bean
{% endnote %}

### Bean

#### 定义

我们使用 Bean 代指那些被IoC容器所管理的对象。一般我们需要在专门的XML文件、注解或者Java配置类来配置元数据以定义 Bean 。

将一个类声明为 Bean 的注解有
- `@Component` 通用注解，如果一个 Bean 不知道在哪个层，就可以用这个注解
- `@Repository` 持久层，即 Dao 层，用于数据库相关操作
- `@Service` 服务层，主要涉及一些复杂的逻辑，需要用到 Dao 层
- `@Controller` 对应 spring MVC 控制层，主要用于接受用户请求，并调用 service` 层返回数据给前端
- `@RestController` 对应 RESTful API 下的控制层，是 `@Controller` 和 `@ResponseBody` 的结合。被它标注的类，其所有方法返回的数据都会直接 HTTP 响应体
- `@Configuration` 配置类，其内部可以包含使用 `@Bean` 的方法，它本身也会被 spring 容器管理

`@Bean` 是唯一的方法级别注解。被注释的方法会返回一个对象，该对象会被 spring 容器注册为一个 Bean。

这些被注释的对象（或方法）会被 spring 容器管理。在需要注入时，使用如下方法
- `@Autowired` spring 内置的注解，默认注入逻辑为先按类型匹配，若存在多个同类型 Bean，再尝试按名称筛选
    当注入接口但接口有多个实现类时，spring 会抛出 `NoUniqueBeanDefinitionException` 异常，因此可以在该注解后面追加 `@Qualifier()` 注解，指明是哪个实现类，或者在默认使用的 Bean 前加 `@Primary` 注解
- `@Resource` JDK 提供的注解，默认注入逻辑为先按名称匹配，若存在多个同名 Bean，则再尝试按类型匹配
    该注解可以指定 name 和 type

#### 注入

注入 Bean 的方式有以下几种
- 构造函数注入
    ```java
    private final UserRepository userRepository;
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    ```

- Setter 注入
    ```java
    @Autowired
    public void setUserRepository(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    ```
- Field 注入
    ```java
    @Autowired
    private UserRepository userRepository;
    ```

相比 setter 注入，spring 官方推荐构造注入。构造注入有以下优势
- 依赖可声明为 `final`，创建不可变的 Bean，保证线程安全和业务逻辑安全
- 保证依赖不为空
- 在不使用 spring 容器下进行单元测试也非常方便

而 Field 注入则更不推荐了，该方法虽然方便，但
- 破坏封装性
- 测试困难，需要依赖 spring 容器。而构造函数注入可以直接 mock 依赖
- 隐藏了依赖关系，外部看不出需要什么依赖
- 注入的对象可能是 null
- 可能会导致循环依赖问题
- 字段注入的依赖是可变的

{% note info %}
`@Autowired` 注入在 Bean 生命周期的属性填充阶段执行。首先，spring 会扫描 Bean 类，找出所有 `@Autowired` 注解的字段和方法。然后，spring 根据字段/参数类型在容器中查找匹配的 Bean。最后，通过**反射**设置字段值，将找到的 Bean 注入到目标字段。对于字段注入，会调用 `Field.set()` 方法，对于 setter 注入，会调用 `Method.invoke()` 方法。
{% endnote %}

#### 循环依赖

对于 Field 或 Setter 注入时可能产生的循环依赖问题，spring 通过三级缓存机制，巧妙解决了单例 Bean 场景下的循环依赖问题。

在 spring 的 `DefaultSingletonBeanRegistry` 类中，维护了三个重要的 Map，也就是我们常说的三级缓存：
1. 一级缓存 `singletonObjects` ：存放已完成实例化、注入、初始化的 Bean。我们平时从 spring 容器中获取到的就是这里的 Bean
2. 二级缓存 `earlySingletonObjects` ：存放已实例化，但未注入、初始化的 Bean。用于解决循环依赖
3. 三级缓存 `singletonFactories` ：存放一个 `ObjectFactory` （对象工厂）。这个工厂可以返回一个目标 Bean 的早期引用（通过动态代理等技术），以便后面有机会创建代理对象

以 A 依赖 B，B 依赖 A 为例，

1. 开始创建 A
    - 在 `getBean("a")` 时，spring 还没意识到 A 还没被创建，正常创建
    - 调用 A 的构造器，实例化 A 对象。此时 A 还是个半成品，属性 b 为 null
    - spring 将构建好的 A 对象包装成一个 `ObjectFactory`，并放入**三级缓存**，同时从**二级缓存**移除 A （若存在）。
2. 为 A 进行属性填充
    - spring 发现 A 依赖 B，于是执行 `getBean("b")` 获取 B
3. 开始创建 B
    - 和创建 A 的过程一样，实例化 B 对象，放入**三级缓存**
4. 为 B 进行属性填充
    - spring 发现 B 依赖 A，于是执行 `getBean("a")` 获取 A
5. **关键步骤** 获取早期引用
    - 这次的 `getBean("a")` 不会从头开始创建 A，因为在第一级、第二级没找到，但在第三级找到了 A 的 `ObjectFactory`
    - spring 通过 `ObjectFactory.getObject()` 方法，获取到 A 对象的早期引用（这个引用可能是一个代理对象，也可能就是原始对象）
    - 然后 spring 将这个早期引用放入**二级缓存**，并从**三级缓存**中移除 A 的工厂
    - 最后，将这个早期引用返回给 B。至此，B成功完成了属性注入，属性 a 指向了 A 的早期引用
6. B 完成初始化
    - B 在注入 A 的早期引用后，继续执行后续步骤。最后变成一个完全初始化的 Bean
    - spring 将初始化好的 B 对象放入第一级缓存，并清除二级和三级缓存中关于 B 的记录
7. A 完成初始化
    - B 创建完成后，步骤 2 中的 `getBean("b")` 的调用成功返回了完整实例
    - A 成功注入 B 并完成初始化

![简图](spring-20250706065436.png)

**那为什么需要三级缓存呢？**

主要是为了解决 [AOP](#aop) 的问题。关键在于三级缓存存储的是一个工厂，而不是直接的对象。这个工厂的核心作用是调用 `getEarlyBeanReference` 方法。这个方法在 Bean 存在 AOP 时至关重要。

如果缺少了三级缓存，在 B 注入 A 时，我们只能从二级缓存拿到 A 的原始对象。但如果 A 最终需要被 AOP 代理，那么 B 注入就是一个原始对象，而不是代理对象，这会导致问题（同一个 Bean 居然会产生两个实例）。有了三级缓存，B 注入 A 时会通过三级缓存中的`ObjectFactory` 来获取 A 的调用。若 A 需要被代理，那么 `getEarlyBeanReference` 方法会在这里提前生成并返回代理对象，如果不需要，则返回原始对象。这样就保证了 B 注入的 A 和最终放入一级缓存的 A 是同一个对象，保证了行为一致性。

如果缺少了二级缓存，那么在三个及以上（假设为 A、B、C）的 Bean 构成间接依赖时，每次 B 或 C 需要获取 A 时，都需要调用 A 中的 `ObjectFactory.getObject()` 方法。这意味着如果 A 需要被代理的话，代理对象可能会重复创建多次。

[可以看这里的视频](https://www.bilibili.com/video/BV1HwkvYmEXv)

以下情况的循环依赖 spring 无法被创建出来：
- 若使用构造器注入的循环依赖，构造时对象还没创建出来，无法放入三级缓存，spring 会直接抛出 `BeanCurrentlyInCreationException`
- 原型 Bean 循环依赖，由于 spring 不缓存 Prototype Bean，所以无法暴露其早期引用
- `@Async` 方法导致的循环依赖，因为 `@Async` 的大力创建时机交完，在三级缓存机制后，可能导致注入的不是最终的代理对象

#### 作用域

spring 中 Bean 的作用域可以通过注释 `@Scope()` 指定，通常有以下几种
- `singleton` 单例
    默认作用域。在整个 spring IoC 容器中，只存在一个该 Bean 的共享实例，该实例在容器启动或第一次请求时创建，容器关闭时销毁
- `prototype` 原型
    每次通过容器获取 Bean 时，都会创建一个新的实例。其销毁由 GC 决定。注意，在 singleton Bean 中注入 prototype Bean 时要小心，因为 singleton Bean 只创建一次，所以 prototype Bean 也只会创建一次，这时候可用 `@Lookup` 注解或者 `ApplicationContext` 动态获取
- `request` 请求 `WebApplicationContext.SCOPE_REQUEST`
    **仅 Web 应用可用**，为每一个 HTTP 请求创建一个新的 Bean，请求结束时销毁
- `session` 会话 `WebApplicationContext.SCOPE_SESSION`
    **仅 Web 应用可用**，为每一个 HTTP Session 创建一个新的 Bean，Session 失效时销毁
- `application` 应用 `WebApplicationContext.SCOPE_APPLICATION`
    **仅 Web 应用可用**，为整个 Web 应用创建一个 Bean，其与 `singleton` 的区别在于，前者在整个 Web应用中共享，无论几个 spring 容器均只有一个，后者在每个 JVM 中一个 Bean
- `websocket` 
    **仅 Web 应用可用**，为每一个 `websocket` 会话创建一个 Bean，绘画结束后销毁

无状态的服务类使用默认的 `singleton`。

单例作用域下，由于只有一个 Bean，所以可能会存在线程安全问题，而在原型作用域下，则不太可能产生线程安全问题。不过，大部分 Bean 都是无状态（没有可变的成员变量）的，也就不存在资源竞争的问题，线程安全。

对于状态单例下的 Bean 线程安全问题，常见的解决办法是
- 避免存在可变成员变量，尽量设计其为无状态
- 将可变成员变量存在 `ThreadLocal` 中
- 使用各种锁进行同步控制

#### 生命周期

{% note danger %}
字节跳动, 中国交易与广告 - 实习, 一面
{% endnote %}

1. 实例化
    spring 容器通过 Bean 的构造方法（默认是无参构造，或指定的有参构造）来创建一个新的对象实例。此时的对象属性还是默认值。
2. 属性赋值/依赖注入
    通过 `@Autowired` `@Resource` 注入依赖对象，通过 `@Value` 注入配置值。
3. 初始化
    Bean 的属性已注入完毕，但可能还需要执行一些自定义的初始化逻辑。初始化的顺序如下
    1. `BeanPostProcessor.postProcessBeforeInitialization`
        容器级别的处理器，对所有 Bean 生效，对 Bean 的任何初始化方法都在被调用前执行，可用于修改 Bean 的包装类，进行某些检查等
    2. `Aware` 接口回调
        如果 Bean 实现了这种接口，spring 容器就会回调响应的方法，将容器本身的一些信息“感知”给 Bean。
        常用的接口为
        - `ApplicationContextAware`: 给 Bean 设置 `ApplicationContext`（Spring 容器本身），让 Bean 能直接获取容器里的其他 Bean
        - `BeanNameAware`: 设置 Bean 的 ID/名字, 然 Bean 知道自己在容器中叫什么
        - `BeanFactoryAware`: 设置 BeanFactory, 让 Bean 能通过工厂获取其他 Bean
        - `BeanClassLoaderAware`: 设置当前 Bean 的类加载器
    3. `@PostConstruct` 注释
        这是 JSR-250 规范提供的注解，标记在方法上，在依赖注入完后立即执行。这是最推荐使用的初始化注解，因为它和 spring 解耦
    4. `InitializingBean.afterPropertiesSet`
        spring 提供的接口，用于重写该方法
    5. `init-method`
        在 Bean 定义中通过 `@Bean(initMethod = "myInit")` 指定自定义方法，这是另一种解耦的方式
    6. `BeanPostProcessor.postProcessAfterInitialization`
        在 Bean 的所有初始化方法都执行之后执行。string AOP 在这里为 Bean 创建代理对象的
4. 使用期
    现在的 Bean 已经随时可以使用了
5. 销毁
    在 spring 容器被关闭（调用 `applicationContext.close()` 或 web 应用关闭），容器会管理 Bean 的销毁。销毁的顺序如下
    1. `@PreDestroy` 注解
        JSR-250 规范提供的注解
    2. `DisposableBean.destroy`
        spring 提供的接口
    3. `destroy-method`
        在 Bean 定义中通过 `Bean(destroyMethod = "myDestroy")` 指定自定义方法

### 容器

Java web 中的容器有两种，spring 容器和 web 容器。

#### 是什么
1. web 容器
    - 是一个运行时环境，管理着 web 应用的生命周期，用于处理各种网络协议
    - 管理组件: 管理 Servlet、Filter、Listener 等 web 层面的组件
    - 生命周期: 在服务器启动时就初始化
    - 常见实现: Tomcat、Jetty、Undertow 等

2. spring 容器
    - 是一个 IoC 和 Bean 的管理框架，管理所有由它创建的 Bean，包括上文提到的各种 `@Component`
    - 核心能力: 依赖注入, AOP, 事务管理等

#### 传统 Spring MVC 中二者的关系

在传统的 Spring MVC + 外置 Tomcat 的架构下:

1. 先启动 Web 容器
    Tomcat 启动, 加载应用(war 包).
2. web 容器初始化 DispatcherServlet
3. DispatcherServlet 启动 Spring 容器
    这个 Servlet 会创建 Spring IoC 容器, 扫描包路径, 创建并装配好所有的 Bean.

#### Spring Boot 中二者的关系

Spring Boot 中由于采用了内嵌的 Web 容器, 所以其启动顺序和传统架构完全相反

1. 先启动 Spring 容器
    执行 jar 包, 启动 Spring 应用上下文 `ApplicationContext`
2. 启动内嵌 web 容器
    Spring Boot 的自动配置检测到 classpath 中有 web 依赖, 开始自动启动内嵌 Tomcat
3. 自动注册 DispatcherServlet
    Spring 容器将 DispatcherServlet 自动注册到内嵌 Tomcat 中, 完成 web 环境集成

#### Spring 的自动装配

spring 容器会在启动时自动扫描 `@ComponentScan` 指定包下的所有类，然后根据类上的注解，来判断哪些 Bean 需要被**自动装配**。

自动装配一般有 `byType`、`byName`、`constructor`、`autodetect` 四种

`@Autowired` 下默认为 `byType`，`@Resource` 注解默认按名称装配

### IoC 实现机制

IoC 的本质是一个高度可配置、可扩展的 Bean 工厂。其核心是 `BeanFactory` 和 `ApplicationContext` 容器。我们通过各种注解告诉工厂自己需要什么产品，产品有什么特性，需要什么原材料，等等。然后工厂里的各种生产线（在 spring 中就是各种 `BeanPostProcessor`）进行生产和缓存。工厂里还有各种缓存机制用来存放产品。

1. 加载 Bean 的定义信息
    spring 会扫描我们配置的包路径。找到所有标注了相关注解的类.
    然后将写类的元信息封装成 `BeanDefinition` 对象，注册到容器的 `BeanDefinitionRegistry` 中.
    这个阶段只是收集信息，还没有真正创建对象.
2. 准备 Bean 工厂
    spring 会创建一个 `DefaultListableBeanFactory` 作为 Bean 工厂来负责 Bean 的创建化和管理
    以 `ApplicationContext` 为例，启动过程的核心是 `refresh()` 方法，该方法包含准备 Bean 工厂、加载 Bean 定义、实例化所有单例 Bean 三步骤
3. Bean 实例化和初始化
    spring 会根据 `BeanDefinition` 来创建 Bean 实例
    对于单例 Bean，spring 会先检查缓存中是否已经存在，如果不存在就创建新实例
    创建实例[参照生命周期部分](#生命周期)

`BeanFactory` 和 `ApplicationContext` 的区别在于

||`BeanFactory`|`ApplicationContext`|
|-|-|-|
|定位|IoC 底层核心接口|在 IoC 的基础上，提供完整的应用框架上下文|
|Bean 加载策略|懒加载：只有在使用 `gerBean()` 请求时，才会实例化 Bean|预加载/饿汉式：容器启动时，立即实例化所有单例 Bean（非懒加载的）。有助于提前发现配置错误|
|容器功能|基础的 Bean 生命周期管理、依赖注入|额外提供 `BeanFactory` 外的国际化、AOP 集成、Web 应用上下文等功能|
|适用场景|资源及其受限的环境|绝大多数 Java EE 应用|

### 懒加载

`@Lazy` 用来标识类是否需要懒加载/延迟加载，可以作用在类或方法上。也可以在配置文件中设置懒加载

```properties
spring.main.lazy-initialization=true
```

如非必要，一般不用全局懒加载。全局懒加载会让 Bean 的第一次使用加载会变慢，并且会延迟应用程序问题的发现（Bean 被加载时问题才会出现）。

## AOP

{% note danger %}
腾讯混元 - 实习, 一面.
{% endnote %}

AOP 能够将那些和业务无关，但为业务模块所共同调用的逻辑（如事务处理、日志管理、权限控制等）封装起来，便于减少系统的重复代码，降低模块间的耦合度。

实现 AOP 需要使用**代理对象**，代理对象实现与目标 Bean 相同的接口或子类，因此它和原始对象没有任何区别。然而，在代理对象的方法内部，包含了处理 AOP 的其他逻辑。

spring AOP 基于动态代理。如果要代理的对象实现了某个接口，那么 spring AOP 会使用 JDK Proxy 去创建代理对象。而对于没有实现接口的对象，spring 会使用 Cglib 生成一个被代理对象的子类来来作为代理。但在目前，主流的 AOP 框架为 AspectJ。

![两种代理对象的区别](230ae587a322d6e4d09510161987d346.jpeg)

### JDK 代理

JDK 代理要求目标类至少实现一个接口，因为它是基于接口来实现代理的。而 Cglib 代理不需要目标类实现接口，它是通过继承目标类来创建代理的，这是两者最根本的区别。

从实现原理来说，JDK 代理是 Java 原生支持的。当我们调用代理对象的方法时，会被转发到 `InvocationHandler` 的 `invoke` 方法中，我们可以在这个方法里插入切面逻辑，然后再通过反射调用目标对象的真实方法。而 Cglib 是第三方的字节码生成库，它通过 ASM 字节码框架动态生成目标类的子类，然后重写父类的方法来插入切面逻辑。

例如，在 `@Controller` 中的类，就只能使用 Cglib 代理；而定义了接口的 `@Service`，通常首选 JDK 动态代理。

在 spring boot 2.0 后。spring AOP 默认使用 Cglib 代理。毕竟 spring boot 作为“约定优于配置”的框架，选择 Cglib 可以简化操作。

使用 JDK 动态代理时，使用方法如下

```java
// 代理处理器
class LogInvocationHandler implements InvocationHandler {
    private Object target;
    
    public LogInvocationHandler(Object target) {
        this.target = target;
    }
    
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("方法调用前: " + method.getName());
        Object result = method.invoke(target, args);
        System.out.println("方法调用后: " + method.getName());
        return result;
    }
}

// 使用
UserService target = new UserServiceImpl();
UserService proxy = (UserService) Proxy.newProxyInstance(
    target.getClass().getClassLoader(),
    target.getClass().getInterfaces(),
    new LogInvocationHandler(target)
);
proxy.save();
```

该代理机制中 `InvocationHandler` 接口和 `Proxy` 类是核心。而 `Proxy` 类中使用频率最高的方法是 `newProxyInstance()`，这个方法主要用于生成一个代理对象。该方法有三个参数
- loader 类加载器，加载代理对象
- interfaces 被代理类实现的一些接口
- h 实现了 InvocationHandler 接口的对象
    这个逻辑当中，这个方法的调用就会被转发到实现 `InvocationHandler` 接口类的 `invoke` 方法调用。该方法有下面三个参数
    - proxy 动态生成的代理类
    - method 与代理类对象调用的方法相对应
    - args 调用 method 方法时的参数

### CGLIB 代理

而 Cglib 的实现方式如下

```java
// 方法拦截器
class LogMethodInterceptor implements MethodInterceptor {
    public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
        System.out.println("方法调用前: " + method.getName());
        Object result = proxy.invokeSuper(obj, args);
        System.out.println("方法调用后: " + method.getName());
        return result;
    }
}

// 使用
Enhancer enhancer = new Enhancer();
enhancer.setSuperclass(UserServiceImpl.class);
enhancer.setCallback(new LogMethodInterceptor());
UserService proxy = (UserService) enhancer.create();
proxy.save();
```

CGLIB (Code Generation Library) 是一个基于 ASM 的字节码生成库，它允许我们在运行时对字节码进行修改和动态生成。在该代理机制中， `MethodInterceptor` 接口和类 `Enhancer` 类是核心。需要自定义 `MethodInterceptor` 并重写 `intercept` 方法，该方法用于拦截增强被代理类的方法。

```java
public interface MethodInterceptor
extends Callback{
    // 拦截被代理类中的方法
    public Object intercept(Object obj, java.lang.reflect.Method method, Object[] args,MethodProxy proxy) throws Throwable;
}
```

参数有
- obj 被代理的对象
- method 被拦截的方法
- args 方法入参
- proxy 用于调用原始方法

首先，CGLIB 需要定义一个类。然后，自定义 `MethodInterceptor` 并重写 `intercept` 方法。最后通过 `Enhancer` 类的 `create()` 方法创建代理类。

### 相关术语

AOP 切面编程涉及到的相关术语（或者说概念）有

|术语|含义|
|-|-|
|目标 `Target`|被通知的对象|
|代理 `Proxy`|向目标对象应用通知后创建的代理对象|
|连接点 `JoinPoint`|目标对象的所属类中，定义的所有方法均为连接点|
|切入点 `PointCut`|被切面拦截/增强的连接点（切入点属于连接点）|
|通知 `Advice`|增强的逻辑/代码，拦截到目标对象的连接点后要做的事情|
|切面 `Aspect`|切入点 + 通知|
|织入 `Weaving`|将通知应用到目标对象，进而生成代理对象的过程动作|

相比 spring AOP，AspectJ 
- 通过在编译时增强、类加载时增强（直接操作字节码）而非在运行时增强（基于动态代理）
- 支持方法级、字段、构造器、静态方法等切入点，但 spring AOP 只支持方法级
- 运行时无代理开销，性能更高
- 适合高性能，高复杂度的 AOP 需求

spring AOP 是在 Bean 初始化阶段发生的，具体来说是在 Bean 生命周期的后置处理阶段。在 Bean 实例化和属性注入完成后，spring 会调用所有的 `BeanPostProcessor` 的 `postProcessAfterInitialization` 方法，AOP 代理的创建就是在这个阶段完成的。

{% note success %}
AOP 和反射的区别在于，反射主要是为了让程序能够检查和操作自身的结构，而 AOP 则是为了在不修改业务的前提下，动态地为方法添加额外的行为。
{% endnote %}

{% note success %}
AOP 和装饰器模式的区别在于，装饰器模式是通过创建一个包装类来实现的，这个包装类持有被装饰对象的引用，并在调用方法时添加额外的逻辑。而 AOP 是通过代理对象或者其他方式实现的。
{% endnote %}

## `@Async` 注解原理

在启动类上添加注解 `@EnableAsync`，开启异步任务支持，然后在异步执行的方法上添加注解 `@Async`，这个方法就会异步执行。

在一个方法上标注 `@Async` 时，spring 会创建一个代理对象。调用这个代理对象时，拦截器将这个方法调用封装成一个 `Runnable` 任务，然后拦截器将这个任务提交给一个 `TaskExecuter`（线程池）。

一旦任务被成功提交到线程池，代理对象的拦截过程就结束了。`triggerAsync()` 方法中的调用会立刻返回（返回一个 `void` 或一个占位符 `Future`），主线程可以继续执行后面的各种语句，不受影响。

线程池会从它的线程池中分配一个空闲的工作线程，这个工作线程会执行上面封装好的 `Runnable` 任务，调用真正对象的方法。因此，主线程和工作线程是并发进行的。

如果没有显式配置线程池，在 `@Async` 底层会先在 `BeanFactory` 中尝试获取线程池。获取不到则会创建一个 `SimpleAsyncTaskExecutor` 实现，但这个执行器对于每个请求都会启动一个线程，而非使用线程池。因此在使用这个注解前，需要显式配置一个线程池，推荐为 `ThreadPoolTaskExecutor`。

另外, 由于代理的是一个 Bean 而非方法本身, 因此对于某个方法中调用 `@Async` 注解, 但在同类中通过 `this.method()` 调用, 是没有用的. 解决方法有以下 3 种:
- 直接拆成两个类
- `@Autowired` 自己, 自己调用自己
- 使用 `AopContext` 获取代理对象, 即 `(Bean) AopContext.currentProxy()` 获取代理 Bean.

## 事务

spring 中的事务分两种：编程式事务和声明式事务。
- 编程式事务：在代码中硬编码，在分布式系统中推荐使用。通过 `TransactionTemplate` 或者 `TransactionManager` 手动管理事务。若事务范围过大，会出现事务未提交导致超时，因此事务比锁的粒度更小
- 声明式事务：在 xml 配置文件中配置或者直接基于注解，实际通过 AOP 实现（使用注解 `@Transaction` 最多）

### 事务传播行为 `propagation`

当事务方法被另一个事务方法调用时，必须指定事务应该如何传播，是继续在现有事务中运行，还是新开一个事务。正确的事务传播薪给的值如下：
1. `TransactionDefinition.PROPAGATION_REQUIRED`
    使用最多的一个事务行为，默认值。若当前存在事务则加入该事务；若当前没有事务则创建一个新事务
2. `TransactionDefinition.PROPAGATION_REQUIRES_NEW`
    创建一个新事务。若当前存在事务，则将当前事务挂起。不管外部方法是否开启事务，该方法都会开启新事务
3. `TransactionDefinition.PROPAGATION_NESTED`
    若当前存在事务，则创建一个事务作为当前事务的嵌套事务进行；若当前没有事务，则创建一个新事务
4. `TransactionDefinition.PROPAGATION_MANDATORY`
    若当前存在事务，则加入该事务；若当前没有事务，则抛出异常

以下三种级别，事务在发生错误时可能不会回滚

5. `TransactionDefinition.PROPAGATION.SUPPORT`
    若当前存在事务，则加入该事务；若当前没有事务，则以非事务的方式运行
6. `TransactionDefinition.PROPAGATION_NOT_SUPPORT`
    非事务方式运行，若存在事务则把当前事务挂起
7. `TransactionDefinition.PROPAGATION_NEVER`
    非事务方式进行，若存在事务则抛出异常

### 事务隔离级别 `isolation`

和数据库一样，spring 也支持事务隔离，其级别和 SQL 差不多
- `TransactionDefinition.ISOLATION_DEFAULT`
    使用后端数据库默认的隔离级别
- `TransactionDefinition.ISOLATION_READ_UNCOMMITTED`
    读未提交
- `TransactionDefinition.ISOLATION_READ_COMMITTED`
    读已提交
- `TransactionDefinition.ISOLATION_REPEATABLE_READ`
    可重复读
- `TransactionDefinition.ISOLATION_SERIALIZABLE`
    可串行化

四种隔离级别的区别详见[https://ivanclf.github.io/2025/10/11/sql-2/#隔离级别](https://ivanclf.github.io/2025/10/11/sql-2/#%E9%9A%94%E7%A6%BB%E7%BA%A7%E5%88%AB)

### 事务属性

- 超时属性
    事务超时就是指一个事务所允许执行的最长时间，若超时则自动回滚。在 `TransactionDefinition` 中以 int 值表示超时时间，单位是秒，默认为 -1，表示超时时间取决于底层系统或没有超时时间。
- 只读属性
    对于只有读取数据查询的事务，可以指定事务类型为 `readonly`，即只读事务。由于不涉及数据的修改，数据库会提供一些优化手段，适合用在有多条数据库查询操作的方法中。

### 声明式事务

当在配置类上使用 `@EnableTransactionManagement` 后，spring 容器会向容器中注册一个关键的 Bean 后处理器—— `InfrastructureAdvisorProxyCreator`。这个类的作用很明确，就是一个“自动代理创建器”，用于在 Bean 初始化后阶段，扫描容器中所有的 Bean，判断哪些 Bean 存在 `@Transactional` 注解，需要被代理。

如果匹配成功，spring 会通过 JDK 动态代理或 Cglib 代理来创建代理。

其底层是通过 `ThreadLocal` 来实现的. `ThreadLocal` 对象用于存储当前宪曾的数据库链接, 事务是否只读, 事务是否需要回滚.

在以下情况下，`@Transactional` 注解会失效
- 自调用。spring 事务基于 AOP 代理，自调用绕过了代理机制(如 `@Async` 注解)
    这是最常见的一个问题. 主线程进入方法时, AOP 先开事务, 主线程往 ThreadLocal 里放数据, 但接着 `@Async` 注解把方法包装成 `Runnable` 丢进线程池里了, 主线程的 ThreadLocal 就直接不需要了. 同时新线程的 ThreadLocal 因为没有被事务代理, 因此是空的.
- 抛出注释中没指定 `rollbackFor` 的异常
    进入方法, 抛出异常后, spring 会认为这个异常不在回滚规则里, 因此会直接提交事务. 也就出现异常抛出去了, 数据却提交了, 没有回滚, 因此看起来像"事务失效".
- 不是 `public` 方法，spring 创建不了代理

## spring MVC

spring MVC 是 spring 这一个大框架中专用于 web 服务器的模块. 其核心组件有以下几种
- `DispatcherServlet` 核心的中央处理器，负责接收请求、分发，并给予客户端响应
- `HandlerMapping` 处理器映射器，根据 URL 去匹配查找能处理的 `Handler`，并会将请求涉及到的拦截器和 `Handler` 一起封装
- `HandlerAdapter` 处理器适配器，根据找到的 `Handler` 去适配执行对应的 `Handler`
- `Handler` 请求处理器，处理实际请求的处理器
- `ViewResolver` 视图解析器，根据 `Handler` 返回的逻辑视图/视图，解析并渲染真正的驶入，并传递给 `DispatcherServlet` 客户端

### 工作原理

1. 当一个 HTTP 请求到达服务器时，首先由 `DispatcherServlet` 接收。它负责将请求分发到合适的处理器，也就是 `@Controller` 中的方法，并协调其他组件的工作。
2. `DispatcherServlet` 查询配置的 `HandlerMapping`。后者扫描是所有带有 `@Controller` 或 `@RestController` 的 Bean，找到对应路由的具体方法。
3. 找到对应方法后，`DispatcherServlet` 会委托给 `HandlerAdapter` 进行调用。在注解驱动开发中，常用的是 `RequestMappingHandlerAdapter`，这一层会把请求参数自动注入到方法形参中，并调用 Controller 执行实际的业务逻辑。
4. Controller 方法最终会返回结果，比如视图名称、ModelAndView 或直接返回 JSON 数据
5. 渲染完成的 HTML 或者换好的 JSON 数据，通过 `HttpServletResponse` 返回给客户端

其中的 `HandlerAdapter` 用于处理多种风格的处理器调用方式，屏蔽不同控制器的差异。

传统的 MVC 中，返回的数据通常是 HTML 页面。但在 RESTful 架构中，通常返回的是 JSON 或 XML，而不再是一个完整的页面。当一个类上使用 `@RestController` 时，它会告诉 spring 这个类中所有方法的返回值都应该直接写入 HTTP 响应体中，而不再被解析为视图。`@ResponseBody` 是其在方法级别的呈现。

## spring boot

spring boot 是 spring 生态的一个重大突破，它极大简化了 spring 应用和开发过程。**约定大于配置**是 spring boot 最核心的概念。它预设了很多的默认配置。

比如 `@SpringBootApplication` 标志着一个 spring boot应用的入口，包含了 `@Configuration`、`@EnableAutoConfiguration`、`@ComponentScan` 等注解

### 自动装配

开启自动装配的注解是 `@EnableAutoConfiguration`。这个注解会告诉 spring 去扫描所有可用的自动配置类。当 main 方法执行的时候，spring 回去类路径下找 `spring.factory` 这个文件，读取里面配置的自动配置类列表。在每个自动配置类的内部，通常会有一个 `@Configuration` 注解，同时结合各种 `@Conditional` 注解来做控制。常用的条件注解为

|注解|作用|
|-|-|
|`@ConditionalOnClass`|类路径下存在指定类时生效|
|`@ConditionalOnMissingClass`|类路径下不存在指定类时生效|
|`@ConditionalOnBean`|容器中存在指定 Bean 时生效|
|`@ConditionalOnMissingBean`|容器中不存在指定 Bean 时生效|
|`@ConditionalOnProperty`|配置文件中存在指定属性时生效|
|`@ConditionalOnWebApplication`|当前是 web 应用时生效|
|`@ConditionalOnExpression`|SpEL 表达式为 true 时生效|

### spring boot starter

starter 本质是一套可复用的自动配置包, 让其他项目引入后就能"开箱即用".

1. starter 结构
    通常将 starter 分成两个模块：启动器模块和自动配置模块。
    1. 启动器模块: 只管理依赖, 不写业务逻辑, 方便引入使用.
    2. 自动配置模块: 包含核心配置逻辑, 业务类, 配置属性绑定
2. 定义配置属性类。
    让用户可以在 `application.yml` 或其他文件中自定义参数, Spring Boot 会自动绑定并注入.
3. 编写业务服务类
4. 创建自动配置类
    使用上文的条件注解控制何时生效.
5. 注册自动配置类
    将自动配置类注册到 `resources/META-INF/` 下的 `spring.factories` 文件中, 让 Sprig Boot 启动时能自动发现并加载

## 启动

{% note danger %}
美团后台开发 - 暑期实习, 二面.
{% endnote %}

### Spring

1. 加载配置
    spring 启动时, 会读取 XML, JavaConfig 或注解中的配置信息, 确定要管理的 Bean, 扫描范围, 依赖关系等.
2. 创建容器
    根据配置创建 `ApplicationContext` 容器, 其本质是一个 BeanFactory, 负责 Bean 的生命周期管理.
3. 扫描和注册 Bean
    - 扫描指定包下的 `@Component`
    - 将类信息封装成 `BeanDefinition`, 注册到 BeanFactory 中
4. 实例化和初始化 Bean
    - 实例化 Bean 对象
    - 填充依赖 (DI 依赖注入)
    - 执行初始化方法
    - 完成创建
5. 容器刷新完成, 发布上下文刷新事件, 应用可以正常接收请求

### Spring Boot

1. 启动入口
    执行 `main` 方法, 调用 `SpringApplication.run(Application.class, args)`
    传入的主类上带有 `@SpringApplication`, Spring Boot 以此为核心进行启动
2. 创建 `SpringApplication` 实例
    启动前先构建启动器, 主要做三件事:
    - 判断应用类型, 看是不是 Servlet Web / Reactive / 普通应用
    - 加载初始化器和监听器
    - 确定主配置类
3. 执行 `run()` 核心流程
    1. 准备运行环境, 加载配置文件, 如 `application.yml` 等
    2. 创建对应类型的 Spring 应用上下文
    3. **刷新上下文**
        - 扫描, 解析, 注册 Bean
        - 执行自动配置, 加载大量默认组件
        - 初始化所有单例 Bean
        - 启动内嵌 web 服务器
4. 容器启动前, 发布就绪事件, 项目正式运行

### 简略版

Spring 相比原生 Java, 提供了 IoC 容器, 对象不用自己 `new`, 统一交给容器管理, 创建, 注入, 适合复杂项目里大量对象的依赖维护.

但 Spring 只提供容器, 但哪些是 Bean, 要配那些组件还需要自己写, 自己配置.

Spring Boot 相比 Spring, 会提前帮你预定义, 自动装配了大量常用 Bean, 比如数据库, MVC, 事务, 模板引擎等, 开箱即用. Tomcat 自然也是这堆 Bean 的一部分, 所以也会在启动时一并创建并启动 web服务器.