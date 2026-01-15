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
    - `Queue`：一个用于保持元素队列的集合。实现类包括 `PriorityQueue`、`ArrayDeque` 等

- 存键值对的Map，实现类包括`HashMap`、`TreeMap`等

Java在util包了还提供了一些常用的工具类

- `Collections`：提供了一些对集合进行排序、二分查找、同步的静态方法
- `Arrays`：提供了一些对数组进行排序、打印、和 `List` 进行转换的静态方法

`Collection`继承了`Iterable`接口，这意味着所有实现了`Collection`接口的类都必须实现`iterator()`方法。因此可以使用增强型`for`来遍历集合中的元素。

{% note success %}
Iterator中的并发修改处理策略：
- **快速失败**机制会在检测到集合在迭代过程中被修改时，立刻抛出`ConcurrentModificationException`异常。其实现的原理与乐观锁非常类似。在集合内部维护一个修改计数器`modCount`。在创建迭代器时，迭代器会记录当前的计数器，每次调用迭代器相关方法时，迭代器都会检测这个计数器的值有没有发生改变。若有改变则抛异常。

- **安全失败**机制在迭代时不会抛异常，即使在面对意外情况也能继续运行。最典型的原理即在迭代器被创建时会基于原集合创建一个副本，然后在这个副本中迭代。原集合的修改不会影响正在进行的迭代。但该方法的一致性不强。可见于`CopyOnWriteArrayList`和`ConcurrentHashMap`。其中，`CopyOnWriteArrayList`在写时会将原数组复制一份，加锁写，然后将原容器的引用引向新容器。

{% endnote %}

## List

### ArrayList

可以将其看作是一个动态数组，在需要扩容时，会扩容数组容量，新数组的容量是原来的1.5倍，然后把原数组的值拷贝到新数组中。

```java
int newCapacity = oldCapacity + (oldCapacity >> 1);
```

ArrayList 在无参构造时，实际上初始化的是一个空数组。当真正对数组进行添加元素操作时，数组容量才开始扩大为10。

和 HashMap 不同，ArrayList 可以存储 null 值，但一般不建议这么做。

为了不将数组中的空白元素也序列化，该集合类中的 `writeObject()` 方法被重写了，只序列化有效数据。

其头部插入、头部删除的时间复杂度为 $O(n)$，尾部插入、尾部删除的时间复杂度为 $O(1)$。但是，当其通量到达极限，需要扩容时，需要执行一次 $O(n)$ 操作将原数组赋值到新的更大数组中，然后再插入。其指定位置插入、指定位置删除由于需要将其后的元素都向后/前移动一个位置，因此时间复杂度为 $O(n)$。

该集合类本身线程不安全，可以使用 `Collections.synchronizedList()` 方法返回一个线程安全的 `List`，即 `SynchronizedList` 。或者直接使用 `CopyOnWriteArrayList`。

`Vector` 是远古时期的非同步动态数组，在所有的方法前都使用 `synchronized` 关键字进行同步，因此效率较低。

### LinkedList

该集合类继承了 `AbstractSequentialList` 并实现了 `Deque`，可以拿来当双端队列。但其本质还是一个双向链表。

它和 ArrayList 都是线程不安全的。它在 JDK 1.6 前为循环链表，JDK 1.7 取消了循环，变成了双向链表。

### CopyOnWriteArrayList

`CopyOnWriteArrayList` 是 `ArrayList` 的线程安全版本。其内部使用 `volatile` 关键字修饰数组 `array`，确保读操作的内存的可见性。

其缺点是写操作的时候会复制一份数组，开销较大，因此适合读多写少的场景。

该集合使用写时复制技术，在进行修改操作时，不会直接修改原数据，而是先创建底层数组的副本，对副本数组进行修改。修改完了再将修改后的数组赋值回去。

在进行写操作时，其内部使用了 ReentrantLock 加锁，保证了同步，避免了多线程写时复制出多个副本出来。

## Set

{% note info %}
`Comparable` 和 `Comparator` 这两个接口都是 Java 中用于排序的接口，多用于自定义排序
- Comparable 接口出自 `java.lang` 包，内置 `compareTo(Object obj)` 方法用来排序
- Comparator 接口出自 `java.util` 包，内置 `compare(Object obj1, Object obj2)` 方法用来排序

{% endnote %}

### HashSet

