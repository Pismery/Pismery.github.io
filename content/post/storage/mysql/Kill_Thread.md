---
title: "「MySQL 45 讲」- Kill 命令"
discriptions: "「MySQL 45 讲」- Kill 命令"
date: 2020-09-14T22:05:33+08:00
author: Pismery Liu
archives: "2020"
tags: [MySQL,极客时间笔记]
categories: []
showtoc: true
---

本文为 「极客时间- MySQL 实战 45 讲」 学习笔记；记录内容主要为了加深理解；

本篇主要讲解 kill 命令的执行流程与原理；

<!--more-->

# MySQL kill 线程

## 概要

日常开发过程中，当发现 SQL 执行时间过长，或者进入锁等待，我们通常执行以下两个 kill 命令终止 SQL 操作；

```SQL
kill query [thread_id]
kill connection [thread_id] (connection 可缺省)
```

但我们会发现 kill 命令有时会快执行完毕，有时又需要很长时间，甚至一直无法关闭；下面我们看看，MySQL 中 kill 命令是如何实现终止操作的；

## 执行原理

在 MySQL 中，一个语句的执行过程进行了多处埋点，目的是为了判断线程状态，如果发现线程状态为「THD::KILL_QUERY」或「KILL_CONNECTION」 则进入语句终止逻辑；语句的终止逻辑中包含以下操作：

- 释放锁；
- 回滚数据版本；
- 回收语句产生的临时文件：如大查询生成的临时文件，DDL 过程中的临时文件；

当用户执行 kill query thread_id 时，MySQL 处理 kill 命令的线程做了以下两件事情：

1. 将 thread_id 的运行状态改成 「THD::KILL_QUERY」;
2. 发送一个唤醒信号给 thread_id;

发送唤醒信号，目的是避免线程 thread_id 处于阻塞状态，无法执行到 MySQL 的埋点判断线程状态，进入终止逻辑；

例如下图，session B 被 session A 阻塞住，若 kill 线程没有发送唤醒信号，session B 将无法执行至埋点处；（ps: 图片来自「极客时间- MySQL 实战 45 讲」）

![](https://gitee.com/pismery/imageshack/raw/master/img/20200914211919.png)

而当用户执行 kill connection thread_id 时，其实就是将客户端的连接断开，后续执行流程走 kill query 的流程；不同的是线程运行状态改为 「KILL_CONNECTION」; (ps:命令「show processlist」遇到线程处于「KILL_CONNECTION」状态时，会将 Command 列显示为 Killed)


## 问题解答

> 为什么 kill 命令会迟迟无法执行完毕

首先，MySQL 不能直接将线程杀死，原因是执行 SQL 的过程中，线程持有了锁资源，也有可能生成了临时文件和中间数据版本；MySQL 需要先回滚操作，再杀死线程；

从 kill 执行原理，kill 命令执行时间长，一般有两个原因：

1. MySQL 无法及时进入埋点处，进行线程状态判断；
2. MySQL 终止逻辑耗时较长；

无法及时进入埋点处，常见以下两种情况：

- 一般是由于 IO 压力过多，读写 IO 的函数迟迟不返回；
- InnoDB 的线程连接数用尽，被 kill 线程接收到唤醒信号，却无法进入 InnoDB 引擎，从而无法执行到埋点处；（ps:线程循环等待进入 InnoDB 过程中没有埋点)

MySQL 终止逻辑耗时长，常见以下情况：

- 超大事务执行期间被 kill。这时候，回滚操作需要对事务执行期间生成的所有新数据版本做回收操作，耗时很长。
- 大查询回滚。如果查询过程中生成了比较大的临时文件，加上此时文件系统压力大，删除临时文件可能需要等待 IO 资源，导致耗时较长。
- DDL 命令执行到最后阶段，如果被 kill，需要删除中间过程的临时文件，也可能受 IO 资源影响耗时较久。

> 当 kill 操作迟迟无法执行完成，能否通过重启服务

答案是重启服务无法解决 kill 操作执行问题，重启后仍旧需要继续执行 kill 的终止逻辑；只能通过调整系统参数加快 kill 命令执行；

> 如果直接在客户端通过 Ctrl+C 命令，是不是就可以直接终止线程呢？

不可以，Ctrl+C 命令是另外启动一个连接，发送 kill query 命令；所以 Ctrl+C 只是断开客户端与 MySQL 服务端的连接；服务端还需要执行终止逻辑；