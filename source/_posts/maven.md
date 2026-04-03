---
title: maven的下载
date: 2024-05-15 21:51:09
tags: [碎片知识]
---

使用spring或者json进行相关配置的时候，需要先将其变成maven依赖的工程文件。以下是在IDEA编辑器将普通工程文件添加到maven依赖的方法。

## 下载与配置

[下载地址](https://maven.apache.org/download.cgi)

然后和往常一样，添加环境变量

![最后效果](maven_1.png)

### 在IDEA中创建maven项目

![在IDEA中创建maven项目](maven_2.png)

## 是什么

Maven 就是 Java 项目的包管理器, 用于管理依赖(jar 包), 统一项目结构, 并且帮编译, 打包, 运行. 在没有 Maven 前, 你得自己去官网一个个下 jar 包, 而一般的 Spring 工程中有巨多 jar 包, 因此一般需要 Maven 管理.

## 生命周期

1. `clean`
    删除 target 目录下的文件, 为重新编译做准备
2. `compile`
    编译代码
3. `test`
    运行单元测试
4. `package`
    打包成 jar/war
5. `install`
    安装到本地仓库, 供其他模块使用
6. `deploy`
    发布到远程仓库

## 插件

### `springboot: run`

如果直接通过 main 方法启动, 那么程序不会走 Maven 插件, 直接加载 classpath.

但使用 `mvn springboot:run` 时, 会通过 Maven 插件启动, 先触发 Maven 生命周期 (compile) 后再启动, 完全由 Maven 管理 classpath. 在启动时, Maven 中所有的 `<scope>provided</scope>` 和 `<optional>true</optional>` 也一并打进运行时, 因此适合在严格模拟打包环境, 检查 provided 依赖, 跑Maven 配置时适用.
