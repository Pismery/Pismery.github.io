---
title: "并发编程基础-synchronized"
discriptions: "并发编程基础-synchronized"
date: 2018-12-20T21:46:37+08:00
author: Pismery Liu
archives: "2018"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---
<!--more-->

# synchronized

## synchronized三种使用方式

1. 修饰实例方法，表示对当前类的实例加锁，若要访问此方法需要获取当前实例的对象锁。
2. 修饰静态方法，表示对当前类加锁，若要访问此方法需要获取当前类锁。
3. 修饰代码快，指定加锁对象，访问同步代码快需要获取指定对象的锁。
    - synchronized(this)，表示指定当前实例为锁对象，类似于修饰示例方法
    - sychronized(class)，表示对指定类加锁，类似修饰静态方法。只是可以指定其他类(一般不这么使用)。

> 示例

```
public class SynchronizedDemo {

    private final Object lock = new Object();
    private static final Object LOCK = new Object();

    //对象锁
    public synchronized void method1() {
            ...
    }

    //类锁
    public static synchronized void method2() {
            ...
    }

    //对象锁
    public void method3() {
        synchronized (lock) {
            ...
        }
    }


    //类锁
    public void method4() {
        synchronized (LOCK) {
            ...
        }
    }

    //类锁
    public void method5() {
        synchronized (SynchronizedDemo.class) {
            ...
        }
    }

}
```

> 注意事项：

1. 当线程获取到类锁时，其他线程可以访问需要获取对象锁或者非同步方法。即需要的锁不同，线程间不会互相阻塞。
2. 不要使用synchronized(String a),因为字符串常量具有缓冲功能，容易导致阻塞其他地方
3. 修饰指定加锁的对象，对象最好使用final关键字修饰，避免其他方法对加锁对象重新赋值，导致需要获取的不是同一个对象的锁，使得线程间不会相互阻塞。

## synchronized底层原理

synchronized底层原理是JVM层面的，所以需要查看字节码才能看到相关信息，最终的代码实现是由C语言写的。下面看看synchronized两种应用情况。

> 修饰同步语句块情况

```
public class SynchronizedDemo {
	public void method() {
		synchronized (this) {
			System.out.println("synchronized 代码块");
		}
	}
}
```

通过javac命令将SynchronizedDemo编译成class文件，在通过命令javap -c -s -v -l SynchronizedDemo.class 查看字节码信息，如下图

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20181220_synchronizedDemo.png)

从字节码可以看出，synchronized修饰同步代码块是通过monitorenter和monitoeexit两个命令，执行monitorenter目的是获取目标对象的monitor,monitor是对象头部的一个标志数值。当标志数值为0时表示没有其他线程使用，线程获取monitor,并将数值自增。synchronized是可重入锁，因此当遇到嵌套的monitorenter判断持有线程是不是当前线程，若是则对象头部monitor数值再自增。当获取不到monitor时，线程会阻塞在这里，直到另外的线程释放锁。当执行monitoeexit，则数值自减直到为0表示释放了锁。

> 修饰方法的情况

```
public class SynchronizedDemo2 {
	public synchronized void method() {
		System.out.println("synchronized 方法");
	}
}
```

字节码信息如下图

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20181220_synchornizedDemo2.png)

从字节码可以看出，synchronized修饰方法是通过ACC_SYNCHRONIZED标识，表示该方法是一个同步方法，JVM通过该标识识别同步方法，从而执行相应的同步调用。


### JDK1.6 优化内容

在JDK1.6之前，synchronized使用的是重量级锁，即通过monitor实现，而monitor又是依赖操作系统的Mutex lock实现的，导致线程的切换就需要从用户态切换系统态，这样的转换需要较高的代价，这就是为什么JDK1.6之前synchronized效率低下的原因。JDK1.6对synchronized在JVM层面进行了大量的优化，引进了偏向锁，轻量级锁，锁消除(Lock Elimination)、锁粗化(Lock Coarsening)，适应性自旋(Adaptive Spinning)。

锁的状态分为:无锁，偏向锁，轻量级锁，重量级锁；随着锁的竞争，锁会从偏向锁到轻量级锁再到重量级锁方向逐渐升级，注意锁升级是单向的，即锁不会出现降级现象。

> 偏向锁

引入偏向锁和轻量级锁目的都是为了当没有多线程竞争情况下，减少传统的重量级锁使用操作系统的互斥量（即Monitor）导致的性能消耗。而轻量级锁的获取与释放需要依赖多次CAS指令，偏向锁只需要在置换ThreadID的时候依赖一次CAS原子指令。