`HashSet`是由`HashMap`实现的，只不过值由一个固定的`Object`对象填充，而键用于相关操作。该集合主要用于去重。

`HashSet` 使用成员对象来计算 `hashCode` 值。

`HashSet` 的 `add()` 方法只是简单调用了 `HashMap` 中的 `put()` 方法，并且判断一下返回值以确保是否有重复元素。在 JDK 8 中，实际上无论 `HashSet` 中是否存在了某元素，`HashSet` 都会直接插入，只是在 `add()` 方法中返回是否会存在相同的元素。

## Queue

{% note info %}

|队列操作|抛异常方法|不抛异常方法|
|-|-|-|
|插入|`add`|`offer`|
|删除|`remove()`|`poll()`|
|元素检查|`element()`|`peek()`|

{% endnote %}

### PriorityQueue

优先队列中的元素按照自然顺序或 `Comparator` 排序，出队顺序按优先级。
- 其底层是基于堆实现的，默认是最小堆。其内部使用动态数组进行存储。
- 通过堆元素的上浮或下沉，实现在 $O(\log n)$ 的时间复杂度下插入元素或删除堆顶元素。
- 优先队列非线程安全，不允许 `null` 元素，迭代的顺序也并不稳定，当元素数量达到数组容量时，会自动扩容（容量小于64时翻倍，大于等于64时增长50%）。

{% note info %}

以下为一个示例

```java
class Request {
    String request_id;
    int timestamp;
}

Queue<Request> tempQueue = new PriorityQueue<>((r1, r2) -> {
    return r1.timestamp - r2.timestamp;
});
```

如果不想在优先队列处定义，则需要 `Request` 类中继承接口。

{% endnote %}

{% note info %}
完全二叉数除去最后一层外，其他层节点都是满的，最后一层的节点都靠左排列。对于索引为 `i` 的节点，其父节点索引为 `(i - 1) / 2`，左子节点索引为 `2 * i + 1`，右子节点索引为 `2 * i + 2`。在最小堆中，每个节点的值都小于等于其子节点的值。使用完全二叉树构建的堆，在插入元素时会将元素插入到末尾，删除时会删去堆顶元素并将最后一个元素替换堆顶。然后调整堆至正常状态。
{% endnote %}

### BlockingQueue

`BlockingQueue` （阻塞队列）是 JUC 包下的一个线程安全队列，支持阻塞式的“生产者-消费者”模型。该队列和实现
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

阻塞队列通常使用 ReentrantLock 和 Condition 来实现线程安全和阻塞操作。不同的实现类采用不同的锁策略：
- `ArrayBlockingQueue`：使用单个 ReentrantLock 和两个 Condition（notEmpty、notFull）。
- `LinkedBlockingQueue`：使用两个分离的 ReentrantLock（putLock、takeLock）和对应的 Condition，实现入队和出队操作的完全并发。

{% endnote %}

#### ArrayBlockingQueue

该容器中，阻塞存取的方法为 `put` `take` 两种。非阻塞的存取方法为 `offer` `poll` 两种（不抛异常）和 `add` `remove` 两种（抛异常）。若需要将队列中的结果全部存到列表中，进行批量操作，则使用 `drainTo` 方法。

`offer` 和 `poll` 方法可以在参数中增加等待时间，用于在指定的超时时间内阻塞式添加和获取元素。

默认使用非公平锁，但也可在构造时指定为公平锁。当队列已满时，生产者线程调用 `notFull.await()` 等待；当队列为空时，消费者线程调用 `notEmpty.await()` 等待；当新元素入队时，调用 `notEmpty.signal()` 唤醒消费者线程；当元素出队时，调用 `notFull.signal()` 唤醒生产者线程。

#### LinkedBlockingQueue

该容器中的队列基于链表实现，且不像 ArrayBlockingQueue 中的锁只有一把，此处的的锁是分离的，即生产用的是 `putLock`，消费是 `takeLock`，以防生产者和消费者线程之间的锁争夺。

**`ConcurrentLinkedQueue`** 是非阻塞的无界队列，使用 CAS 操作实现，与 `LinkedBlockingQueue` 的阻塞机制不同。

#### DelayQueue

该队列适用于基于时间的调度和缓存过期删除的场景。
- 元素必须实现 `Delayed` 接口，包含 `getDelay()` 方法
- 只有延迟时间到期（`getDelay() <= 0`）的元素才能被取出
- 典型应用：缓存过期删除、定时任务调度、会话超时管理等

