---
title: Java高级特性
date: 2025-09-26 08:40:25
tags: [java]
category: web
---

[参考文献](https://javabetter.cn/sidebar/sanfene/javase.html)

{% note success %}
- JVM: Java Virtual Machine
- JRE: Java Runtime Environment
- JDK: Java Development Kit

{% endnote %}

## 面向对象，多态

多态就是“同一个行为，不同对象有不同的实现方式”。对于同一个方法，在同一父类下的不同子类都会有不同的反应。编译时，编译器只认某个变量的类型为其父类，只要父类中有这个方法，代码就能通过。而在运行时，jvm会查看变量指向的对象实际是什么，再调用真正的方法。这叫“动态绑定”或“运行时多态”。而在重写方法时，子类会复制一份父类的方法到自己的虚方法中。在调用方法时，若子类实现了该方法，则直接调用；反之调用指针指向的父类方法。

{% note info %}
以下是几个面向对象的设计原则：
里氏代换原则：父类能出现的地方子类也一定能出现
单一职责原则：一个类只负责一项职责
开闭原则：软件实体就扩展开放，对修改关闭（添加新功能时应该增加代码而非修改原有代码）
接口隔离原则：客户端不应该依赖它不需要的接口
依赖倒置原则：高层模块不应该依赖于底层模块，二者都应该依赖于抽象；抽象不应该依赖于细节，细节应该依赖于抽象
{% endnote %}

## equals和hashCode

为什么重写equals的时候必须也重写hashCode？hashCode方法用于获取哈希码，返回一个int整数。该整数多用于存放hashMap中的key。只重写了equals方法可能会导致hashMap不符合预期的问题。哈希码可能会一致，hashMap在处理键时，不仅会比较键对象的哈希码，还会使用equals方法检查键对象是否真正相等。

## String，StringBuilder和StringBuffer

`String`对象本身是不可变的，每次对`String`对象进行修改操作时（比如加号操作），实质上都会先生成一个`StringBuilder`对象执行`.append()`操作，再使用`.toString()`方法换上去。这可能会导致不必要的内存和性能开销。因此在需要操作大量字符串的情况下，可以采用`StringBuilder`类实现。`StringBuilder`提供了一系列方法进行字符串的增删改查操作，这些操作都是在字符串原有的字符数组上实现的，不会产生新的`String`对象。`StringBuffer`是`StringBuilder`的线程安全版，方法前面都加有`synchronized`关键字。但真有人在并发状态下编辑字符串吗？

使用`String s = "abc"`（字面量方式）创建新的`String`对象时，jvm会首先检查字符串常量池中是否会存在`"abc"`，若存在则直接返回常量池中的引用，否则则在常量池中创建`"abc"`对象，然后返回其引用。
而使用`String s = new String("abc")`（`new`关键字方式）创建新的`String`对象时，除了在常量池进行类似操作外，还会在堆内存中创建一个新的`String`对象，并且往后都会指向堆内存中的新对象。
因此一般推荐使用字面量方式来初始化字符串。如果想使用`new`关键字方式实现类似字面量方式的效果，需要加`.intern()`方法，即`String s = new String("abc").intern()`。

`String`的不可变性使得`String`对象在使用时更加安全，更容易缓存和重用，并且能作为某些集合类的键。为了保证其不可变性，该类有`final`声明，防止被继承；字符数组成员定义为`private final char value[]`；每一次调用方法实际上都返回一个新的对象；每次构造时都会传递一份拷贝而非参数本身。

将`String`转换为`Integer`有两种方法，一种是`Integer.parseInt(String s)`，一种是`Integer.valueOf(String s)`，但两种最终都会调用`Integer.perseInt(String s, int radix)`方法，其中是简单的字符串遍历算法。

## 包装类缓存机制

对基本类型的包装类，Java提供了缓存机制

|包装类|缓存范围|备注|
|-|-|-|
|`Integer`|-128~127|默认范围|
|`Byte`|-128~127|全部缓存|
|`Short`|-128~127|默认范围|
|`Long`|-128~127|默认范围|
|`Character`|0~127|ASCII字符范围|
|`Boolean`|`true` `false`|都缓存|

{% note info %}
可以在运行时添加 `-Djava.lang.Integer.IntegerCache.high = 10000`来调整缓存的最大值为10000。
{% endnote %}

因此对于如下语句

```java
Integer a = 127;
Integer b = 127;
return a == b;
```

会返回true，因为在缓存区内，对象引用都是缓存区里的对象。而对于如下语句

```java
Integer a = 128;
Integer b = 128;
return a == b;
```

会返回false，因此不再缓存区内，这是两个不同的对象。若需要判断值是否相等，则最好调用`.equals()`方法。

总之，基本类型的包装类会部分或全部先缓存好，在新建包装类时若基本类的值在缓存内，jvm直接返回其缓存中的地址。

## Object类中的基本方法

Object类是所有类的父类，其中定义了所有对象都能用的方法。

- `hashCode()`
    返回对象的哈希码。若重写了`equals()`方法，则必须要重写`hashCode()`方法。
- `equals()`
    比较二者的内存地址是否相等（对象名本身存储着的就是地址），若需要通过比较其他部分来判断则需要重写。
- `clone()`
    返回某个对象的浅拷贝，需要该对象实现`Cloneable`接口，否则会报`CloneNotSupportedException`错误。
    {% note info %}
    浅拷贝只拷贝本身，深拷贝递归地拷贝其子类。
    {% endnote %}
- `toString()`
    实现对象转字符串，默认返回类名@哈希码的十六进制表示，若要返回其他类型的字符串则需要重写。该方法也可以交给Lombok的`@Data`注解自动生成。而数组也是一个对象，直接调用`toString()`方法也会看到哈希码结果。
- `wait()` `notify()`
    多线程下的线程等待和唤醒。
- `getClass()`
    返回对象的类信息，返回值的类型为`Class<?>`，在反射中常用。
- `finalize()`
    垃圾回收，若需在回收时自定义则调用次方法，但在Java 9已弃用。

{% note success %}
对于异常的处理机制，此处不单开一章了。
若在`try`块中`return`，`finally`块会先执行再返回。若`finally`也有`return`，则返回`finally`中的结果。而在这一块代码中

```java
public static int test() {
    int i = 0;
    try {
        i = 2;
        return i;
    } finally {
        i = 3;
    }
}
```

会返回2而不是3。在`try`块开始`return`时，不是立即返回，而是先算出需要`return`的值，然后将该值进行缓存，然后跳转到`finally`块。此时的`finally`改变的仅是局部变量的值而非缓存里的值，因此无法改变其缓存。
{% endnote %}

## IO流

流的分类方式有很多种。可以按照其流动方向将其分为**输入流**和**输出流**；按照其数据单位分为处理音频、图像等二进制数据的**字节流**，和处理文本数据的**字符流**；按功能划分为与输入输出端相连的**节点流**，对已存在的流进行包装的**缓冲流**，进行线程间的数据传输的**管道流**。

![流的分类](stream.png)

当生产消费速度不匹配，数据写入速度大于读取/处理速度时（比如客户端发送数据过快，文件写入速度过快，控制台输入数据过多等），可能会导致缓冲区无法容纳更多数据而出现异常或数据丢失的问题。为了避免此类问题，可以合理设置缓冲区大小，或者控制写入的数据量，进行流量控制，或者使用NIO的非阻塞IO。

字节流是由jvm将字节转换得到的，该过程比较耗时且容易出现乱码问题，因此IO流也提供了直接操作字符的字符流。在大文本中查找某个字符串时更推荐使用字符流，对视频文件通常使用字节流，并且尽量使用缓冲流来提高读写速度。

Java常见的IO模型有3种：BIO、NIO、AIO。
- **BIO**(Blocking IO)阻塞式IO，使用字节流或字符流，线程在执行IO操作时被阻塞，无法执行其他任务。适用于连接数较少且固定的架构，如传统HTTP服务器。
- **NIO**(Non-Blocking IO)同步非阻塞IO，使用多路复用器，轮询多个通道，只有就绪的通道才进行IO操作，线程在等待期间可以做其他事，通过轮询检查状态。使用于高并发场景，是目前的主流。
- **AIO**(Asynchronous IO)异步非阻塞IO，使用回调函数或`Future`，操作完成后IO主动通知。线程发起请求后立即返回，完全不等。适用于连接数多且连接时间长（如大型文件读写，数据库连接池等）的场景。

普通的对象要想转换成流，需要先进行**序列化**。序列化是指将对象转换为字节流的过程，而反序列化是将字节流转换回对象的过程。若希望将某个对象序列化，需要使用`Serializable`接口进行标记。
`serialVersionUID`是Java序列化机制种用于标识类版本的唯一标识符，该标识符要求在序列化和反序列化中保持一致，用于在序列化和反序列化的过程中，类的版本是兼容的。该标识符可以自己设定，可以由IDEA自动生成，也可以交由Java自动生成。
Java序列化不包含静态变量。这是因为序列化机制只保存对象的状态，而静态变量属于类的状态。
可以用`transient`关键字修饰不像想被序列化的变量。

序列化一般包括以下3个过程：先实现`Serializable`接口，然后使用`ObjectOutputStream`来将对象写入，最后调用其中的`writeObject()`方法，将对象序列化后写入输出流中。

序列化一般有3种方式：对象流序列化、json序列化、protoBuff序列化。一般使用的是json序列化，一般需要Jackson包，将对象转化为byte数组或String字符串。

## Socket套接字 与 RPC

Socket是网络通信的基础，表示两台设备间通信的一个端点，Socket通常用于简历TCP或UDP链接，实现进程间的网络通信。
使用socket实现一个简单的TCP通信。

TCP客户端

```java
class TcpClient {
    public static void main(String[] args) throws IOException {
        Socket socket = new Socket("127.0.0.1", 8080);

        BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        PrintWriter out = new PrintWriter(socket.getOutputStream(), true);

        // ...

        socket.close();
    }
}
```

TCP服务端

```java
class TcpServer {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(8080);
        Socket socket = serverSocket.accept();

        BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        PrintWriter out = new PrintWriter(socket.getOutputStream(), true);

        // ...

        socket.close();
        serverSocket.close();
    }
}
```

RPC框架是一种协议，允许程序调用位于远程服务器上的方法，就像调用本地方法一样。RPC通常基于Socket通信实现。
![RPC协议](rpc.png)

常见的RPC框架包括

1. gRPC：基于 HTTP/2 和 Protocol Buffers。
2. Dubbo：阿里开源的分布式 RPC 框架，适合微服务场景。
3. Spring Cloud OpenFeign：基于 REST 的轻量级 RPC 框架。
4. Thrift：Apache 的跨语言 RPC 框架，支持多语言代码生成。

RPC 可以使用多种传输协议，如 TCP、UDP 等，使用 IDL（接口定义语言）进行接口定义，如 `Protocol Buffers`、`Thrift` 等。也支持跨语言通信，可以使用 IDL 生成不同语言的客户端和服务端代码，其响应速度也比单纯的 HTTP 请求快了不少。

{% note success %}
常用的泛型通配符为 `?` `T` `K`/`V` `E`等。

Java的泛型是伪泛型，这是因为Java在编译期间，所有的类型信息都会被擦掉，也就是说，在运行的时候是没有泛型的。该特性主要是为了向下兼容，因为jdk5之前是没有泛型的。
{% endnote %}

{% note success %}
注解的生命周期有三大类，分别是：
- `RetentionPolicy.SOURCE`: 源码级别，给编译器用的，不会写入`class`文件。如`@Override`，Lombok的`@Getter`会在`class`文件中写入对应的`getter`，但注解本身不会保留。
- `RetentionPolicy.CLASS`: 会写入`class`文件，在类加载阶段丢弃。这是定义注解时的默认配置。如一些AOP框架或字节码增强库。
- `RetentionPolicy.RUNTIME`: 写入`class`文件，永久保存，并可以通过反射获取注解信息。如Spring框架中的`@Controller`等。
{% endnote %}

## 反射

反射允许Java在运行时检查和操作类的方法和字段。多用于Spring框架的加载和管理Bean和动态代理等。
Java程序的执行分为编译和运行两步。编译后会生成字节码文件，jvm进行类加载的时候，会加载这个字节码文件，将类型相关的所有信息加载进方法区，反射就是去获取这些信息。

可以通过该方法加载并实例化类

```java
// 根据传入的完整类名的字符串，动态地加载这个类到jvm中。返回一个Class对象
Class<?> cls = Class.forName("java.util.Date");
// 按照上一步获取的CLass对象，新建该类的一个实例。
Object obj = cls.newInstance();
```

获取并调用方法

```java
// 从Class对象中查找并获取一个特定的公共方法。
Method method = cls.getMethod("getTime");
// 调用上一步获得的方法。第一个参数指定在哪个对象上调用这个方法，后续的参数则是方法本身的参数。
Object result = method.invoke(obj);
```

访问字段

```java
// 从Java对象中获取一个声明的字段
Field field = cls.getDeclaredField("fastTime");
// 突破访问权限限制，对于私有变量需要这么做
field.setAccessible(true);
// 获取该字段的值。知道其Long类型就getLong，不知道则为get
Long number = field.getLong(obj);
```

{% note success %}
Lambda 表达式主要用于提供一种简洁的方式来表示匿名方法，使 Java 具备了函数式编程的特性。所谓的函数式编程，就是把函数作为参数传递给方法，或者作为方法的结果返回。
{% endnote %}

{% note success %}
`Optional`是用于防范`NullPointerException`的工具。可以将`Optional`看作是一种包装对象的容器，当某方法的返回值可能是空的时候可以使用该容器包装。
{% endnote %}

## Stream流

该特性可以对包含一个或多个元素的集合做各种操作，这些操作可能是中间操作或终端操作。中间操作能执行多次，而终端操作只能执行一次。

Stream的创建有多种方式。可以从集合创建，也可以从数组创建。
还可以使用`Stream.of()`方法显式声明。

```java
Stream<String> stream = Stream.of("a", "b", "c");
```

还可以使用lambda函数显式声明

```java
Stream<Integer> infiniteStream = Stream.iterate(0, n -> n + 2); // 无限偶数流
Stream<Double> randomStream = Stream.generate(Math::random); // 无限随机数流
```

常用中间操作如下

<table>
    <thead>
        <tr>
            <th>中间操作类别</th>
            <th>方法</th>
            <th>说明</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan="4">过滤操作</td>
            <td>filter()</td>
            <td>进行过滤，参数放匿名函数</td>
        </tr>
        <tr>
            <td>distinct()</td>
            <td>去重，不放参数</td>
        </tr>
        <tr>
            <td>limited()</td>
            <td>限制元素数量，参数放整数</td>
        </tr>
        <tr>
            <td>skip()</td>
            <td>跳过前n个元素，参数放整数</td>
        </tr>
        <tr>
            <td rowspan="2">映射操作</td>
            <td>map()</td>
            <td>一对一映射，将每个元素转换为另一个元素，然后将这些流合并为另一个流，参数是一个匿名函数</td>
        </tr>
        <tr>
            <td>flatMap()</td>
            <td>一对多映射，将所有生成的流片扁平化为一个流，参数是一个匿名函数</td>
        </tr>
        <tr>
            <td rowspan="2">排序操作</td>
            <td>sorted()</td>
            <td>自然排序</td>
        </tr>
        <tr>
            <td>sorted(Comparator.reverseOrder())</td>
            <td>自定义排序，这里是逆序</td>
        </tr>
    </tbody>
</table>

常用终端操作如下

<table>
    <thead>
        <tr>
            <td>终端操作类别</td>
            <td>方法</td>
            <td>说明</td>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan="3">匹配操作<br>返回Boolean</td>
            <td>allMatch()</td>
            <td>是否全部匹配，参数为匿名函数</td>
        </tr>
        <tr>
            <td>anyMatch()</td>
            <td>是否有匹配的，参数为匿名函数</td>
        </tr>
        <tr>
            <td>noneMatch()</td>
            <td>是否没有匹配的，参数为匿名函数</td>
        </tr>
        <tr>
            <td rowspan="2">查找操作</td>
            <td>findFirst</td>
            <td>返回第一个元素（如果有），没有参数</td>
        </tr>
        <tr>
            <td>findAny()</td>
            <td>在顺序流中返回第一个元素，在并行流中返回任意一个元素，没有参数</td>
        </tr>
        <tr>
            <td rowspan="3">规约操作</td>
            <td>reduce(0, Integer::sum)</td>
            <td>求和操作，实例中为给装Integer的集合求和，第一个参数为求和前的初始值<br>第二个参数为一个匿名函数，放置一个累加器</td>
        </tr>
        <tr>
            <td>count()</td>
            <td>计数，没有参数</td>
        </tr>
        <tr>
            <td>max()/min()</td>
            <td>最大最小值， 参数为匿名函数。Integer中为Integer::compareTo</td>
        </tr>
        <tr>
            <td rowspan="4">收集操作</td>
            <td>collect(Collection.toList())</td>
            <td>收集为某一集合类，实例中为转化为List</td>
        </tr>
        <tr>
            <td>collect(Collectors.joining(", "))</td>
            <td>按照特定的规则链接字符串，示例中为字符串间添加", "</td>
        </tr>
        <tr>
            <td>collect(Collectors.groupingBy())</td>
            <td>按照特定的规则分组，参数为匿名函数，返回一个值为List的Map</td>
        </tr>
        <tr>
            <td>collect(Collectors.partitioningBy())</td>
            <td>进行分区，将符合与不符合的元素分成两组，参数为匿名函数，返回值为值为List的Map</td>
        </tr>
    </tbody>
</table>