当只有一个线程访问同步代码块线程,则不需要触发同步，此时为对象加一个偏向锁。若出现线程竞争的情况，当到达全局安全点(safepoint)，获取到偏向锁的线程会被阻塞，然后将偏向锁升级为轻量级锁，线程继续运行。注意到达全局安全点后偏向锁升级，这个过程会导致stop the world。

因此，当有锁竞争的情况下，偏向锁会导致额外的很多代价操作，所以确认有锁竞争的情况下要禁用偏向锁。

```
## 开启偏向锁
-XX:+UseBiasedLocking -XX:BiasedLockingStartupDelay=0
## 关闭偏向锁
-XX:-UseBiasedLocking
```


> 轻量级锁

首先声明，轻量级锁不是用来替代重量级锁的，它的本意是在没有多线程竞争的前提下，减少传统的重量级锁使用产生的性能消耗。轻量级锁适用的场景是多个线程交替执行同步方法或同步代码块。若同一时间多线程竞争同一个锁，则锁升级为重量级锁。


> 锁消除(Lock Elimination)

锁消除指当编译器编译时，检测到共享变量不可能发生竞争，则执行锁消除，避免无谓的获取锁操作。

> 锁粗化(Lock Coarsening)

锁粗化指当编译器编译时，发现一系列连续的操作重复的对同一个对象加锁解锁，则进行锁粗化，避免带来不必要的消耗

> 适应性自旋(Adaptive Spinning)

首先先讲自旋，自旋是轻量级锁失败后，为了避免线程真实地在操作系统层面挂起，进行的一项称为自旋的优化手段。

有时候线程1获取锁失败时，其实很快线程2就释放锁了，若不使用自旋，则线程一需要挂起线程再恢复线程(挂起恢复线程需要在内核态执行，而用户态转换内核态需要较高的代价)，这就得不偿失了。因此，引入自旋操作，线程1不挂起，不断重复的去获取锁。

JDK1.6之前自旋已经实现了，只是默认不开启，通过启动参数--XX:+UseSpinning开启。JDK1.6后就变成默认开启了。需要注意自旋操作并不能取代阻塞操作，自旋操作需要一直占用Cpu时间片资源，当有一个线程持有时间过长，这就出现cpu资源被大量耗费了。因此自旋操作需要限制尝试次数，默认次数是10次，可通过启动参数--XX:PreBlockSpin来更改。

适应性自旋就是指在自旋的基础上，自旋操作的尝试次数会上一次同一个锁上的自旋时间以及锁的拥有者的状态来动态指定。


## synchronized vs ReenTrantLock  

1. 两者都是可重入锁。
2. synchronized依赖于JVM实现，而ReenTrantLock依赖于Java api(需要通过lock,unlock方法和try/finally语句快完成)。
3. ReenTrantLock相较于synchronized增加了几个高级功能-等待可中断，可实现公平锁，可实现选择性通知。

> 等待可中断

ReenTrantLock提供了一种能够中断等待锁的线程的机制，通过lock.lockInterruptibly()来实现这个机制。也就是说正在等待的线程可以选择放弃等待，改为处理其他事情。

> 可实现公平锁

ReenTrantLock默认是非公平锁，但是可通过构造方法ReentrantLock(boolean fair)来确认是否使用公平锁，而synchronized只能是非公平锁。

> 可实现选择性通知

ReenTrantLock可借助Condition接口(Java1.5 后才有的接口)的newCondition方法实现等待/通知机制。Condition具有灵活的使用方式，一个Lock可以具有多个Condition,每个线程可以注册到指定的Condition中，从而能够实现有选择性的通知线程。synchronized只能通过wait,notify,notifyAll相结合实现等待/通知机制，并且只能由JVM来选择唤醒的线程，相当于所有线程都注册到同一个Condition当中。

注意：在JDK1.6以前synchronized未优化时，synchronized和ReenTrantLock选择上，考虑到性能问题一般不推荐使用synchronized，而优化后两者的性能基本持平。由于synchronized使用方便，所以若需要使用上述synchronized没有的功能才会使用ReenTrantLock+Condition。

# 参考链接

- [synchronized关键字](https://github.com/Snailclimb/JavaGuide/blob/master/Java%E7%9B%B8%E5%85%B3/synchronized.md)
- [Synchronized底层优化（偏向锁、轻量级锁）](http://www.cnblogs.com/paddix/p/5405678.html)
- [java 中的锁 -- 偏向锁、轻量级锁、自旋锁、重量级锁](https://www.jianshu.com/p/78cf35f01b2f)