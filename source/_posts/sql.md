---
title: SQL基础
date: 2025-10-10 20:13:26
tags: [SQL, 数据库]
category: web
---

这部分主要涉及SQL语法及部分实现上的差别，暂不涉及太底层的内容。

参考文献：
- [https://javaguide.cn/database/sql/sql-syntax-summary.html](https://javaguide.cn/database/sql/sql-syntax-summary.html)
- [https://javabetter.cn/sidebar/sanfene/mysql.html](https://javabetter.cn/sidebar/sanfene/mysql.html)

{% note success %}
数据库范式有3种
- 第一范式：属性不可再分，确保表的每一列都是不可分割的基本数据单元
- 第二范式：第一范式的基础上，消除了非主属性对于码的部分函数依赖，即表中每一列都和主键直接相关
- 第三范式：第二范式的基础上，消除了非主属性对于码的传递函数依赖，即非主键列应该只依赖于主键列

{% endnote %}

{% note success %}
SQL和NoSQL有什么区别？
||SQL|NoSQL|
|-|-|-|
|数据存储类型|结构化存储，具有固定行和列的表格|非结构化存储。文档：JSON 文档，键值：键值对，宽列：包含行和动态列的表，图：节点和边|
|例子|Oracle、MySQL、Microsoft SQL Server、PostgreSQL|文档：MongoDB、CouchDB，<br>键值：Redis、DynamoDB，<br>宽列：Cassandra、 HBase，<br>图表：Neo4j、 Amazon Neptune、Giraph|
|ACID 属性|提供原子性、一致性、隔离性和持久性 (ACID) 属性|通常不支持 ACID 事务，为了可扩展、高性能进行了权衡，少部分支持比如 MongoDB |
|性能|性能通常取决于磁盘子系统。要获得最佳性能，通常需要优化查询、索引和表结构|性能通常由底层硬件集群大小、网络延迟以及调用应用程序来决定|
|扩展|垂直（使用性能更强大的服务器进行扩展）、读写分离、分库分表|横向（增加服务器的方式横向扩展，通常是基于分片机制）|

{% endnote %}

## 基本数据类型指北

- `varchar`和`char`的区别在于，`varchar`是可变长度的字符类型，最长不会超过声明的大小。原则上最多可以容纳65535个字符（但MySQL需要1到2个字节来表示字符串长度）。但`char`字段无论存储的字符长度是多少，都会占用声明的长度。
    不过，当`varchar`类型在指定大小较大时，会消耗更多的内存，因为`varchar`类型在内存中操作时，通常会分配固定大小的内存块来保存值。

- `blob`和`text`的区别在于，`blob`用于存储二进制数据，因此基本所有数据都能存，但存多媒体更好。然而市面上更多人会把文件存到OSS上，然后在数据库中存URL。而`text`用于存储文本数据，但目前`text`因为不能有默认值，检索效率较低等缺点，目前也不常用。

- `datetime`和`timestamp`的区别在于，一个直接放日期和时间的完整值，和时区无关，占8个字节；而另一个放时间戳，占4个字节，实际开发更常用。

- `null`和`''`是两个不同的值，一个表示值未确定，而另一个表示空字符串。
    任何值和`null`进行比较的结果都是`null`。
    要判断一个值是不是`null`，必须使用`is null`或`is not null`。
    大多数聚合函数会忽略`null`值。

- 若需要包含有 null 的数据，需要加上 `is null` 进行筛选，否则不会选到。

- MySQL中没有专门的布尔类型，一般使用`tinyint(1)`表示布尔值。

## 关键字指北

![提到数据库基础就必须要放的join图](join.jpg)

- `left join` 在遇到没有的数据时会置 null，而 `inner join` 在遇到没有的数据会不合并。最后查询时，前者会返回 null，后者不返回结果。

- `drop`，`delete`，`truncate`的区别在于，`drop`直接把整个表删除掉，`truncate`只是清空表中的数据而不改变表的结构，同时自增id也重新开始，`delete`删除某一行的数据，不加`where`字句时和`truncate`类似，不改变表的结构。同时，`truncate`和`drop`直接对整张表进行操作，因此原数据不能回滚，也不会触发trigger。

- `in`和`exists`的区别在于，在使用`in`时，MySQL会首先执行子查询，然后将结果集用于外部查询的条件，适用于结果集较小的情况；`exists`会对外部查询的每一行执行一次子查询，若子查询返回任何行则`exists`条件为真，适用于结果集可能很大的情况。
    还有，`in`可能会受到null值陷的影响，产生意外结果，而`exists`完全不受影响。

- `union`，`union all`，`join`的区别在于，`union`和`union all`都是垂直合并，用于合并多个`select`语句的结果集，但前者会自动去重，后者不去重，而`join`为列合并，基于某个条件将多个表的列组合到一起。

- `like`操作符用于确定字符串是否匹配模式，支持两个通配符选项：`%`和`_`
    `%`表示任何字符出现任意次数
    `_`表示任何字符出现一次

- 事务管理不对`select`操作生效，不能回退`create`和`drop`语句。

- 使用`start transaction`开启事务，`commit`提交事务，`savepoint`创建保留点，`rollback to`用于回滚到某个保留点（没有设置则回滚到`start transaction`）。

- `where`用于过滤指定行，后面不跟聚合函数，放`group by`前；`having`用于过滤分组，一般和`group by`连用。

- 约束条件可以在创建表(`create table`)时约定，也可以在表创建后更新(`alter table`)。常用的约束条件有
    |类型|说明|
    |-|-|
    |`not null`|存不了`null`值|
    |`unique`|每行必须有唯一值|
    |`primary key`|`not null` + `unique`，主键|
    |`foreign key`|外键|
    |`check`|保证列中的值符合指定条件|
    |`default`|默认值|

- `explain`可以用于普通crud语句，显示其执行查询的计划。以下是其中的一些输出列。
    |参数|说明|
    |-|-|
    |`id`|查询的标识符。如果是复杂查询（如子查询或UNION），数字大的先执行，数字相同的从上到下执行|
    |`select_type`|查询类型常见的有<br>`simple` 简单查询<br>`primary` 最外层的查询<br> `subquery` 子查询中的第一个`select`<br>`derived` 派生表（`from`字句里的子查询）<br>`union` `union`中的第二个或后面的`select`|
    |`table`|当前行访问的是哪个表|
    |`partitions`|匹配的分区|
    |`type`|连接类型或访问类型。是衡量查询效率的关键指标<br>从好到坏大致是<br>`system`>`count`>`eq_ref`>`ref`>`range`>`index`>`all`<br>达到`const` `eq_ref` `ref`的推荐情况；范围查询下，使用`range`也可以接受。如果是`all`，则需要进行优化|
    |`possible_keys`|查询可能使用的索引|
    |`key`|查询实际使用的索引，`null`为没有使用索引|
    |`key_len`|使用索引的长度，越短越好|
    |`ref`|显示索引的哪一列被使用了|
    |`extra`|包含不适合放其他列的额外信息。包括<br>`using index` 使用了覆盖索引<br>`using where` 在存储引擎检索行后进行了过滤<br>`using temporary` 需要创建临时表来处理查询，这通常需要优化<br>`using filesort` 需要额外的排序操作，通常需要优化|

## 函数

MySQL常用函数如下

|函数|说明|函数|说明|
|-|-|-|-|
|`left()` `right()`|左边或右边的字符|`lower()` `upper()`|转换为小写或大写|
|`ltrim()` `rtrim()` `trim()`|去掉左边或右边或两边的空格|`concat()`|链接多个字符串|
|`length()`|长度，以字节为单位|`round()`|返回小数的四舍五入值|
|`if()`|若条件为真，返回一个值，否则返回另一个值|`case`|根据一系列条件返回值|

以下都以MySQL的函数为例。

- `count(<constance>)`和`count(*)`之间没什么差别，`count(<col>)`只统计列中非`null`值数据。

- `char_length()` 用于计算字符串的字符数，`length()` 用于计算字符串的字节数

- 常见的计算时间函数有
    |函数|说明|
    |-|-|
    |`curdate()`|当前日期|
    |`now()`|当前日期和时间|
    |`to_days`|返回从 0000 年到现在的天数|
    |`date_add` `date_sub`|加减天数，参数1为目前时间，参数二可以为 `interval <num> hour/day/month/...`|
    |`datediff` `timestampdiff`|计算时间差，前者只计算日期，后者计算两个时间点<br>后者的第一个参数为 `day/hour/second/...`，后两个参数为需要计算的两个时间|
    |`date`|提取日期部分|
    |`last_day`|获取指定日期所在月的最后一天|

- `nullif()` 函数使用两个参数，比较两个表达式的值，若两表达式相等则返回 null，否则返回第一个表达式

- `ifnull()` 函数使用两个参数，若第一个参数为 null 则返回第二个参数的值，否则返回第一个参数的值

- `coalesce()` 函数返回参数列表中第一个非 null 的值，若全为 null 则返回 null