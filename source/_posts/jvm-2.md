---
title: JVM调优
date: 2025-10-10 09:27:24
tags: [java]
category: web
---

{% note primary %}
参考文献
- [https://javabetter.cn/sidebar/sanfene/jvm.html](https://javabetter.cn/sidebar/sanfene/jvm.html#_39-jvm-%E7%9A%84%E5%B8%B8%E8%A7%81%E5%8F%82%E6%95%B0%E9%85%8D%E7%BD%AE%E7%9F%A5%E9%81%93%E5%93%AA%E4%BA%9B)
- [https://javaguide.cn/java/jvm/jvm-parameters-intro.html](https://javaguide.cn/java/jvm/jvm-parameters-intro.html)

{% endnote %}

## 命令行工具
JDK命令行工具有
- `jmap` 生成堆存储快照
- `jps` 类似UNIX的`ps`，查看所有Java进程的相关信息
- `jstat` 收集HotSpot虚拟机各方面的运行数据
- `jinfo` 实时查看和调整虚拟机配置信息
- `jstack` 生成虚拟机此时的线程快照

jmap相关指令
|参数|使用场景|备注|
|-|-|-|
|`-heap <pid>`|查看堆内数据|了解堆配置、GC算法、各区域（如`Eden`, `Old Gen`）使用情况|
|`-histo <pid>`|查看对象统计信息|浏览堆中所有对象实例的数量和占用内存|
|`-histo:live <pid>`|查看存活对象统计|只统计存活对象，会触发`Full GC`|
|`-dump:format=b,file=文件名 <pid>`|生成堆存储|用于详细离线分析，会暂停应用|
|`-clstats <pid>`|查看类加载器信息|获取类加载器相关统计|
|`-finalizerinfo <pid>`|查看等待终结的对象|查看等待`finalize`方法的对象队列|

一般可以使用jmap[分析内存溢出或泄漏](#内存溢出和内存泄漏)。注意
- 谨慎使用 `-histo:live` 和 `-dump:live：`这两个命令都会触发`Full GC`
- 使用 `jmap` 需要具有目标Java进程的操作权限。

jps相关命令参数
|参数|说明|
|-|-|
|`-l`|输出主类全名和jar包路径|
|`-v`|输出启动时的JVM参数|
|`-m`|输出`main()`函数参数|

jstat相关命令
|参数|说明|
|-|-|
|`-class <vmid>`|显示类加载器的相关信息|
|`-compiler <vmid>`|显示JIT编译的相关信息|
|`-gc <vmid>`|显示GC相关的堆信息|
|`-gccapacity <vmid>`|显示各个代的容量及使用情况|
|`-gcnew <vmid>`|显示新生代信息|
|`-gcnewcapacity <vmid>`|显示新生代大小和使用情况|
|`-gcold <vmid>`|显示老年代（和永久代）的行为统计|
|`-gcoldcapacity <vmid>`|显示老年代的大小|
|`-gcutil <vmid>`|显示垃圾收集信息|

加上`-t`还能在输出信息后加`Timestamp`列，显示程序运行时间。

jinfo相关命令
|参数|说明|
|-|-|
|`<vmid>`|输出当前jvm进程的全部参数和系统属性|
|`-flag <name> <vmid>`|输出对应名称的参数的具体值，如`MaxHeapSize`等|
|`-flag [+/-]<name> <vmid>`|开启或关闭对应名称的参数|

## JVM参数

内存相关参数
|参数|描述|说明|
|-|-|-|
|`-Xms`|初始堆大小|`-Xms2g`表示初始堆大小为2g<br>一般与`-Xmx`保持一致，避免动态调整内存带来的损耗|
|`-Xmx`|最大堆大小|`-Xmx4g`表示堆最大为4g|
|`-Xmn`<br>`-XX:NewSize=<young size>[unit]`<br>`-XX:MaxNewSize=<young size>[unit]`|年轻代大小<br>初始年轻代大小<br>最大年轻代大小|一般是整个堆的3/8左右|
|`-XX:NewRatio=2`|老年代 : 年轻代的比例|默认是2，表示老年代 : 年轻代 = 2 : 1<br>与`-Xmn`冲突时以`-Xmn`为准|
|`-XX:SurvivorRatio=8`|`Eden`区和`Survivor`区的比例|`Eden` : `Survivor` = 8 : 1时，`Survivor`区占堆的1/10|
|`-XX:permsize`<br>`-XX:MetaspaceSize`|JDK 7前永久代的初始大小<br>JDK 7后`Metaspace`的初始大小|`Metaspace`的初始容量并不是这个设置，无论此处设置什么值，对于64位JVM，元空间的初始容量通常是一个固定的较小值(12-20Mb)|
|`-XX:MaxPermSize`<br>`-XX:MaxMetaspaceSize`|JDK 7前永久代的最大大小<br>JDK 7后`Metaspace`的最大大小|默认无上限|

垃圾收集相关参数
|参数|描述|说明|
|-|-|-|
|`-XX:+UseG1GC`|启用G1垃圾收集器|/|
|`-XX:+UseConMarkSweepGC`|启用CMS垃圾收集器|/|
|`-XX:+UseParallelGC`|启用`Parallel Scavenge` + `Parallel Old`<br>若只使用`Parallel Old`则参数为`-XX:+UseParallelOldGC`|
|`-XX:MaxPauseMillis`|期望的最大GC停顿时间|收集器会尽力达成这个目标|
|`-XX:GCTimeRatio`|吞吐量目标|计算吞吐量式子为$\frac{1}{1+\text{GCTimeRatio}}$|
|`-XX:InitiatingHeapOccupancyPercent`|触发并发GC周期的堆占用阈值|默认为45，即当堆占用率达到45%时，G1开始并发标记周期|
|`-Xloggc:<file>` `-XX:PrintGC`|将GC日志输出到文件<br>JDK 9后引入了统一的JVM日志框架`-Xlog`|/|
|`-XX:+PrintGCDetails`|打印详细的GC信息|提供包括各代容量、使用情况、耗时等详细信息|
|`-XX:+PrintGCTimeStamps`|打印GC发生的时间戳|从JVM启动开始计算的时间|
|`-XX:+PrintGCDateStamps`|打印GC发生的日期和时间|更常用|
|`-XX:+UseGCLogFileRotation`<br>`-XX:NumberOfGCLogFiles`<br>`-XX:GCLogFileSize`|开启GC日志滚动<br>滚动日志文件的数量，保留最近的多少个<br>设置每个日志文件的最大大小|避免单个日志文件过大，需要多个参数配合使用|

处理OOM，生成相关文件等
|参数|描述|
|-|-|
|`-XX:+HeapDumpOnOutOfMemoryError`|在发生OOM时生成转储文件|
|`-XX:HeapDumpPath=/path/to/heapdump/java_pid<pid>.hprof`|指定堆转储文件的输出路径|
|`-XX:OnOutOfMemoryError="<command> <args>"`|发生OOM时执行的命令|
|`-XX:+UseGCOverheadLimit`|在GC时间占比过高（默认98%）时抛出OOM|

一个JVM参数配置示例

```bash
java -server \
     -Xms4g -Xmx4g -Xmn2g \                    # 堆内存固定4G，年轻代2G
     -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m \ # 元空间固定256M
     -XX:+UseG1GC \                            # 使用G1收集器
     -XX:MaxGCPauseMillis=200 \                # 目标停顿200ms
     -XX:InitiatingHeapOccupancyPercent=45 \   # IHOP阈值45%
     -Xloggc:/app/logs/gc.log \                # GC日志路径
     -XX:+PrintGCDetails -XX:+PrintGCDateStamps \ # 打印详细GC信息和日期
     -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=10M \ # 日志滚动
     -XX:+HeapDumpOnOutOfMemoryError \         # OOM时生成Dump
     -XX:HeapDumpPath=/app/logs \              # Dump文件路径
     -Dfile.encoding=UTF-8 \                   # 系统属性：文件编码
     -Dspring.profiles.active=prod \           # 系统属性：Spring环境
     -jar my-application.jar
```

## 调优案例

[资料](https://javaguide.cn/java/jvm/jvm-in-action.html)

### 内存溢出和内存泄漏

在出现以下问题时则很可能发生了内存泄漏
- 应用响应越来越慢，频繁进行 `Full GC`。
- 通过监控系统（如 Prometheus + Grafana）发现 Java 堆内存使用率持续上升，且即使经过 `Full GC` 也无法回落到正常水平，呈现“锯齿状但整体向上”的趋势。
- 最终抛出 `java.lang.OutOfMemoryError: Java heap space` 错误。

排查内存泄漏的流程如下
{% note info %}
首先使用以下的监控工具进行监视

```bash
# 查看GC概况，1s打印一次，共打印10次
jstat -gcutil <pid> 1s 10
```

重点关注`OU`（老年代使用率）和`FU`（元空间使用率）。若发生了老年代内存泄漏，那么`OU`会持续增长，即使`Full GC`后也不下去。

然后获取内存快照(Heap Dump)。当确认存在内存泄漏嫌疑后，需要在内存占用量高的时候，生成堆转储文件，即一个时刻的Java堆内存快照。
生成Heap Dump有两种方法：
1. 一般使用命令行工具`jmap`。命令中，`live` 选项会触发一次 `Full GC`，只转储存活的对象。这能使快照更小，分析焦点更集中。如果不想要触发 GC，可以去掉 `live`。

```bash
# 在当前目录生成一个 heap.hprof 文件
jmap -dump:live,format=b,file=heap.hprof <pid>
```

2. 也可以加JVM启动参数。当JVM发生OOM时，会自动生成Heap Dump。

```bash
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/path/to/dump.hprof
```

接着分析这个巨大的二进制文件。一般可以使用`Eclipse Memory Analyzer Tool` (`MAT`)或`JVisualVM`分析。
{% endnote %}