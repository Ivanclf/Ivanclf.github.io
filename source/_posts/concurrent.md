---
title: 并发基础 - 1
date: 2025-09-29 15:47:15
tags: [java]
category: web
---

[参考文献](https://javabetter.cn/sidebar/sanfene/javathread.html)

{% note success %}
并行与并发的区别在于，并行是同时执行多个任务的能力，并发是程序交替执行多个任务的能力。

在单核CPU上的多线程程序与js在浏览器中的异步操作为并发但不并行的操作，多核CPU上的Web服务器与分布式系统上的微服务即为既并发又并行的场景。
{% endnote %}

## 创建

线程的创建有三种方式。

第一种是重写父类Thread的`run()`方法，并且调用`start()`方法启动线程。

```java
class ThreadTask extends Thread {
    public void run() {
        // Task...
    }

    public static void main(String[] args) {
        ThreadTask task = new ThreadTask();
        task.start();
    }
}
```

该方法的缺点是如果`ThreadTask`已经继承了另外一个类，就不能再继承`Thread`类了。

第二种是实现`Runnable`接口的`run()`方法。并将实现类的对象作为参数传递给`Thread`对象的构造方法，最后调用`start()`方法启动线程。

```java
class RunnableTask implements Runnable {
    public void run() {
        // Task...
    }

    public static void main(String[] args) {
        RunnableTask task = new RunnableTask();
        Thread thread = new Thread(task);
        thread.start();
    }
}
```

第三种需要重写`Callable`接口的`call()`方法，然后创建`FutureTask`对象，参数为`Callable`实现类的对象，紧接着创建`Thread`对象，参数为`FutureTask`对象，然后调用`start()`方法启动线程。

```java
class CallableTask implements Callable<String> {
    public String call() {
        // Task...
    }

    public static void main(String[] args) throws ExecutionException, InterruptedException {
        CallableTask task = new CallableTask();
        FutureTask<String> futureTask = new FutureTask<>(task);
        Thread thread = new Thread(futureTask);
        thread.start();
        System.out.println(futureTask.get());
    }
}
```

该方法能获取线程的执行结果。

创建线程的时候，至少需要分配一个虚拟机线，在64位操作系统中，默认大小为1M，因此一个线程大约需要1M内存。当然，由于JVM、操作系统本身运行也需要内存，因此只给这么大的内存卡跑到理论值肯定是不够的。

{% note info %}
调用`start()`的时候会执行`run()`方法，那为什么不直接调用`run()`方法？因为`start()`方法是启动一个新的线程，然后让这个线程去执行`run()`方法。而`run()`方法本身只是在当前线程中调用的一个普通方法。
调用`start()`后，线程进入就绪状态，等待操作系统调度；一旦调度执行，线程会执行其`run()`方法中的代码。
{% endnote %}

## 调度

<table>
    <thead><tr><td>类别</td><td>方法</td><td>说明</td></tr></thead>
    <tbody>
        <tr><td rowspan="2">线程状态控制方法</td><td>start()</td><td>启动线程，使其进入就绪状态，等待CPU调度</td></tr>
        <tr><td>run()</td><td>线程执行体，定义线程要执行的任务逻辑</td></tr>
        <tr><td>线程休眠</td><td>sleep()</td><td>线程休眠，参数填毫秒级时间</td></tr>
        <tr><td rowspan="2">线程等待</td><td>wait()</td><td>必须在synchronized块中使用，<br>让当前线程进入WAITING或TIMED_WAITING状态，<br>需要被notify()或notifyAll()唤醒，<br>参数可指定毫秒级最长等待时间</td></tr>
        <tr><td>join()</td><td>让当前线程等待目标线程执行完毕，<br>参数可指定毫秒级等待时间</td></tr>
        <tr><td rowspan="2">线程唤醒</td><td>notify()</td><td>唤醒单个等待线程</td></tr>
        <tr><td>notifyAll()</td><td>唤醒所有等待线程</td></tr>
        <tr><td rowspan="4">线程让步与中断</td><td>yield()</td><td>线程让步，提示可让出CPU（但不保证立刻让出，<br>线程从RUNNING回到RUNNABLE状态</td></tr>
        <tr><td>interrupt()</td><td>中断线程</td></tr>
        <tr><td>isInterrupted()</td><td>检查中断状态</td></tr>
        <tr><td>interrupted()</td><td>检查并清除中断状态</td></tr>
        <tr><td rowspan="2">线程优先级</td><td>setPriority()</td><td>设置线程优先级，参数从1到10，<br>优先级只是建议，不保证执行顺序</td></tr>
        <tr><td>getPriority()</td><td>获取线程优先级</td></tr>
        <tr><td rowspan="2">守护线程</td><td>setDaemon()</td><td>设置守护线程，<br>当所有非守护线程结束时，JVM会自动退出，不管守护线程是否执行完毕，<br>参数为布尔值</td></tr>
        <tr><td>isDaemon()</td><td>检查是否为守护线程</td></tr>
    </tbody>
</table>

{% note info %}
当线程A调用共享对象的`wait()`方法时，线程A会被挂起，直到
- 线程B调用了共享对象的`notify()`方法或者`notifyAll()`方法；
- 其他线程调用线程A的 `interrupt()` 方法，导致线程A抛出 `InterruptedException` 异常。

`notify()`唤醒哪个正在`wait()`的线程是随机的。
{% endnote %}

{% note info %}
`interrupt()`方法能中断线程，但它只是改变中断状态，不会中断一个正在运行的线程，需要线程自行处理中断标志。若中断一个已经中断或正在等待的线程，就会抛异常。
{% endnote %}

{% note info %}
守护线程的作用大多是为其他线程提供服务。
{% endnote %}

{% note success %}
和[OS课](https://ivanclf.github.io/2025/05/14/os/)上的不大一样，Java中管理线程有6种状态

![6种状态变化](status.png)
{% endnote %}

{% note success %}
线程上下文切换是指CPU从一个线程切换到另一个线程执行的过程。而多核处理器的每个核心都可以独立执行一个或多个线程，可以让一些并发任务变成并行任务。
{% endnote %}

## 通信

上文中提到的`wait()`和`notify()`之间的互动就是一种线程通信方式。除此之外，还有许多种通信方式。

- 阻塞队列
    这是最常用的通信方式（毕竟用上消息队列就得上redis或者rabbit MQ了）。可以简单实现生产者消费者模式，也不用死记那两个锁的作用了。
    常用的示例有`ArrayBlockingQueue`、`LinkedBlockingQueue`、`PriorityBlockingQueue`等。
    ```java
    BlockingQueue<String> queue = new ArrayBlockingQueue<>(10);

    new Thread(() -> {
        try {
            String data = "message";
            queue.put(data);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }).start();

    new Thread(() -> {
        try {
            String data = queue.take();
            System.out.println("收到: " + data);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }).start();
    ```

- 信号量
    依旧是经典的信号量和PV操作。控制并发访问资源的线程数量。
    ```java
    Semaphore semaphore = new Semaphore(5); // 最大5个许可

    for (int i = 0; i < 10; i++) {
        new Thread(() -> {
            try {
                semaphore.acquire(); // 获取许可
                // 使用数据库连接
                System.out.println(Thread.currentThread().getName() + " 使用连接");
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                semaphore.release(); // 释放许可
            }
        }).start();
    }
    ```

    `Semaphore` 可以用于流量控制，比如数据库连接池、网络连接池等。假如有这样一个需求，要读取几万个文件的数据，因为都是 IO 密集型任务，我们可以启动几十个线程并发地读取。但是在读到内存后，需要存储到数据库，而数据库连接数是有限的，比如说只有 10 个，那我们就必须控制线程的数量，保证同时只有 10 个线程在使用数据库连接。这个时候，就可以使用 `Semaphore` 来做流量控制。

- Exchanger 交换器
    两个线程在同步点交换数据。一个线程调用`exchange()`方法时会阻塞，直到另一个线程也调用`exchange()`方法，然后两个线程交换数据后继续执行。
    ```java
    Exchanger<String> exchanger = new Exchanger<>();

    new Thread(() -> {
        try {
            String data = "来自线程1的数据";
            String response = exchanger.exchange(data);
            System.out.println("线程1收到: " + response);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }).start();

    new Thread(() -> {
        try {
            String data = "来自线程2的数据";
            String response = exchanger.exchange(data);
            System.out.println("线程2收到: " + response);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }).start();
    ```

    `Exchanger` 可以用于遗传算法，也可以用于校对工作，比如我们将纸制银行流水通过人工的方式录入到电子银行时，为了避免错误，可以录入两遍，然后通过 `Exchanger` 来校对两次录入的结果。

{% note success %}
多个线程可以通过`volatile`关键字和`synchronized`关键字来实现通信。`volatile`关键字确保变量的可见性，`synchronized`关键字确保线程之间的互斥访问。

`volatile`可以用于修饰成员变量，告知程序任何对该变量的访问均需要从共享内存中获取最新值，而不是从线程的本地缓存中获取。

`synchronized`关键字可以用于修饰方法或代码块，确保同一时刻只有一个线程可以访问被修饰的代码，从而避免数据竞争和不一致的问题。
{% endnote %}

{% note success %}
`CompletableFuture`类提供了一种更简洁和强大的方式来处理异步编程和线程间通信。它允许线程在完成计算后将结果传递给其他线程，并支持链式调用和组合多个异步任务。

```java
CompletableFuture.supplyAsync(() -> {
    try {
        Thread.sleep(1000);
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
    return "Hello";
}).thenApply(result -> {
    return result + " World";
}).thenAccept(finalResult -> {
    System.out.println(finalResult);
});
```
{% endnote %}

## 保证线程安全

Java中提供了许多方法来保证线程安全。

- 可以在代码块或方法上使用`synchronized`关键字。
- 使用`ReentrantLock`类来显式地加锁和解锁，这种锁还支持并发重入。
- 保证变量的可见性，可以使用`volatile`关键字修饰变量。
- 使用`Atomic`类（如`AtomicInteger`、`AtomicLong`等）
- 对于线程独立的数据，可以使用`ThreadLocal`类来存储和访问这些数据。
- 对于需要并发容器的地方，可以使用`ConcurrentHashMap`、`CopyOnWriteArrayList`等线程安全的集合类。

{% note success %}
一个`int`的变量为0，10个线程轮流对它进行`++`操作，循环一万次，结果会小于十万。原因是多线程环境下，`++`操作不是原子操作，可能会出现多个线程同时读取和写入变量的情况，导致数据丢失。
一般的`++`操作可以分解为三个步骤：
1. 读取变量的当前值
2. 对值进行加1操作
3. 将新的值写回变量
在多个线程并发进行`++`操作时，可能会出现以下情况：
- 线程A读取变量的值为0
- 线程B读取变量的值也为0
- 线程A对值进行加1操作，得到1
- 线程B对值进行加1操作，得到1
- 线程A将1写回变量
- 线程B将1写回变量
最终变量的值为1，而不是预期的2。因此最后需要通过某种方式保证`++`操作的原子性，比如使用`synchronized`关键字、`ReentrantLock`类或者`AtomicInteger`类。
{% endnote %}

{% note success %}
如果多个线程同时尝试创建实例，单例类必须确保只创建一个，并提供一个全局访问点。在多种实现单例类的方式中，饿汉式是一种比较直接的实现方式。

```java
public class Singleton {
    private static final Singleton instance = new Singleton();

    private Singleton() {}

    public static Singleton getInstance() {
        return instance;
    }
}
```

饿汉式单例则在第一次使用时初始化单例对象，这种方式需要使用双重检查锁定来确保线程安全。

```java
public class Singleton {
    private static volatile Singleton instance;

    private Singleton() {}

    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```
{% endnote %}

## ThreadLocal

`ThreadLocal`类提供了一种线程本地存储机制，使得每个线程都可以拥有自己的独立变量副本，避免了多线程环境下的共享变量带来的数据竞争和不一致问题。

对`ThreadLocal`的操作有4种方法：
1. `set(T value)`：设置当前线程的局部变量值。
2. `get()`：获取当前线程的局部变量值。
3. `remove()`：移除当前线程的局部变量值。
4. `initialValue()`：提供初始值的方式，子类可以重写该方法。

在Web应用中，可以使用`ThreadLocal`存储用户对话信息，这样每个线程在处理请求时都可以访问自己的用户信息，而不会影响其他线程。很多场景的cookie、session等信息都可以通过`ThreadLocal`来存储。

在数据库操作中，可以使用`ThreadLocal`存储数据库连接对象，确保每个线程使用自己的连接，避免连接冲突，以及避免多线程竞争下同一数据库链接的部分问题。

在`ThreadLocal`中，每个线程的访问的变量的副本都是独立的，避免了共享变量引起的线程安全问题。`ThreadLocal`可用于跨方法、跨类时间传递数据，避免了通过方法参数传递数据的繁琐。

当我们创建一个`ThreadLocal`变量时，实际上是为每个线程创建了一个独立的副本，这些副本存储在每个线程的`ThreadLocalMap`中。

`ThreadLocalMap`是`ThreadLocal`类的一个内部类，它是一个哈希表，用于存储每个线程的`ThreadLocal`变量及其对应的值。`ThreadLocalMap`的键是`ThreadLocal`对象，值是对应的变量值。键值对继承了弱引用的特性，当`ThreadLocal`对象不再被引用时，垃圾回收器可以回收它，从而避免内存泄漏。

{% note info %}
强引用与弱引用的区别详见jvm篇。
{% endnote %}

`ThreadLocalMap`的key是弱引用，但value是强引用，因此如果不手动调用`remove()`方法，value会一直存在，导致内存泄漏。因此需要在不需要使用`ThreadLocal`变量时，调用`remove()`方法来清除当前线程的局部变量值。`remove()`方法会调用`ThreadLocalMap`的`remove()`方法，删除当前线程的`ThreadLocal`变量及其对应的值。

将key设计成弱引用的好处是，jvm能够及时回收掉弱引用的对象。一旦key被回收，`ThreadLocalMap`在进行`set()`或`get()`操作时会发现key为null，然后会将该entry删除，从而避免内存泄漏。

{% note success %}
`ThreadLocal`也有许多改进方案：
- 在Netty中的`FastThreadLocal`，内部维护了一个索引常量`index`，每次创建`FastThreadLocal`中都会自动+1，用来取代hash冲突带来的损耗，用空间换时间。

- 而阿里的`TransmittableThreadLocal`，不仅实现了子线程可以继承父线程 `ThreadLocal`的功能，并且还可以跨线程池传递值。

{% endnote %}

`ThreadLocalMap`底层的数据结构是一个数组，也是一个简单的线性探测表。毕竟`ThreadLocalMap`设计的目的是存储线程私有数据，不会有大量的key，设计得太复杂没必要。
`ThreadLocalMap`并不会直接在元素数量达到阈值时立即扩容，而是首先清理掉那些key为null的entry，然后在填充率达到四分之三时扩容。扩容时，会将数组长度翻倍，并重新计算每个entry的位置，重新放入。

注意，父线程不能用`ThreadLocal`给子线程传值。子线程不会继承父线程的`ThreadLocalMap`，可以使用`InheritableThreadLocal`类来实现父线程向子线程传递`ThreadLocal`变量。因为子线程在创建的时候会拷贝父线程的`InheritableThreadLocalMap`，从而实现继承。

## Fork/Join

该框架主要用于分治算法的并行执行，可以将一个大任务拆分成多个小任务并行处理。其底层结构是个特殊的线程池——`ForkJoinPool`，且使用了工作窃取算法（一个线程执行完自己的任务后，可以窃取其他线程的任务，避免线程闲置）。