---
title: Java 的集合类
date: 2025-09-28 20:52:13
tags: [java]
category: web
---
参考文献
- [https://javabetter.cn/sidebar/sanfene/collection.html](https://javabetter.cn/sidebar/sanfene/collection.html)
- [https://javaguide.cn/java/collection/java-collection-questions-01.html](https://javaguide.cn/java/collection/java-collection-questions-01.html)

在集合框架下，有两大种类

- 只存一种种类的Collection，是最基本的集合框架形式，下分3个分支
    - `List`：一个可包含重复元素的有序集合。实现类包括 `ArrayList`、`LinkedList` 等
    - `Set`：一个不包含重复元素的集合。实现类包括 `HashSet` 等
    - `Queue`：一个用于实现队列逻辑的集合。实现类包括 `PriorityQueue`、`ArrayDeque` 等

- 存键值对的Map，实现类包括`HashMap`、`TreeMap`等。可以使用 `.entrySet()` 方法获取其键值对的集合，从而遍历或进行其他操作。

Java在util包了还提供了一些常用的工具类

- `Collections`：提供了一些对集合进行排序、二分查找、同步的静态方法
- `Arrays`：提供了一些对数组进行排序、打印、和 `List` 进行转换的静态方法

`Collection` 接口直接继承了 `Iterable` 接口，这意味着所有实现了 `Collection` 接口的类都必须实现 `iterator()` 方法。因此可以使用增强型 `for` 循环来遍历集合中的元素。

{% note success %}
Iterator中的并发修改处理策略：
- **快速失败**机制会在检测到集合在迭代过程中被修改时，立刻抛出`ConcurrentModificationException`异常。其实现的原理与乐观锁类似。在集合内部维护一个修改计数器`modCount`。在创建迭代器时，迭代器会记录当前的计数器，每次调用迭代器相关方法时校验，若有改变则抛异常。
- **安全失败**机制在迭代时不会抛异常，即使在面对意外情况也能继续运行。最典型的原理即在迭代器被创建时会基于原集合创建一个副本，然后在这个副本中迭代。原集合的修改不会影响正在进行的迭代。但该方法不能保证实时一致性。可见于`CopyOnWriteArrayList`和`ConcurrentHashMap`。其中，`CopyOnWriteArrayList`在写时复制原数组生成新数组，加锁修改新数组，最后将原容器引用指向新数组。

{% endnote %}

## List

### ArrayList

可以将其看作是一个动态数组，在需要扩容时，会扩容数组容量，新数组的容量是原来的1.5倍，然后把**原数组的值拷贝到新数组中**。

```java
int newCapacity = oldCapacity + (oldCapacity >> 1);
```

ArrayList 在无参构造时，实际上初始化的是一个空数组。当真正对数组进行添加元素操作时，数组容量才开始扩大为10。

和 HashMap 不同，ArrayList 可以存储 null 值，但一般不建议这么做，这样可能会产生 NPE 或歧义。

为了不将数组中的空白元素也序列化，该集合类中的 `writeObject()` 方法被重写了，只序列化有效数据。

其头部插入/删除的时间复杂度为 $O(n)$，尾部插入、尾部插入/删除的时间复杂度为 $O(1)$。但是，当其通量到达极限，需要扩容时，需要执行一次 $O(n)$ 操作将原数组赋值到新的更大数组中，然后再插入。其指定位置插入、指定位置删除由于需要将其后的元素都向后/前移动一个位置，因此时间复杂度为 $O(n)$。

该集合类本身线程不安全，可以使用 `Collections.synchronizedList()` 方法返回一个线程安全的 `List`，即 `SynchronizedList` 。或者直接使用 `CopyOnWriteArrayList`。

`Vector` 是远古时期的非同步动态数组，所有方法前均使用 `synchronized` 进行同步，因此效率较低。

### LinkedList

该集合类继承了 `AbstractSequentialList` 并实现了 `Deque`，可以拿来当双端队列，或者栈，或者普通队列。但其本质还是一个双向链表。它和 ArrayList 都是线程不安全的。

### CopyOnWriteArrayList

`CopyOnWriteArrayList` 是 `ArrayList` 的线程安全版本。其内部使用 `volatile` 关键字修饰数组 `array`，确保多线程读操作的内存的可见性。

其缺点是写操作的时候会复制一份数组，开销较大，因此适合读多写少的场景。

该集合使用**写时复制**技术，在进行修改操作时，不会直接修改原数据，而是先创建底层数组的副本，对副本数组进行修改。修改完了再将原数组的指针指向修改后的数组赋值回去。

在进行写操作时，其内部使用了 `ReentrantLock` 独占锁实现同步，避免了多线程写时复制出多个副本出来，保证写操作的原子性。

## Set

{% note info %}
`Comparable` 和 `Comparator` 这两个接口都是 Java 中用于排序的接口，多用于自定义排序
- Comparable 接口出自 `java.lang` 包，内置 `compareTo(T obj)` 方法用来排序
- Comparator 接口出自 `java.util` 包，内置 `compare(T obj1, T obj2)` 方法用来排序

{% endnote %}

### HashSet

`HashSet`是由`HashMap`实现的，只不过值由一个固定的`Object`对象（`PRESENT`）填充，而键用于相关操作。该集合主要用于元素去重。`HashSet` 使用元素对象来计算 `hashCode` 值，同时结合 `equals()` 方法判断是否重复。

`HashSet` 的 `add()` 方法只是简单调用了 `HashMap` 中的 `put()` 方法，并且判断一下返回值以确保是否有重复元素。

## Queue

{% note info %}

|队列操作|抛异常方法|不抛异常方法|
|-|-|-|
|插入|`add()`|`offer()`|
|删除|`remove()`|`poll()`|
|元素检查|`element()`|`peek()`|

{% endnote %}

### PriorityQueue

优先队列中的元素按照自然顺序或 `Comparator` 排序，出队顺序按优先级。
- 其底层是基于堆实现的，默认是最小堆。其内部使用动态数组进行存储。
- 通过堆元素的上浮或下沉，实现在 $O(\log n)$ 的时间复杂度下插入元素或删除堆顶元素。
- 优先队列非线程安全，不允许 `null` 元素，迭代的顺序也并不稳定，当元素数量达到数组容量时，会自动扩容（容量小于64时翻倍，大于等于64时增长50%）。

{% note info %}

以下为一个自定义排序示例

```java
class Request {
    String requestId;
    int timestamp;
}

Queue<Request> tempQueue = new PriorityQueue<>((r1, r2) -> {
    return r1.timestamp - r2.timestamp;
});

// 若不想在优先队列处定义，则需要放置的类实现该接口。
class Request implements Comparable<Request> {
    String requestId;
    int timestamp;
    
    @Override
    public int compareTo(Request o) {
        return this.timestamp - o.timestamp; // *按 timestamp 升序排序*
    }
}
```
{% endnote %}

{% note info %}
完全二叉树除去最后一层外，其他层节点都是满的，最后一层的节点都靠左排列。

对于索引为 `i` 的节点，其父节点索引为 `(i - 1) / 2`，左子节点索引为 `2 * i + 1`，右子节点索引为 `2 * i + 2`。

在最小堆中，每个节点的值都小于等于其子节点的值。使用完全二叉树构建的堆，在插入元素时会将元素插入到末尾，删除时会删去堆顶元素并将最后一个元素替换堆顶。然后调整堆至正常状态。
{% endnote %}

### BlockingQueue

`BlockingQueue` （阻塞队列）是 JUC 包下的线程安全队列，支持阻塞式的“生产者-消费者”模型。该队列和实现
1. 阻塞队列数据为空时，所有的消费者线程被阻塞
2. 生产队列往队列中填充数据后，队列就会通知消息队列非空，消费者此时就可以进来消费
3. 当阻塞队列因为队列满而放不了新元素时，生产者就被阻塞

其实现类有很多

|实现类|数据结构|是否有界|特点|
|-|-|-|-|
|`ArrayBlockingQueue`|数组|有界|先进先出，基于数组，固定容量|
|`LinkedBlockingQueue`|链表|可选有界|先进先出，基于链表，默认容量为 `Integer.MAX_VALUE`|
|`PriorityBlockingQueue`|堆（优先队列）|无界|基于优先级排序，线程安全的 `PriorityQueue`|
|`DelayQueue`|堆（优先队列）|无界|基于优先级队列，元素按延迟时间排序，元素必须实现`Delayed` 接口|
|`SynchronousQueue`|无缓冲|无界|必须一对一交换数据，适用于高吞吐量场景|
|`LinkedTransferQueue`|链表|无界|基于链表，支持直接传输元素 `tryTransfer()`|

{% note info %}
**阻塞队列的同步机制**

阻塞队列通常使用 `ReentrantLock` 和 `Condition` 来实现线程安全和阻塞操作。不同的实现类采用不同的锁策略：
- `ArrayBlockingQueue`：使用单个 `ReentrantLock` 和两个 `Condition`（notEmpty、notFull），出队入队共用一把锁。
- `LinkedBlockingQueue`：使用两把分离的 `ReentrantLock`（putLock、takeLock）和对应的 Condition，实现入队和出队操作的完全并发。

{% endnote %}

#### ArrayBlockingQueue

该容器中，阻塞存取的方法为 `put` `take` 两种。非阻塞的存取方法为 `offer` `poll` 两种（不抛异常）和 `add` `remove` 两种（抛异常）。

若需要将队列中的结果全部存到列表中，进行批量操作，则使用 `drainTo` 方法。`offer` 和 `poll` 方法可以在参数中增加等待时间，用于在指定的超时时间内阻塞式添加和获取元素。

默认使用非公平锁，但也可在构造时指定为公平锁。
- 当队列已满时，生产者线程调用 `notFull.await()` 等待；
- 当队列为空时，消费者线程调用 `notEmpty.await()` 等待；
- 当新元素入队时，调用 `notEmpty.signal()` 唤醒消费者线程；
- 当元素出队时，调用 `notFull.signal()` 唤醒生产者线程。

#### LinkedBlockingQueue

**`ConcurrentLinkedQueue`** 是非阻塞的无界队列，使用 CAS 操作实现，与 `LinkedBlockingQueue` 的阻塞机制不同。

#### DelayQueue

该队列适用于基于时间的调度和缓存过期删除的场景。
- 元素必须实现 `Delayed` 接口，包含 `getDelay()` 方法
- 只有延迟时间到期（`getDelay() <= 0`）的元素才能被取出
- 典型应用：缓存过期删除、定时任务调度、会话超时管理等

## Map

{% note info %}
在 jdk 9 后，可以使用 `Map.of()` 方法往里面传入多个键值对，生成小型的不可变的小 map，最多支持 10 组键值对。
{% endnote %}

### HashMap

#### 数据结构

基于哈希表的键值对集合。JDK 8 起底层采用 “数组 + 链表 + 红黑树” 的混合结构。
- 数组作为链表或红黑树的头节点，可以通过索引快速定位到数组的某个位置（常被称为 Bucket）。
- 发生哈希冲突时，键值对会使用链表的形式存储。
- 当链表的长度大于8**且**数组的总长度大于64（若小于64则先扩容）时，则转换为红黑树。
- 树中的节点小于等于6时，红黑树会退化成链表。

`HashMap` 的核心参数：
- 初始容量：16，保证是 2 的幂。
- `loadFactor` / 负载因子：默认为0.75。
- 扩容阈值： `capacity * loadFactor`，扩容后的数组大小为原来的2倍，所有元素需重新计算哈希并迁移。

![示意图](hashmap1.png)

{% note info %}
红黑树是一种自平衡的二叉树，用于防止树退化为链表。

1. 每个节点要么是红色，要么是黑色
2. 根节点永远是黑色
3. 根节点下的 `null` 节点永远是黑色
4. 红色节点的子节点一定是黑色的
5. 从任意节点到其每个叶子节点的所有简单路基那个都包含相同数目的黑色节点

红黑树通过左旋和右旋来调整树的结构，避免某一侧过深。通过染色，保证树的高度不会失衡。
{% endnote %}

#### put 操作

其put操作较为复杂
1. 调用 `hash(key)` 方法计算键的哈希。
    将key的 `hashCode()` 的高16位和低16位异或。
        因为在数组容量较小的情况下，哈希与运算仅能用到低位。因此需要通过高低位异或让高位也参与运算，减少冲突。
2. 利用这个哈希值计算桶索引。
    计算方法为 `(n - 1) & hash`，由于 `n` 总是2的幂，因此这相当于与一串 1。
3. 若目标桶为空，则直接创建新节点放入；否则判断当前位置的第一个节点是否与新节点的key相同，相同则直接覆盖 value，不同则发生了哈希冲突。
4. 如果是链表，则将新节点追加到链表底部，若触发条件，就将链表转换为红黑树。
5. 每次插入新元素后都需要检查是否需要扩容，并且重新计算每个节点的索引，进行数组重新分布。

#### get 操作

get操作则相对简单
1. 通过哈希值定位索引
2. 定位桶
3. 检查第一个节点，看是否匹配
4. 若不匹配，则遍历链表或红黑树查找
5. 返回结果

#### 容量与扩容

`HashMap` 默认初始容量为16。在进行初始化时，若指定的容量不是2的幂，那么 `HashMap` 会进行向上取2次幂。提前指定一个较大的初始容量有利于减少因扩容导致的重哈希操作，但也有可能造成不必要的内存花销。

{% note info %}
为什么数组的长度必须是2的幂？
1. 高效计算数组下标，通过位运算 `(n - 1) & hash` 替代取模运算 `hash % n`。当数组长度为2的幂时，`n - 1` 的二进制表示为一串连续的1（例如16-1=15，二进制为1111），这使得 `&` 操作能够均匀地覆盖 `[0, n-1]` 的所有索引，且计算效率远高于取模运算。
2. 扩容时，每个元素的新位置要么是旧索引，要么是旧索引 + 旧容量，极大简化扩容操作。

{% endnote %}

`HashMap` 在扩容时，遍历哈希表中的元素，将其重新分配到新的哈希表中。
- 若只有一个元素，则直接通过 `(e.hash & (newCap - 1))` 计算
- 若当前桶是链表，则会进行 `(e.hash & oldCap) == 0` 判断是在旧索引还是旧索引 + 旧容量
- 若当前桶是红黑树，就会调用 `split()` 方法，同样进行上述的链表拆分逻辑

#### JDK 7 和 JDK 8 的区别

JDK 8 中对 HashMap 的实现进行了重大优化。

**数据结构**

JDK 7 仅用单向链表存储冲突元素。如果大量 key 都哈希到同一个桶中，其查询性能会退化到 $O(n)$。因此在 JDK 8 中，引入了[红黑树](#数据结构)以解决上述问题。

**插入方式**

- JDK 7 中使用头插法，因为“后插入的条目被访问的可能性更大”。然而，在多线程扩容时，头插法会反转链表顺序，可能形成循环链表，导致查询时死循环。
- 在 JDK 8 中，新插入的节点会放在链表的尾部，因此在扩容时，元素的相对顺序在链表上不会改变，这从根本上避免了多线程扩容时出现的死循环问题。

[具体可以看这个](https://www.bilibili.com/video/BV1n541177Ea)

**扩容机制**

JDK 7 中对每个节点使用 `e.hash & (newCap - 1)` 重新计算其在新数组中的下标。而在 JDK 8 中，由于扩容总是翻倍，因此新数组的 `newCap` 总是旧数组 `oldCap` 的两倍，算法简化为检查 `(e.hash & oldCap) == 0`，若等于0则原位置不变，否则位置变为 `index + oldCap`。

**hash 计算**

在 JDK 7 中计算方式为

```java
h ^= (h >>> 20) ^ (h >>> 12);
return h ^ (h >>> 7) ^ (h >>> 4);
```

而在 JDK 8 中简化了计算

```java
return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
```

扰动次数更少了。

#### 线程安全

HashMap 不是线程安全的。除了可能的环形链表问题，还有覆盖 `put` 问题
- 两个线程同时进行 put 操作，且发生了哈希冲突。线程1在哈希冲突判断后挂起
- 线程2再 put，完成操作
- 那么线程1由于已经执行过 hash 判断，因此会直接插入，导致线程2插入的数据被线程1覆盖了

`size` 计数错误问题
- 两个线程同时执行 put 操作，且均触发 `size++`
- 由于 s`ize++` 是非原子操作（读取 - 修改 - 写入），最终 `size` 仅增加 1，导致计数与实际元素数量不一致

### LinkedHashMap

`LinkedHashMap` 继承 `HashMap`，在其基础上新增双向链表维护键值对的顺序。

1. 遍历顺序：默认按**插入顺序**遍历；若构造时指定 `accessOrder = true`，则按**访问顺序**遍历（访问 / 修改的元素会移至链表尾部）。
2. LRU 实现：结合 `accessOrder = true` + 重写 `removeEldestEntry()` 方法（返回 true 时移除链表首元素），可快速实现简易 LRU 缓存。
3. 迭代效率：
    - `HashMap` 迭代器通过 `nextNode()` 方法遍历：需逐个检查哈希桶，找到非空节点后继续；
    - `LinkedHashMap` 迭代器直接通过双向链表的 `after` 指针定位后继节点，遍历效率更高（无需遍历空桶）。

### ConcurrentHashMap

`ConcurrentHashMap` 是 `HashMap` 的线程安全版本，并且是目前常用的版本。

在 JDK 7 中，`ConcurrentHashMap` 采用的是**分段锁**，整个 Map 会被分为若干段，每个段可以独立加锁。不同的线程可以同时操作不同段。为了减少锁的竞争，在 JDK 8 中，其底层结构和 `HashMap` 类似，改为使用 `CAS` 和 `synchronized` 关键字来保证线程安全，或者叫做“桶锁”。

其 `put` 操作流程如与 `HashMap` 相比
- 在插入新元素时，若发现桶为空，则使用 `CAS` 操作插入新节点，而不是直接插入。
- 若桶为空，且数组未初始化，则通过 `CAS` 操作初始化数组；若 `CAS` 操作失败，则自旋等待。
- 若桶不为空，则使用 `synchronized` 锁住桶的头节点，然后在桶内进行更新。
- 在`hash`的计算方式上，`ConcurrentHashMap` 的 `spread`方法会将`hashCode`的高16位与低16位进行异或运算，然后再与一个质数`0x7fffffff`进行与运算，确保哈希值为非负数，避免索引越界。
- `ConcurrentHashMap`在修改节点时，使用`volatile`关键字修饰节点的`value`字段与`next`指针，确保其他线程能看到最新的值。

其 `get` 操作与 `HashMap` 一致。

`ConcurrentHashMap` 可以保证多个线程同时进行读写操作时不会出现数据不一致的情况，但这不意味着它可以保证所有的复合操作（多个如 `put` `get` `containsKey` 等基本操作组成的操作）都是原子性的。若需要保证复合操作的原子性，则需要使用其提供的方法（如 `putIfAbsent` `computeIfAbsent` 等）。

## Stream流

该特性可以对包含一个或多个元素的集合做各种操作。操作分为两类
- 中间操作，可链式执行或惰性执行（惰性操作触发时才执行），如 `filter()`、`map()` 等。
- 终端操作，只能执行一次，触发中间操作执行并生成最终结果，如 `collect()`、`foreach()` 等。

Stream的创建有多种方式。
1. 从集合创建，如 `list.stream()`
2. 从数组创建，如 `Arrays.stream()`
3. 使用`Stream.of()`方法显式声明。
    ```java
    Stream<String> stream = Stream.of("a", "b", "c");
    ```
4. 使用lambda函数显式声明
    ```java
    Stream<Integer> infiniteStream = Stream.iterate(0, n -> n + 2); // 无限偶数流
    Stream<Double> randomStream = Stream.generate(Math::random); // 无限随机数流
    ```

## 注意事项

- 集合内部的判空使用 `isEmpty()` 方法，而非 `size() == 0`
    绝大部分集合的 `size()` 和 `isEmpty()` 方法复杂度都是 $O(1)$，但 JUC 包下的某些集合的 `size()` 和 `isEmpty()` 都是 $O(n)$ 操作，因为它们都需要遍历链表，防止有的节点 item 为 null。其中 `isEmpty()` 会调用 `first()` 方法，返回队列中的第一个非 null 节点。
    
    有的为 null 的原因是在并发环境下采用的标记删除机制：当节点被移除时，并不是立即物理删除，而是先将 item 置为 null 作为逻辑删除标记，后续由其他线程在适当时候完成实际的链表结构调整。
- 使用 `toMap()` 方法避免 value 为 null
    `toMap()` 方法底层调用了 `Map.merge()` 方法，而 `merge()` 方法会先调用 `Objects.requireNonNull()` 方法判断 value 是否非空，传入 `null` 则直接抛出 NPE。
- 禁止在 foreach 循环中直接 `remove/add` 集合元素
    foreach 底层依赖 Iterator，但直接调用集合的 `remove/add` 会破坏 Iterator 的并发修改检测机制，触发 `ConcurrentModificationException`。
- 可以使用 Set 来进行去重，避免使用 List 的 contains() 进行遍历去重
- 集合转数组必须使用 `toArray(T[] array)`，传入长度为 0 的空数组
    如 `Collection.toArray(new String[0])`，其中的 `new String[0]` 就是起一个模板的作用。
- 使用工具类 `Arrays.asList()` 把数组转换成集合时，不能使用其修改集合相关方法，它的 `add/remove/clear` 方法会抛出 UnsupportedOperationException 异常
    传入一个原生数据类型的数组时，该方法真正得到的参数就不是数组中的元素，而是数组对象本身，此时 `List` 的唯一元素就是这个数组。
