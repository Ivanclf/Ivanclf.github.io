---
title: 高并发下的缓存策略 - 2
date: 2025-09-24 11:14:34
tags: [java]
category: web
---

## 超卖问题与一人一单

以下以优惠券（或者理解成门票也行）的抢购为例，列举并解决高并发下各种可能发生的情况。

优惠券的抢购规则如下：提供N张优惠券，在指定时间内可以进行抢购，一人只能抢一张，抢完为止。在一般的服务器中，该需求执行流程如下

1. 向数据库查询用户是否抢到过了，抢到过就报错。
2. 向数据库查询是否还有库存，没有就报错。
3. 没问题就返回成功信息。

```mermaid
sequenceDiagram
    participant t1 as Thread1
    participant t2 as Thread2
    participant t3 as Thread3

    t1->>t1: check storage, remain 1
    t2->>t2: check storage, remain 1
    t3->>t3: check storage, remain 1
    t1->>t1: return success, remain 0
    t2->>t2: return success, remain -1
    t3->>t3: return success, remain -2
```

可以发现，在高并发状态下，数据库中的一个数据可能同时会被多个线程同时访问，从而导致只有一个线程会读取到正确的数据，最后导致超卖问题。而如果使用正常的互斥锁，就会造成大量无用的性能消耗，严重拖慢响应速度，影响体验。

因此引入乐观锁的概念。普通的互斥锁可以视作悲观锁，因为这种锁假定线程安全问题一定发生。而乐观锁则认为线程安全问题不一定发生，只需要检查在修改数据前读取到的数据有没有发生更改。若发生了更改，说明有其他线程正在使用该关键区，则进行等待，反之则说明没有其他线程使用，可以放心修改数据。

一种比较经典的乐观锁方案叫做CAS(Compare and Swop)，它的工作原理与上文一样，通过直接比较需要更改的值前后两次读取的值是否一样。但单纯的CAS方案可能会引起ABA问题：另一个线程在两次读取期间，将关键区数据由A变成B再变成A，但此时本线程仍然认为没有改变，从而进行更改。作为改进，乐观锁通常使用单独的版本号替代关键区数据。

```mermaid
sequenceDiagram
    participant t1 as Thread1
    participant t2 as Thread2

    t1->>t1: storage: 1 version: 1
    t2->>t2: storage: 1 version: 1
    t1->>t1: storage > 0 & version = 1 ? success : failed
    t1->>t1: success, storage = 0, version = 2
    t2->>t2: storage > 0 & version = 1 ? success : failed
    t2->>t2: failed, storage = 0, version = 2
```

而在实际操作中，后一次version的判断往往在MySQL中进行，这样就保证了判断相等与改变数据的原子性——其实就是把应该原子化操作的部分扔给MySQL完成了。上图的示例演示了优惠券刚好减到0的状况，如果不是0，没抢到关键区的线程还需要再重试。

对于一人一单问题，如果单纯加一层判断，那么就可能出现和上面超卖问题中类似的问题

```mermaid
sequenceDiagram
    participant t1 as Thread1
    participant t2 as Thread2

    t1->>t1: count = 0? yes
    t2->>t2: count = 0? yes
    t1->>t1: count++, now count is 1
    t2->>t2: count++, now count is 2
```

因此也需要在修改的时候加锁。

## 分布式锁

对于存在多个后端服务器的场景，就容易出现自己jvm中线程的锁无法顾及另一个jvm的情况，因此需要将一些锁放到redis中，称为分布式锁。在redis中，有命令`setnx`来方便地设置类似锁的键值对。我们可以通过在Spring中操作`setnx`操作来获取锁，通过操作的返回值判断获取成功与否。若获取成功后再释放锁，则通过`del`操作解决。当然，为了解决死锁或其他问题，可以在`setnx`后添加`ex`属性，设置超时时间expire time。但是，分布式锁可能会存在一些问题。

### 误删锁