## Map

### HashMap

#### 数据结构

基于哈希表的键值对集合。JDK 8 中该集合类的数据结构为数组 + 链表 + 红黑树。数组作为链表或红黑树的头节点，可以通过索引快速定位到数组的某个位置（常被称为 Bucket）。发生哈希冲突时，键值对会使用链表的形式存储。当链表的长度大于8**且**数组的总长度大于64（若小于64则先扩容）时，则转换为红黑树。在删除操作时，当树中的节点小于等于6时，红黑树会退化成链表。

`HashMap` 的初始容量为16，扩容的阈值为 `capacity * loadFactor`，其中的 `loadFactor` 是负载因子，默认为0.75。扩容后的数组大小为原来的2倍，然后把原来的元素重新计算哈希值，放到新的数组中。

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

![示意图](hashmap2.jpg)

1. 调用 `hash(key)` 方法计算键的哈希。
    将key的 `hashCode` 的高16位和低16位进行异或运算。这是因为，在 `n` （数组容量） 较小的情况下，其高位都是0。由于与运算的特性，哈希的高位也相当于截取低位了。因此需要通过高低位异或让高位也参与运算之中，添加哈希值的随机性，从而减少哈希冲突。
2. 利用这个哈希值计算桶索引并检查是否为空。
    计算方法为 `(n - 1) & hash`，由于 `n` 总是2的幂，因此这相当于与一串 1。
3. 若目标桶为空，则直接创建新节点放入；否则判断当前位置的第一个节点是否与新节点的key相同，相同则直接覆盖 value，不同则发生了哈希冲突。
4. 如果是链表，则将新节点添加到链表底部，若触发条件，就将链表转换为红黑树。
5. 每次插入新元素后都需要检查是否需要扩容，并且重新计算每个节点的索引，进行数组重新分布。

#### get 操作

get操作则相对简单

![示意图](hashmap3.png)

1. 通过哈希值定位索引
2. 定位桶
3. 检查第一个节点，看是否匹配
4. 若不匹配，则遍历链表或红黑树查找
5. 返回结果

#### 容量与扩容

`HashMap` 默认初始容量为16。在进行初始化时，若指定的容量不是2的幂，那么 `HashMap` 会进行向上取2次幂。

提前指定一个较大的初始容量有利于减少因扩容导致的重哈希操作，但也有可能造成不必要的内存花销。

{% note info %}
为什么数组的长度必须是2的幂？
1. 高效计算数组下标，通过位运算 `(n - 1) & hash` 替代取模运算 `hash % n`。当数组长度为2的幂时，`n - 1` 的二进制表示为一串连续的1（例如16-1=15，二进制为1111），这使得 `&` 操作能够均匀地覆盖 `[0, n-1]` 的所有索引，且计算效率远高于取模运算。
2. 扩容时，每个元素的新位置要么是旧索引，要么是旧索引 + 旧容量，极大简化扩容操作。

{% endnote %}

`HashMap` 在扩容时，遍历哈希表中的元素，将其重新分配到新的哈希表中。
- 若只有一个元素，则直接通过 `(e.hash & (newCap - 1))` 计算
- 若当前桶是链表，则会进行 `(e.hash & oldCap) == 0` 判断是在旧索引还是旧索引 + 旧容量
- 若当前桶是共给叔，就会调用 `split()` 方法，同样进行上述的链表拆分逻辑

要实现一个 `HashMap`，整体思路为

1. 实现一个hash函数，对键的HashMap进行扰动
2. 实现拉链法解决哈希冲突
3. 扩容后，重新计算哈希值，将元素放到新数组中

#### JDK 7 和 JDK 8 的区别

JDK 8 中对 HashMap 的实现进行了重大优化。

**数据结构**

