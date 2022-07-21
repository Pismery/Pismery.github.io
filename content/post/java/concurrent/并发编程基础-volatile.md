---
title: "并发编程基础 Volatile"
discriptions: "并发编程基础 Volatile"
date: 2019-01-09T20:53:07+08:00
author: Pismery Liu
archives: "2019"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---
<!--more-->

# voliatile 关键字

我们知道synchronized经过Java6的偏向锁、轻量级锁、锁消除、锁粗化等等优化性能得到了很大的提升，与Lock相差不大。但是依然还是会发生线程之间的上下文切换。而voliatile关键字则在保证了可见性和禁止指令重排序下，实现了一个比synchronized更加轻量级的操作。注意voliatile不保证原子性，典型例子就是i++操作。

## 实现原理

> 可见性实现

从Java内存模型可知每个线程都有一个工作内存，正常情况下若工作内存值存在变量值，则不会从主存中读取变量值。这就导致多线程运行的情况下，线程间操作共享变量不能即时的被其他线程感知，这就是不可见性。而volatile关键字通过以下两个操作解决了这类可见性问题。

1. 修改volatile变量需要立即从工作内存更新到主内存。
2. 读取volatile变量都需要从主内存中获取。
3. 通过内存屏障阻止指令重排序

> 禁止指令重排序

首先，先了解下Java中happen-before原则；若A happen-before B则表示A所做操作对B是可见的，注意是可见的，不是指时间上的前后。Java规定了以下几条happen-before原则;

- 同一个线程中的，前面的操作 happen-before 后续的操作。（即单线程内按代码顺序执行。但是，在不影响在单线程环境执行结果的前提下，编译器和处理器可以进行重排序，这是合法的。换句话说，这一是规则无法保证编译重排和指令重排）。
- 监视器上的解锁操作 happen-before 其后续的加锁操作。（Synchronized 规则）
- 对volatile变量的写操作 happen-before 后续的读操作。（volatile 规则）
- 线程的start() 方法 happen-before 该线程所有的后续操作。（线程启动规则）
- 线程所有的操作 happen-before 其他线程在该线程上调用 join 返回成功后的操作。
- 如果 a happen-before b，b happen-before c，则a happen-before c（传递性）。

为了实现volatile内存语义，JMM会对volatile变量限制编译器重排序和处理器重排序两种类型的重排序。下面是JMM针对volatile变量所规定的重排序规则表：

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190103volatile2.png)

若观察汇编指令(不是字节码)时会发现加入volatile关键字的属性会多出一个lock前缀指令，这个lock前缀指令其实就相当于一个内存屏障，内存屏障又叫内存栅栏，是一组实现对内存操作的顺序限制的处理器指令。下图是完成上述重排序规则所需要的内存屏障：

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190103volatile3.png)



## 参考链接

- [Java 并发编程：volatile的使用及其原理](http://www.cnblogs.com/paddix/p/5428507.html)
- [【死磕Java并发】—–深入分析volatile的实现原理](http://cmsblogs.com/?p=2092)