```mermaid
sequenceDiagram
    participant r as Redis Lock
    participant t1 as Thread1
    participant t2 as Thread2
    participant t3 as Thread3

    t1->>+r: get lock
    r->>+t1: ok
    note over t1: blocked for some reason
    r->>-r: TTL limit
    t2->>+r: get lock
    r->>+t2: ok
    t1->>-t1: stop being blocked
    t1->>+t1: now it begins to work
    t1->>-r: release lock
    r->>-r:lock released
    t3->>+r: get lock
    r->>+t3: ok
    t3->>-t3: now it begins to work
    t2->>-t2: working
    r->>-r: when does it release?
```

本不应该释放的锁却因为其他原因释放了，导致最后有两个线程在关键区域工作。因此，创建锁的时候要给这个锁创建一个标识（可以是UUID），释放锁的时候要先查看锁是不是自己创建的，若不是自己创建的则释放失败。

### 原子性操作

```mermaid
sequenceDiagram
    participant r as Redis Lock
    participant t1 as Thread1
    participant t2 as Thread2
    participant t3 as Thread3

    t1->>+r: get lock
    r->>+t1: ok
    note over t1: working
    t1->>-r: is it the lock I settle?
    r->>-t1: yes
    t1->>+t1: suddenly blocked
    note over t1: blocked
    t2->>+r: get lock
    r->>+t2: ok
    t1->>t1: start working
    note over t1: working
    t1->>-r: release lock
    r->>-r: lock released
    t3->>+r: get lock
    r->>+t3: ok
    t3->>-t3: it begins to work
    t2->>-t2: working
    r->>-r: when does it release?
```

当判断锁的表示与释放锁不在同一个原子操作时，就可能出现上述情况。因此需要保证判断和释放锁的操作为一个原子操作。而这个只能通过操作lua脚本实现。

{% note info %}
redis是用C语言写的，但也支持使用lua脚本语言执行批处理操作。在这个脚本中的操作redis保证实现原子性。
{% endnote %}

### 优化

目前，在Tomcat中，需要执行的步骤为

```mermaid
flowchart LR
    a[查询优惠券]-->b[判断秒杀库存]-->c[查询订单]-->d[校验一人一单]-->e[减库存]-->f[创建订单]
```

由于写的速度比读的速度慢很多，因此可以考虑将某些业务部署到redis中实行

```mermaid
flowchart LR
a[查询优惠券]
b[判断秒杀库存]
c[查询订单]
d[校验一人一单]
e[减库存]
f[创建订单]
    subgraph redis
    A[判断秒杀库存]-->B[校验一人一单]
    end
    B-->C[记录相关信息，存储到队列里]
    C-->|返回订单ID|D[用户]
    D-->|抢单|C
    subgraph tomcat
    a-->b-->c-->d-->e-->f
    end
    tomcat-...->|读取队列信息，并进行相关操作|C
```

因此需要把库存信息和已经拿到优惠券的用户存到redis里，原子性操作也能通过lua脚本统一写好。

但是目前还存在四个问题

1. 同一个线程无法多次获取同一把锁
2. 目前获取锁只尝试一次就返回false，没有重试机制
3. 若任务执行时间较长，会导致锁提前超时释放
4. 在多集群redis中，主从的同步存在一定的延迟。当主机宕机时，可能锁会出现问题

## Redisson

