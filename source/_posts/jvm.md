---
title: JVM的底层实现
date: 2025-10-06 00:39:06
tags: [java]
category: web
---

[参考文献](https://javabetter.cn/sidebar/sanfene/jvm.html)

JVM是Java实现跨平台的基石。Java源代码经编译后变成字节码文件，最后在运行时JVM会将字节码文件逐行解释，翻译成机器码指令，由此实现一次编译，处处运行的特性。并且，JVM还能实现自动管理内存和使用即时编译器JIT进行热点代码缓存的功能。

![JVM对源代码的处理过程](compile.png)

而JVM本身可以分成3部分：类加载器、运行时数据区和执行引擎

![JVM结构示例图](structure.png)

- 类加载器。负责从其他来源加载`.class`文件，将`.class`文件中的二进制数据读入到内存当中。
- 运行时数据区。JVM在运行Java程序时，需要从内存中分配空间来处理各种数据。
- 执行引擎。负责执行字节码，包括一个虚拟处理器、即时编译器JIT和垃圾回收器。