JDK 7 在发生哈希冲突时，HashMap 会将所有冲突的键值对连接成一个单向链表。在极端情况下，如果大量 key 都哈希到同一个桶中，其查询性能会退化到 $O(n)$，效率极低。因此在 JDK 8 中，引入了[红黑树](#数据结构)以解决上述问题。

**插入方式**

JDK 7 中使用头插法，因为“后插入的条目被访问的可能性更大”。然而，在多线程环境下进行扩容时，头插法会改变链表中元素的顺序，可能导致两个线程在操作链表时形成循环链表。后续有线程在对该桶进行查询时，就会陷入死循环。在 JDK 8 中，新插入的节点会放在链表的尾部，因此在扩容时，元素的相对顺序在链表上不会改变，这从根本上避免了多线程扩容时出现的死循环问题。

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


还有一种情况是同时 put 操作导致的 size 值不正确，即两个线程同时执行了 put 操作，但 size 的值却只增加了1。

### Hashtable

`HashMap` 不是线程安全的，早期的 JDK 版本中可以使用 `Hashtable` 保证线程安全。也可以使用 `Collections.synchronizedMap` 方法返回一个线程安全的 Map。

`HashMap` 可以存储一个 null 键和多个 null 值。而 `Hashtable` 不允许有 null 的键或值，否则抛异常。

创建时若不指定容量初始值，`Hashtable` 的默认初始大小为11，然后每次扩充的容量为原来的 $2n+1$；而 `HashMap` 默认的初始化大小为16，此后每次扩充的容量大小为原来的2倍。

创建时若指定了容量初始值，`Hashtable` 会直接使用指定的大小，而 `HashMap` 会将其扩充为2的幂次方大小。

`Hashtable` 没有动态转换（链表转化为红黑树）的机制，也没有将哈希值进行高低位混合扰动处理以减少冲突的机制。

### LinkedHashMap

`LinkedHashMap` 在 `HashMap` 的基础上增加了一个双向链表来保持键值对的插入顺序。

因此，在对它进行遍历时，其顺序是一开始插入时候的顺序。并且它还可以定义排序模式 `accessOrder`，为 true 时则为访问顺序，访问到的元素将会移动到链表末端。

通常可以使用该结构，并配合 `accessOrder` 为 true，重写 `removeEldestEntry` 方法告知是否需要移除链表首元素，实现一个简单的 LRU。

在 HashMap 中，其迭代器在迭代键值对时会使用 `nextNode` 方法，该方法会返回 next 指向的下一个元素，并会从 next 开始遍历 bucket 找到下一个 bucket 中不为空的元素 Node。相比之下 LinkedHashMap 中的迭代器直接使用通过 `after` 指针快速定位到当前节点的后继节点，简洁高效许多。

### TreeMap

`TreeMap` 通过key比较器决定元素的排序，若没有指定比较器，那么key必须实现 `Comparable` 接口。其底层是红黑树。因此相比 `HashMap`，`TreeMap` 主要多了对集合中元素根据键排序的能力，以及对集合内元素搜索的能力。

其与 `HashMap` 区别在于，`TreeMap` 一开始就是通过红黑树实现的，不像 `HashMap` 那样按需选择。 `TreeMap` 在进行 `put` 操作的时候，会先判断根节点是否为空，如果为空，则直接插入到根节点。若不为空，则通过key的比较器判断元素应该插入到左子树还是右子树。


### ConcurrentHashMap

`ConcurrentHashMap` 是 `HashMap` 的线程安全版本，并且是目前常用的版本。

#### JDK 7

在 JDK 7 中，`ConcurrentHashMap` 采用的是分段锁，整个 Map 会被分为若干段，每个段可以独立加锁。不同的线程可以同时操作不同段。

在分段锁结构中，整个 Map 会被分为若干段，每个段可以独立加锁，每个段都是一个独立的哈希表，称为 `HashEntry`。默认情况下，`ConcurrentHashMap` 有16个段，每个段的初始容量为2，负载因子为0.75。

注意，整个 Map 的 Segment 数组在创建后就是固定大小的，无法扩容。扩容指的是单个 Segment 内部的 `HashEntry` 进行扩容。

每个 Segment 还维护了一个 `ReentrantLock` 锁对象，或者说，由于 Segment 继承了 ReentrantLock，其 Segment 本身就是一个可重入锁。

此时的 `put` 流程与 `HashMap` 类似，只不过是先定位段，再通过 `ReentrantLock` 加锁，然后在段内进行`put` 操作。
get 操作则不需要加锁，直接定位段，然后在段内进行 `get` 操作。因为 value 字段和 next 指针都是 `volatile` 的，所以可以保证可见性。

![JDK7中的put流程](concurrenthashmap1.png)

#### JDK 8

为了减少锁的竞争，在JDK 8中，`ConcurrentHashMap` 摒弃了分段锁，其底层结构和 `HashMap` 类似，改为使用 `CAS` 和 `synchronized` 关键字来保证线程安全，或者叫做“桶锁”。

其 `put` 操作流程如下

![JDK 8 中的 put 流程](concurrenthashmap2.jpg)

与 `HashMap` 相比
- 将链表转换为红黑树的阈值没有变化，仍然是8
- 在插入新元素时，若发现桶为空，则使用 `CAS` 操作插入新节点，而不是直接插入
- 若桶为空，且数组未初始化，则使用 `CAS` 操作初始化数组；若 `CAS` 操作失败，则让出 CPU 并自选等待
- 若桶不为空，则使用 `synchronized` 锁住桶的头节点，然后在桶内进行更新
- 在`hash`的计算方式上，`ConcurrentHashMap` 的 `spread`方法会将`hashCode`的高16位与低16位进行异或运算，然后再与一个质数`0x7fffffff`进行与运算，确保哈希值为非负数
- `ConcurrentHashMap`在修改节点时，使用`volatile`关键字修饰节点的`value`字段与`next`指针，确保其他线程能看到最新的值

其 `get` 操作也是通过 `key` 中的 `hash` 定位，若桶为空则返回 `null`，若第一个节点匹配则返回，若不匹配则遍历链表或红黑树查找。

相比 `Hashtable`，`ConcurrentHashMap` 效率更高，因为 `Hashtable` 在每个方法上都使用 `synchronized` 关键字进行同步，导致线程竞争激烈时性能较差。而 `ConcurrentHashMap` 通过分段锁或桶锁的方式，允许多个线程同时访问不同的段或桶，从而提高了并发性能。

`ConcurrentHashMap` 可以保证多个线程同时进行读写操作时不会出现数据不一致的情况，但这不意味着它可以保证所有的复合操作（多个如 `put` `get` `containsKey` 等基本操作组成的操作）都是原子性的。若需要保证复合操作的原子性，则需要使用其提供的方法（如 `putIfAbsent` `computeIfAbsent` 等）。

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

## 注意事项

- 集合内部的判空使用 `isEmpty()` 方法，而非 `size() == 0`
    绝大部分集合的 `size()` 和 `isEmpty()` 方法复杂度都是 $O(1)$，但 JUC 包下的某些集合的 `size()` 和 `isEmpty()` 都是 $O(n)$ 操作，因为它们都需要遍历链表，防止有的节点 item 为 null。其中 `isEmpty()` 会调用 `first()` 方法，返回队列中的第一个非 null 节点。
    
    有的为 null 的原因是在并发环境下采用的标记删除机制：当节点被移除时，并不是立即物理删除，而是先将 item 置为 null 作为逻辑删除标记，后续由其他线程在适当时候完成实际的链表结构调整。

    此外，在 `ConcurrentHashMap` 1.7 中，`size()` 方法需要统计每个 Segment 的数量，而 `isEmpty()` 只需要找到第一个不为空的 Segment 即可，因此后者时间复杂度更低。
- 使用 `toMap()` 方法转为 Map 集合时，要注意当 value 为 null 时的 NullPointException
    `toMap()` 方法内部调用了 Map 接口的 `merge()` 方法，而 `merge()` 方法会先调用 `Objects.requireNonNull` 方法判断 value 是否为空。
- 不要在 foreach 循环中进行元素的 `remove/add` 操作。需要 remove 元素时，使用 Iterator 方式。并发操作下需要对 Iterator 加锁
    因为 foreach 语法底层其实还是依赖 Iterator，但 `remove/add` 操作直接调用的是集合的方法而非 Iterator 的，这就导致 Iterator 莫名其妙发现自己有元素被 `remove/add`，然后就会抛异常。除了直接使用 Iterator 进行遍历外，还可以使用普通的 for 循环，或使用 JUC 包下安全失败的集合类。
- 可以使用 Set 来进行去重，避免使用 List 的 contains() 进行遍历去重
- 集合转数组必须使用集合的 `toArray(T[] array)`，传入的是类型完全一致、长度为0的空数组
    如 `Collection.toArray(new String[0])`，其中的 `new String[0]` 就是起一个模板的作用。
- 使用工具类 `Arrays.asList()` 把数组转换成集合时，不能使用其修改集合相关方法，它的 `add/remove/clear` 方法会抛出 UnsupportedOperationException 异常
    传入一个原生数据类型的数组时，该方法真正得到的参数就不是数组中的元素，而是数组对象本身，此时 `List` 的唯一元素就是这个数组。