[redisson官方网址](https://redisson.pro/)

redisson在redis基础上提供了许多Java中许多分布式服务的实现，如各种分布式锁（可重入锁、公平锁、红锁、读写锁等等）。

### Redisson可重入锁原理

在redis中存入哈希类型，其中的`field`存储线程的标识、`value`部分存储重入的次数。

加锁时，首先判断锁是否存在。若不存在，则获取锁并添加线程标示，设置过期时间并执行业务。
若存在，则判断锁表示是不是自己的，若不是自己的则获取失败。
是自己的，就将锁的计数加1，并重新设置锁的有效期，执行业务。

解锁时，首先判断锁是不是自己的。若不是自己的，就说明锁已经释放过了，不用管了。
若是自己的，则将锁的计数减1，最后判断计数是否为0。若不为0，则说明还要用，重置锁有效期，执行业务。
若为0，说明已经用好了资源，可以释放锁了。

流程图如下

```mermaid
graph TD
    StartLock[开始加锁] --> CheckLockExist{锁是否存在?}
    
    CheckLockExist -->|不存在| AcquireLock[获取锁]
    AcquireLock --> SetThreadId[添加线程标识]
    SetThreadId --> SetExpire[设置过期时间]
    SetExpire --> LockSuccess[加锁成功]
    LockSuccess --> ExecuteBusiness[执行业务]
    
    CheckLockExist -->|存在| CheckOwner{锁标识是否自己的?}
    CheckOwner -->|不是| LockFail[获取锁失败]
    CheckOwner -->|是| IncreaseCount[锁计数加1]
    IncreaseCount --> ResetExpireLock[重置锁有效期]
    ResetExpireLock --> LockSuccess
    
    ExecuteBusiness --> StartUnlock[开始解锁]
    
    StartUnlock --> CheckOwnerUnlock{锁标识是否自己的?}
    CheckOwnerUnlock -->|不是| Ignore[无需处理]
    CheckOwnerUnlock -->|是| DecreaseCount[锁计数减1]
    
    DecreaseCount --> CheckCount{计数是否为0?}
    CheckCount -->|不为0| ResetExpireUnlock[重置锁有效期]
    CheckCount -->|为0| ReleaseLock[释放锁]
    
    ResetExpireUnlock --> UnlockSuccess[解锁完成]
    ReleaseLock --> UnlockSuccess
    Ignore --> UnlockSuccess
    
    UnlockSuccess --> End[结束]
```

### 锁重试与WatchDog机制

注意：若写明了释放锁的时间，则不会触发看门狗机制。

在redisson的`trylock()`方法中，在参数中设置等待时间（与释放锁时间）。在该方法运行时，除了获取等待时间，还需要获取当前时间与线程ID。若释放锁时间没有指定，则设为30秒。获取相关参数后开始尝试获取锁。尝试获取锁的操作与上文一致，即只有锁存在且不是自己的时候获取失败。若成功则返回`nil`。若获取锁失败，则返回锁的剩余有效期。后面执行判断，若剩余有效期为`null`则表示执行成功，返回`true`；反之则需要重试。

重试时，先用当前时间减去获取锁前获得的当前时间，再用等待时间减去这个时间差，获取剩下的等待时间。剩余等待时间小于0则结束。大于0则再次获取当前时间。然后，使用`subscribe()`方法，“订阅”锁释放的消息，在有锁释放的时候再启动，或者在大于剩余等待时间时取消订阅并返回`false`。而在成功等到时，再次获取剩余等待时间，时间有剩余时尝试获取锁。

若依然获取锁失败，则查看当前剩余时间，再次准备获取锁。但这次与上次不同，此次使用了信号量`getLatch()`方法，并且对剩余等待时间进行判定。取其他锁的剩余有效期与剩余等待时间的较小值作获取锁的等待时间。等好了再看看时间，若剩余等待时间不够了就返回`false`，足够则再重复该段操作。

获取锁成功后，为了保证业务先于锁释放执行完，需要运行额外的机制。若抛异常则直接释放。获取锁成功时（即剩余有效期为`null`），执行过期时间更新的方法。

该方法先往map中放入一个键值对（若不存在），键大致为锁的名称，值为一个独特的Entry对象。使用一个Entry获取插入的数据，若锁原先存在则为`null`，若不存在则为全新的Entry，以保证每一个锁拿到的是自己的Entry。原先存在时，只需要往Entry中放入ThreadId即可，等价为重入；原先不存在的情况下，除了要往Entry中放入ThreadId，还要更新有效时间。

在更新操作中，先拿到Entry，然后设置一个定时任务，在释放时间参数的1/3（没有指定时为10s）后拿出Entry与线程ID，然后更新有效期，最后再调用自己，从而不断更新。老线程中由于一直在执行这个操作，就不用另行执行时间更新的方法了。

而释放锁时，从map中拿出Entry，然后销毁线程ID，取消任务，最后销毁Entry本身，锁成功释放。

总之，可以归纳为以下流程

**加锁流程：**
1. 调用tryLock()时，若指定释放时间则禁用看门狗，否则设为30秒
2. 尝试获取锁：锁不存在或为自己所有则成功，否则失败返回剩余有效期
3. 获取失败时进行重试：计算剩余等待时间，订阅锁释放消息，使用信号量等待
4. 成功后在map中创建/更新Entry对象管理锁状态
5. 未指定释放时间时启动看门狗：每10秒自动续期，防止业务未完成锁过期

**解锁流程：**
1. 从map中获取Entry，移除线程ID
2. 取消看门狗定时任务
3. 销毁Entry，释放锁资源

{% note info %}
反反复复折腾有效期，为什么不直接不设置有效期呢？这个主要是防止服务器宕机时锁还没释放，导致服务器重启时发生各种问题。
{% endnote %}

总结此处上方获取可重入锁的机制，可以做出如下的流程图

```mermaid
graph TD
    Start[调用tryLock] --> CheckLeaseTime{是否指定释放时间?}
    
    CheckLeaseTime -->|是| DisableWatchdog[禁用看门狗机制]
    CheckLeaseTime -->|否| SetDefaultLease[设置默认30秒释放时间]
    
    DisableWatchdog --> TryAcquireLock
    SetDefaultLease --> TryAcquireLock
    
    subgraph 尝试获取锁
        TryAcquireLock{锁状态判断} -->|不存在| CreateLock[创建锁并设置线程ID]
        TryAcquireLock -->|存在且为自己| ReentrantLock[重入: 计数+1]
        TryAcquireLock -->|存在且为他人| ReturnTTL[返回剩余有效期]
        
        CreateLock --> SetExpireTime[设置过期时间]
        ReentrantLock --> ResetExpire[重置过期时间]
        SetExpireTime --> AcquireSuccess[获取成功]
        ResetExpire --> AcquireSuccess
    end
    
    ReturnTTL --> CheckWaitTime{剩余等待时间>0?}
    CheckWaitTime -->|否| ReturnFalse[返回false]
    CheckWaitTime -->|是| Subscribe[订阅锁释放消息]
    
    Subscribe --> WaitNotification[等待通知/超时]
    WaitNotification --> Retry[重新尝试获取锁]
    Retry --> TryAcquireLock
    
    AcquireSuccess --> InitWatchdog{是否禁用看门狗?}
    InitWatchdog -->|否| StartWatchdog[启动看门狗定时任务: 每10秒续期]
    InitWatchdog -->|是| SkipWatchdog[跳过看门狗初始化]
    
    StartWatchdog --> UpdateEntry
    SkipWatchdog --> UpdateEntry
    
    subgraph 锁状态管理
        UpdateEntry[创建/更新Map中的Entry] --> CheckExisting{Entry是否存在?}
        CheckExisting -->|否| CreateNewEntry[创建新Entry+线程ID]
        CheckExisting -->|是| UpdateExisting[更新现有Entry+线程ID]
        CreateNewEntry --> ScheduleRenewal[安排定时续期任务]
        UpdateExisting --> OnlyIncrement[仅增加重入计数]
    end
    
    ScheduleRenewal --> BusinessLogic[执行业务逻辑]
    OnlyIncrement --> BusinessLogic
    
    BusinessLogic --> UnlockProcess[开始解锁]
    
    subgraph 解锁过程
        UnlockProcess --> GetEntry[获取Map中的Entry]
        GetEntry --> RemoveThreadID[移除线程ID]
        RemoveThreadID --> CancelWatchdog[取消看门狗任务]
        CancelWatchdog --> DestroyEntry[销毁Entry]
        DestroyEntry --> ReleaseSuccess[锁释放成功]
    end
```

### 主从一致性

什么是redis主从呢？是设置多个redis节点，一个为主节点，其他的为从节点。主节点处理所有写操作，从节点处理所有读操作，主节点会不断把数据同步到从节点。若主节点宕机，则将一个从节点转化为主节点。但不同机子之间毕竟存在延迟，就可能存在不一致的问题。要是Java应用设置了锁，还没同步到从节点，主节点就宕机了，又应该如何解决呢？

redisson的解决方案比较暴力，就是将所有的redis节点都做读写，不做主从分别，主从设置在每一个节点直接做。换句话说，就是搞多个主从集群。Java应用设置锁则将所有节点加锁，反之亦然。这种多个锁的方法称为`multilock`（联锁）。
