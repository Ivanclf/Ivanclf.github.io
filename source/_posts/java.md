---
title: Java高级特性
date: 2025-09-26 08:40:25
tags: [java]
category: web
---

参考文献
- [https://javabetter.cn/sidebar/sanfene/javase.html](https://javabetter.cn/sidebar/sanfene/javase.html)
- [https://javaguide.cn/java/basis/java-basic-questions-01.html](https://javaguide.cn/java/basis/java-basic-questions-01.html)
- [https://javaguide.cn/java/io/nio-basis.html](https://javaguide.cn/java/io/nio-basis.html)

## 基本知识

{% note info %}
`>>` 为带符号右移，符号位为1时高位补1，反之补0；`>>>` 为无符号右移，空位都以1补齐。
{% endnote %}

{% note success %}
- JVM: Java Virtual Machine，详见[另一篇](https://ivanclf.github.io/2025/10/06/jvm/)。
- JRE: Java Runtime Environment，Java 基础环境和类库。在 JDK 9 后，就不需要区分 JDK 和 JRE 的关系了/
- JDK: Java Development Kit，是一个功能齐全的 Java 开发工具包，用于创建和编译 Java 程序。

{% endnote %}

源码运行时，首先 `javac` 会将 `.java` 文件编译成 `.class` 文件，然后解释器或 JIT 再将 `.class` 文件转换成机器可理解的代码。

{% note info %}
`javac` 作为前端的编译器，任务是将 Java 类代码编译成 JVM 可理解的、平台中立的 `.class` 文件。两种文件其实差别不太大，因此主要进行以下操作
- 语法糖解糖，如将 `foreach` 转换为传统的 `for` 循环
- 常量折叠，如将 `int a = 1 + 2` 转换为 `int a = 3`
- 进行简单的语法检查

后端的 JIT 编译器详见 [JVM 的文章](https://ivanclf.github.io/2025/10/06/jvm/)

{% endnote %}

{% note success %}
程序将实参传递给方法的方式有两种：值传递和引用传递。前者接收实参值的拷贝，后者传递实参的地址。在 Java 中，严格来说只有值传递，因为对象名中存储的是示例的地址，而传递参数的时候也只是传递地址这个值。而这个值也是传递了一个副本，也就是指针的副本。
{% endnote %}

## 面向对象，多态

多态就是“同一个行为，不同对象有不同的实现方式”。对于同一个方法，在同一父类下的不同子类都会有不同的反应。编译时，编译器只认某个变量的类型为其父类，只要父类中有这个方法，代码就能通过。而在运行时，jvm会查看变量指向的对象实际是什么，再调用真正的方法。这叫“动态绑定”或“运行时多态”。而在重写方法时，子类会复制一份父类的方法到自己的虚方法中。在调用方法时，若子类实现了该方法，则直接调用；反之调用指针指向的父类方法。

{% note info %}
以下是几个面向对象的设计原则：
**里氏代换**原则：父类能出现的地方子类也一定能出现
**单一职责**原则：一个类只负责一项职责
**开闭原则**：软件实体就扩展开放，对修改关闭（添加新功能时应该增加代码而非修改原有代码）
**接口隔离**原则：客户端不应该依赖它不需要的接口
**依赖倒置**原则：高层模块不应该依赖于底层模块，二者都应该依赖于抽象；抽象不应该依赖于细节，细节应该依赖于抽象
{% endnote %}

## equals和hashCode

为什么重写equals的时候必须也重写hashCode？hashCode方法用于获取哈希码，返回一个int整数。该整数多用于存放hashMap中的key。只重写了equals方法可能会导致hashMap不符合预期的问题。哈希码可能会一致，hashMap在处理键时，不仅会比较键对象的哈希码，还会使用equals方法检查键对象是否真正相等。

## String，StringBuilder和StringBuffer

`String` 对象本身是不可变的，每次对 `String` 对象进行修改操作时（比如加号操作），实质上都会先生成一个 `StringBuilder` 对象执行 `.append()` 操作，再使用 `.toString()` 方法换上去。这可能会导致不必要的内存和性能开销。因此在需要操作大量字符串的情况下，可以采用 `StringBuilder` 类实现。`StringBuilder` 提供了一系列方法进行字符串的增删改查操作，这些操作都是在字符串原有的字符数组上实现的，不会产生新的 `String` 对象。`StringBuffer` 是 `StringBuilder` 的线程安全版，方法前面都加有 `synchronized` 关键字。但真有人在并发状态下编辑字符串吗？

使用 `String s = "abc"`（字面量方式）创建新的 `String` 对象时，JVM 会首先检查字符串常量池中是否会存在 `"abc"`，若存在则直接返回常量池中的引用，否则则在常量池中创建 `"abc"` 对象，然后返回其引用。
而使用 `String s = new String("abc")`（`new` 关键字方式）创建新的 `String` 对象时，除了在常量池进行类似操作外，还会在堆内存中创建一个新的 `String` 对象，并且往后都会指向堆内存中的新对象。
因此一般推荐使用字面量方式来初始化字符串。如果想使用 `new` 关键字方式实现类似字面量方式的效果，需要加 `.intern()` 方法，即 `String s = new String("abc").intern()`。

`String` 的不可变性使得 `String` 对象在使用时更加安全，更容易缓存和重用，并且能作为某些集合类的键。为了保证其不可变性，该类有 `final` 声明，防止被继承；字符数组成员定义为 `private final char value[]`；每一次调用方法实际上都返回一个新的对象；每次构造时都会传递一份拷贝而非参数本身。

将 `String` 转换为 `Integer` 有两种方法，一种是 `Integer.parseInt(String s)`，一种是 `Integer.valueOf(String s)`，但两种最终都会调用 `Integer.perseInt(String s, int radix)` 方法，其中是简单的字符串遍历算法。

`String` 不可变有两点原因
1. 保存字符串的数组被 `final` 修饰且为私有的，并且 `String` 类没有提供/暴露修改这个字符串的方法
2. `String` 类被 `final` 修饰导致其不能被继承，进而避免了子类破坏 `String` 不可变

在 Java 9 后， `String` 的底层实现由 `char[]` 改成了 `byte[]`，因为新版的 String 支持两个编码方案：Latin 1 和 UTF 16。若字符串中包含的汉字没有超过范围内的字符，就会使用 Latin 1 作为编码方案，因为 Latin 1 (8 bit) 比 UTF 16 (16 bit)，更节省内存空间。

由于字符串相加底层是通过 `StringBuilder` 的 `.append()` 方法且这个对象不会复用，因此在循环相加时会导致大量的对象开销。而在 JDK 9 中，字符串相加改用动态方法 `makeConcatWithConstants()` 实现，通过提前分配对象从而减少了部分临时对象的创建。

## 包装类

对于基本数据类型，都有对应的**包装类**。包装类属于对象类型。
- 基本数据类型的存放在 Java 虚拟机栈的局部变量表或 Java 虚拟机的堆中，包装类型存放在堆中。
- 成员变量包装类型若不赋值就是 null，而基本类型有默认值，且基本不是 null。因此需要特别注意包装类拆包时可能产生的 null 值问题。

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
可以在运行时添加 `-Djava.lang.Integer.IntegerCache.high = 10000`来调整缓存的最大值为10000。但不能修改下限 -128。

两种浮点数类型的包装类 `Float` `Double` 并没有实现缓存机制。
{% endnote %}

因此对于如下语句

```java
Integer a = 127;
Integer b = 127;
return a == b;
```

会返回 true，因为在缓存区内，对象引用都是缓存区里的对象。而对于如下语句

```java
Integer a = 128;
Integer b = 128;
return a == b;
```

会返回 false，因此不在缓存区内，这是两个不同的对象。若需要判断值是否相等，则最好调用`.equals()`方法。

总之，基本类型的包装类会部分或全部先缓存好，在新建包装类时若基本类的值在缓存内，jvm直接返回其缓存中的地址。

**装箱**即将基本类型用对应的包装类包装起来的过程，**拆箱**就是上述的逆过程。其实，装箱就是调用了包装类的 `valueOf()` 方法，拆箱就是调用了 `xxxValue()` 方法。

因此 `Integer i = 10` 等价于 `Integer i = Integer.valueOf(10)`，而 `int n = i` 等价于 `int n = i.intValue()`。

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

## 异常

Java 中的 Exception 和 Error 都有一个共同的祖先：`java.lang` 包中的 `Throwable` 类。区别在于
- Exception 指程序本身能处理的异常，能通过 `catch` 捕获。其中的 Exception 又能分为 Checked Exception (受检异常，必须处理) 和 Unchecked Exception (未受检异常，不必处理)。前者若发现则没办法通过编译，而 `RuntimeException` 及其子类都是不受检异常，常见的有
    - `NullPointerException` 空指针错误
    - `IllegalArgumentException` 参数错误
    - `NumberFormatException` 字符串转换为数字格式错误
    - `ArrayIndexOutOfBoundException` 数组越界错误
    - `ClassCastException` 类型转换错误
    - `ArithmeticException` 算术错误
    - `SecurityException` 安全错误，如权限不够
    - `UnsupportedOperationException` 不支持的操作错误
- Error 指程序本身无法处理的错误，比如 Java 虚拟机运行错误或 OOM、`NoClassFoundError` 等。这些异常发生时，Java 虚拟机一般会选择线程终止

Throwable 常用的方法有
|方法|描述|
|-|-|
|`String getMessage()`|返回异常发生时的详细信息|
|`String toString()`|返回异常发生时的简要描述|
|`String getLocalizedMessage()`|返回异常对象的本地化信息|
|`void printStackTrace()`|在控制台上打印 `Throwable` 对象封装的异常信息|

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

finally中的代码在 finally 前虚拟机被终止运行、程序所在线程死亡、关闭 CPU 这3种情况，finally 中的代码不会被执行。

面对必须要关闭的资源，我们应该优先使用 `try-with-resource` 而非 `try-finally`。Java 7 后提供了该语法糖以改造代码。

```java
try (BufferedInputStream bin = new BufferedInputStream(new FileInputStream(new File("test.txt")));
     BufferedOutputStream bout = new BufferedOutputStream(new FileOutputStream(new File("out.txt")))) {
    int b;
    while ((b = bin.read()) != -1) {
        bout.write(b);
    }
}
catch (IOException e) {
    e.printStackTrace();
}
```

## IO流

流的分类方式有很多种。可以按照其流动方向将其分为**输入流**和**输出流**；按照其数据单位分为处理音频、图像等二进制数据的**字节流**，和处理文本数据的**字符流**；按功能划分为与输入输出端相连的**节点流**，对已存在的流进行包装的**缓冲流**，进行线程间的数据传输的**管道流**。

![流的分类](stream.png)

当生产消费速度不匹配，数据写入速度大于读取/处理速度时（比如客户端发送数据过快，文件写入速度过快，控制台输入数据过多等），可能会导致缓冲区无法容纳更多数据而出现异常或数据丢失的问题。为了避免此类问题，可以合理设置缓冲区大小，或者控制写入的数据量，进行流量控制，或者使用 NIO 的非阻塞 IO。

字节流是由jvm将字节转换得到的，该过程比较耗时且容易出现乱码问题，因此IO流也提供了直接操作字符的字符流。在大文本中查找某个字符串时更推荐使用字符流，对视频文件通常使用字节流，并且尽量使用缓冲流来提高读写速度。

Java常见的IO模型有3种：BIO、NIO、AIO。
- **BIO** (Blocking IO)阻塞式 IO，使用字节流或字符流，线程在执行IO操作时被阻塞，无法执行其他任务。适用于连接数较少且固定的架构，如传统HTTP服务器。
- **NIO** (New IO 或 Non-Blocking IO)同步非阻塞 IO，使用多路复用器，轮询多个通道，只有就绪的通道才进行IO操作，线程在等待期间可以做其他事，通过轮询检查状态。使用于高并发场景，是目前的主流。
- **AIO** (Asynchronous IO)异步非阻塞 IO，使用回调函数或`Future`，操作完成后IO主动通知。线程发起请求后立即返回，完全不等。适用于连接数多且连接时间长（如大型文件读写，数据库连接池等）的场景。

### NIO

NIO 主要包括 Buffer、Cannel、Selector 3个部件

![示意图](channel-buffer-selector.png)

在 Java 1.4 的 NIO 库中，NIO 的读数据和写数据都在缓冲区进行操作。该 `buffer` 对象不能通过 `new` 调用构造方法创建对象，只能通过静态方法实例化。

Channel 是一个通道，建立了与数据源（如文件、网络套接字）之间的链接，可以利用它来读写数据。Channel 是全双工的。在读数据时，将 Channel 中的数据填充到 Buffer 中，而写操作时将 Buffer 数据写入到 Channel 中。

Selector，即选择器，是 NIO 中的一个关键组件，用于轮询注册在其上的 Channel，并在链接时轮询到就绪的 Channel 进行对应的 IO 操作。

### 序列化和反序列化

普通的对象要想转换成流，需要先进行**序列化**。序列化是指将对象转换为字节流的过程，而反序列化是将字节流转换回对象的过程。若希望将某个对象序列化，需要使用 `Serializable` 接口进行标记。

序列化是 Java 对象脱离 Java 运行环境的一种手段。序列化协议属于 [TCP/IP 协议](https://ivanclf.github.io/2025/11/13/networking/#TCP-IP-%E5%8D%8F%E8%AE%AE%E7%B0%87)中的应用层，因为这是应用程序特有的数据表示方式，不属于底层通信协议。

`serialVersionUID` 是Java序列化机制种用于标识类版本的唯一标识符，该标识符要求在序列化和反序列化中保持一致，用于在序列化和反序列化的过程中，类的版本是兼容的。该标识符可以自己设定，可以由 IDEA 自动生成，也可以交由 Java 自动生成。反序列化时会检查这个 UID 是否和当前类的 UID 一致，不一致则会抛异常 `InvalidClassException`。

Java 序列化不包含静态变量。这是因为序列化机制只保存对象的状态，而静态变量属于类的状态。也可以用 `transient` 关键字修饰不像想被序列化的变量。

{% note info %}
但 UID 不是已经被 static 变量修饰了吗？为什么还会被序列化？通常情况下，static 是属于类的，不属于任何一个对象单例，与序列化已保存对象的目的不同，因此不会被序列化。但这个 UID 的序列化做了特殊处理。关键在于，UID 不是作为对象状态的一部分被序列化的，而是被序列化本身用作一个特殊的“指纹”或“版本号”。
{% endnote %}

序列化一般包括以下3个过程：先实现 `Serializable` 接口，然后使用 `ObjectOutputStream` 来将对象写入，最后调用其中的 `writeObject()` 方法，将对象序列化后写入输出流中。序列化的数据一般以魔数和版本号 *`SerializableUID`* 开头。

序列化一般有3种方式：对象流序列化、json 序列化、protoBuff 序列化。一般使用的是 json 序列化，将对象转化为 byte 数组或 String 字符串。

JDK 自带的序列化，只需要实现 `java.io.Serializable` 接口即可。

{% note info %}
一般不会用 JDK 自带的序列化方式，一来自带的序列化方式其他语言可能不支持，二来是自带的序列化器性能更差，三来是存在安全问题，若输入的反序列化的数据可被用户控制，那么攻击者计科构造恶意输入，让反序列化产生非预期的对象。
{% endnote %}

可用的序列化包为 Kryo、Protobuf、ProtoStuff、Hessian 等。

## Socket套接字 与 RPC

Socket是网络通信的基础，表示两台设备间通信的一个端点，Socket通常用于建立TCP或UDP链接，实现进程间的网络通信。
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

## 泛型

常用的泛型通配符为 `?` `T` `K`/`V` `E`等。

Java的泛型是伪泛型，这是因为Java在编译期间，所有的类型信息都会被擦掉，也就是说，在运行的时候是没有泛型的。该特性主要是为了向下兼容，因为 jdk 5 之前是没有泛型的。

类似 `public static <E> void fun (E input)` 的结构一般被称为静态泛型方法。Java 中泛型只是一个占位符，必须在传递类型后才能使用，而类在实例化时才能真正的传递类型参数，由于静态方法的加载先于类的实例化，也就是说类中泛型还没有传递真正的类型参数，静态方法的加载就已经完成了，所以静态泛型方法是没有办法使用类上声明的泛型的，只能使用自己声明的 `<E>`。

## 注解

注解和注释不同，注解是一种特殊的注释，主要用于修饰类、方法或者变量，提供某些信息共程序在编译或者运行时使用。声明注解时，需要继承 `Annotation` 接口。

注解的生命周期有三大类，分别是：
- `RetentionPolicy.SOURCE`: 源码级别，给编译器用的，不会写入`class`文件。如`@Override`，Lombok的`@Getter`会在`class`文件中写入对应的`getter`，但注解本身不会保留。
- `RetentionPolicy.CLASS`: 会写入`class`文件，在类加载阶段丢弃。这是定义注解时的默认配置。如一些AOP框架或字节码增强库。
- `RetentionPolicy.RUNTIME`: 写入`class`文件，永久保存，并可以通过反射获取注解信息。如Spring框架中的`@Controller`等。

注解的解析方式有编译期直接扫描和运行期通过反射处理两种。

## 反射

反射允许Java在运行时检查和操作类的方法和字段。多用于Spring框架的加载和管理Bean和动态代理，例如 IoC，注解处理、AOP等。

Java程序的执行分为编译和运行两步。编译后会生成字节码文件，jvm进行类加载的时候，会加载这个字节码文件，将类型相关的所有信息加载进方法区，反射就是去获取这些信息。

{% note info %}
比如，基于反射分析类，然后拿到类/方法/参数上的注解。收到注解后再做进一步处理。
{% endnote %}

Class 类对象将一个类的方法、变量等信息告诉运行的程序。Java 提供了四种方式获取 Class 对象。

```java
// 知道具体类的情况下
Class class = TargetObject.class;
// 遍历包下面的类，通过 Class.forName() 传入类的全路径获取
Class class = Class.forName("com.example.TargetObject");
// 通过对象实例获取
Target o = new TargetObject();
Class class = o.getClass();
// 通过类加载器获取。该方法获取的 Class 不会初始化，静态代码块和静态对象也不会执行
ClassLoader.getSystemClassLoader.loadClass("com.example/TargetObject");
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

## 代理

一种设计模式，即用代理对象来代替对真实对象的访问。

### 静态代理

静态代理中，我们对目标对象的每个方法的增强都是手动完成的，在编译时已确定代理关系，需要手动编写代理类，代理类和目标类要实现相同的接口，一个代理类只能代理一个接口。

实现步骤为
1. 定义一个接口及其实现类
2. 创建一个代理类，同样实现这个接口
3. 将目标对象注入代理类，然后在代理类的对应方法中调用目标类中的对应方法。这样的话，我们就可以通过代理类屏蔽对目标对象的访问，并且可以在目标方法执行前后做一些自己想做的事情。

```java
// 接口定义
interface UserService {
    void save();
}

// 实现类，也是目标类
class UserServiceImpl implements UserService {
    public void save() {
        System.out.println("保存用户");
    }
}

// 静态代理类
class UserServiceProxy implements UserService {
    private UserService target;
    
    public UserServiceProxy(UserService target) {
        this.target = target;
    }
    
    public void save() {
        System.out.println("前置处理");
        target.save();  // 调用目标方法
        System.out.println("后置处理");
    }
}

// 使用
UserService proxy = new UserServiceProxy(new UserServiceImpl());
proxy.save();
```

### 动态代理

动态代理相比静态代理更加灵活，我们不需要针对每个目标类都单独创建一个代理类，也不需要我们必须实现接口。从 JVM 的角度来说，动态代理是在运行时动态生成字节码，并加载到 JVM 中的。

具体应用有 JDK 代理和 CGLib 代理两种，[主要应用于 AOP 中](https://ivanclf.github.io/2025/10/29/spring/#AOP)

## Unsafe

Unsafe 是位于 sun.misc 包下的一个类，主要提供一些执行低级别、不安全操作的方法，入直接访问内存、自主管理内存资源等，以提升 Java 运行效率。

Unsafe 提供的功能实现需要依赖本地方法。

Unsafe 中的方法是实现整个 JUC (Java.util.concurrent) 的基石。然而业务代码无法直接使用。普通代码想拿到它只能通过反射拿到单例字段。

在 JDK 9 后，模块系统开始强封禁，反射访问会警告。在 JDK 17+ 后默认进制打开，启动需要添加 `--add-opens` 参数。