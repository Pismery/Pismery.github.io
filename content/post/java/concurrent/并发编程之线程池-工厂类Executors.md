---
title: "并发编程之线程池-工厂类Executors"
discriptions: "并发编程之线程池-工厂类Executors"
date: 2018-12-05T21:16:38+08:00
author: Pismery Liu
archives: "2018"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---

线程池工厂类 Executors

<!--more-->

# Executors工厂类

> 前置概念

分治法：对于一个规模为n的问题，若该问题可以容易地解决（比如说规模n较小）则直接解决，否则将其分解为k个规模较小的子问题，这些子问题互相独立且与原问题形式相同，递归地解这些子问题，然后将各子问题的解合并得到原问题的解；基本操作步骤：拆分->解决->合并。

> 基本介绍

因为配置一个线程池比较复杂，需要了解其实现的原理，很有可能配置的线程池性能不佳，因此Executors类提供了静态工厂方法创建以下六种常用的线程池:

- newCachedThreadPool:创建一个可缓存线程池，如果线程池长度超过处理需要，可灵活回收空闲线程，若无可回收，则新建线程。此线程池不会对线程池大小做限制，线程池大小完全依赖于操作系统（或者说JVM）能够创建的最大线程大小。
- newFixedThreadPool:创建固定大小的线程池。每次提交一个任务就创建一个线程，直到线程达到线程池的最大大小。线程池的大小一旦达到最大值就会保持不变，如果某个线程因为执行异常而结束，那么线程池会补充一个新线程。
- newSingleThreadExecutor:创建一个单线程的线程池。这个线程池只有一个线程在工作，也就是相当于单线程串行执行所有任务。如果这个唯一的线程因为异常结束，那么会有一个新的线程来替代它。此线程池保证所有任务的执行顺序按照任务的提交顺序(FIFO, LIFO, 优先级)执行。
- newWorkStealingPool: java7新出现的线程池，底层调用的是ForkJoinPool。其思想是采用分治法解决问题，使用fork()和join()来进行调用线程。这个线程池还有一个特性即工作窃取机制，例如当两个线程同时解决问题，线程1提前完成子问题，它会去‘窃取’线程2的任务，帮助线程2完成，最后合并子问题结果得到最终问题结果。
- newScheduledThreadPool:创建一个定长线程池，支持定时及周期性任务执行。
- newSingleThreadScheduledExecutor：仅仅是newSingleThreadExecutor与newScheduledThreadPool的结合。


> 使用示例

```
public static void main(String[] args) {
    ExecutorService threadPool = Executors.newCachedThreadPool();
    runWithThreadPool(threadPool, "newCachedThreadPool");
    
    ExecutorService threadPool = Executors.newWorkStealingPool(10);
    runWithThreadPool(threadPool, "newWorkStealingPool");
    
    ExecutorService threadPool = Executors.newFixedThreadPool(10);
    runWithThreadPool(threadPool, "newFixedThreadPool");
}

private static void runWithThreadPool(ExecutorService threadPool, String name) {
    log.debug("==================" + name + "==================");
    List<Future<String>> futureList = new ArrayList<>();
    for (int i = 0; i < 100; i++) {
        Callable<String> callable = () -> Thread.currentThread().getName() + " is running...";
        futureList.add(threadPool.submit(callable));
    }
    log.debug(name + " Middle: " + threadPool);
    futureList.forEach(future -> {
        try {
            future.get();
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
    });
    log.debug(name + " Done: " + threadPool);

    threadPool.shutdownNow();
}
```

## newCachedThreadPool

> 源码

```
public static ExecutorService newCachedThreadPool() {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                  60L, TimeUnit.SECONDS,
                                  new SynchronousQueue<Runnable>());
}

public static ExecutorService newCachedThreadPool(ThreadFactory threadFactory) {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                  60L, TimeUnit.SECONDS,
                                  new SynchronousQueue<Runnable>(),
                                  threadFactory);
}
```

从中可以看出底层使用的是ThreadPoolExecutor，传入一个阻塞缓存队列(SynchronousQueue)实现缓存。

> 特性

- 如果有闲置可用线程则重用线程，如果没有则新建线程并添加到线程池中。
- 线程池的最大数目为Integer.MAX_VALUE。
- 默认闲置60s的线程将被终止并移除。
- 若线程池长期闲置，所有线程被回收，不会消耗资源。
- 阻塞队列大小没有限制。

> 适用范围

- 适用于执行大量短期异步的任务。
- 不适用于高并发、高负载的情况，因为阻塞队列大小没有限制，如果队列堆积过多会造成系统资源枯竭。



## newFixedThreadPool

> 源码

```
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(nThreads, nThreads,
                                  0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>());
}

public static ExecutorService newFixedThreadPool(int nThreads, ThreadFactory threadFactory) {
    return new ThreadPoolExecutor(nThreads, nThreads,
                                  0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>(),
                                  threadFactory);
}
```

从源码可以看出newFixedThreadPool底层与newCachedThreadPool一样是ThreadPoolExecutor。不过其最大最小线程数均为固定值。keepAliveTime是0是因为不存在有多余的线程，所以直接设置为0。

> 特性

- 具有固定大小的线程池，若线程池所有线程都工作，此时新的任务将在队列中等待。
- 线程数目固定，不会被自动回收。
- 若其中一个线程执行过程抛出异常，若有新的任务，将新建一个线程取代异常线程。整个过程保持线程池的数目。
- 阻塞队列大小没有限制。

> 适用范围

- 适用于多数情况最好高峰时期与低峰时期相差的线程数不多。
- 同样不适用于高并发、高负载的情况，


## newSingleThreadExecutor

> 源码

```
/**
 * Creates an Executor that uses a single worker thread operating
 * off an unbounded queue. (Note however that if this single
 * thread terminates due to a failure during execution prior to
 * shutdown, a new one will take its place if needed to execute
 * subsequent tasks.)  Tasks are guaranteed to execute
 * sequentially, and no more than one task will be active at any
 * given time. Unlike the otherwise equivalent
 * {@code newFixedThreadPool(1)} the returned executor is
 * guaranteed not to be reconfigurable to use additional threads.
 *
 * @return the newly created single-threaded Executor
 */
public static ExecutorService newSingleThreadExecutor() {
    return new FinalizableDelegatedExecutorService
        (new ThreadPoolExecutor(1, 1,
                                0L, TimeUnit.MILLISECONDS,
                                new LinkedBlockingQueue<Runnable>()));
}
```
从源码的Javadoc上看，注意最后一句话Unlike the otherwise equivalent  {@code newFixedThreadPool(1)} the returned executor is guaranteed not to be reconfigurable to use additional threads。意思是与其等价的newFixedThreadPool(1)不同的是newSingleThreadExecutor能够保证不能重新配置去使用其他的线程。

> 示例

```
final ExecutorService single = Executors.newSingleThreadExecutor();
ThreadPoolExecutor executor = (ThreadPoolExecutor) single;
executor.setCorePoolSize(4);


final ExecutorService fixed  = Executors.newFixedThreadPool(1);
ThreadPoolExecutor executor = (ThreadPoolExecutor) fixed;
executor.setCorePoolSize(4);

## 结果
single会抛出ClassCastException异常。
fixed能够正常使用，能够重新配置线程池。
```

从源码方法实现上看，留意到newSingleThreadExecutor就是在newFixedThreadPool(1)上包装了一层FinalizableDelegatedExecutorService，而进入FinalizableDelegatedExecutorService发现其继承DelegatedExecutorService类，这个类是将AbstractExecutorService进行包装使其只暴露ExecutorService的方法，从而实现隐藏了ThreadPoolExecutor中配置线程池的方法

> 特性

- 整个运行期间线程池只有一个线程，保证了任务的执行顺序，先提交的先执行。
- 若线程出现异常，将会新建新的线程替代原来的，执行后续任务。

> 适用范围

- 任务需要顺序执行。

> 与newFixedThreadPool(1)区别

从源码上看，newSingleThreadExecutor仅仅是在newFixedThreadPool(1)上包装了FinalizableDelegatedExecutorService类，使其只暴露线程池的执行方法，隐藏了ThreadPoolExecutor配置线程池的方法。因此两者除了能否重新配置线程池以外没有其他区别。

注意在网上说两者区别有

- newSingleThreadExecutor能够保证任务的执行顺序，newFixedThreadPool(1)不能。
- newSingleThreadExecutor在线程异常时会新建线程替换异常线程，newFixedThreadPool不能。

第二种理解错误，应该都是查看方法的Javadoc最后一句话，理解错误导致的。而第一种错误存粹臆想。


## newWorkStealingPool

> 源码

```
public static ExecutorService newWorkStealingPool(int parallelism) {
    return new ForkJoinPool
        (parallelism,
         ForkJoinPool.defaultForkJoinWorkerThreadFactory,
         null, true);
}

public static ExecutorService newWorkStealingPool() {
    return new ForkJoinPool
        (Runtime.getRuntime().availableProcessors(),
         ForkJoinPool.defaultForkJoinWorkerThreadFactory,
         null, true);
}
```

newWorkStealingPool底层使用的是ForkJoinPool并且使用的是FIFO队列，若最后一个参数为false则是LIFO队列。并且若不传parallelism参数则默认使用当前系统环境可用的CPU数目。parallelism与最大线程数相一致。

> 特性

- 不保证任务的执行顺序。
- 线程池的线程数目会动态增减
- 维护多个工作队列(相当于ThreadPoolExecutor的阻塞队列)，减少竞争。

> 适用范围

- 面对能够使用分治法解决的问题使用多线程运行，这些问题能够拆分为多个子问题分别解决，最终汇总子问题的结果得到最终结果；例如求和、图像模糊；

## newScheduledThreadPool

> 源码

```
public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) {
    return new ScheduledThreadPoolExecutor(corePoolSize);
}

public static ScheduledExecutorService newScheduledThreadPool(
        int corePoolSize, ThreadFactory threadFactory) {
    return new ScheduledThreadPoolExecutor(corePoolSize, threadFactory);
}
```

newScheduledThreadPool底层使用ScheduledThreadPoolExecutor，而ScheduledThreadPoolExecutor仍是继承自ThreadPoolExecutor。使用DelayedWorkQueue作为阻塞队列

> 特性

- 具有无边界的阻塞队列
- 能够指定延迟时间和执行间隔时间，重复的执行。
- 可以延时启动，定时启动的线程池。

> 适用范围

- 适用于需要多个后台线程执行周期任务的场景。


## 最佳实现

FixedThreadPool 和 CachedThreadPool 两者对高负载的应用都不是特别友好。CachedThreadPool 要比 FixedThreadPool 危险很多。如果应用要求高负载、低延迟，最好不要选择以上两种线程池：

- 任务队列的无边界：会导致内存溢出以及高延迟
- 长时间运行会导致 CachedThreadPool 在线程创建上失控

因为两者都不是特别友好，所以推荐使用 ThreadPoolExecutor ，它提供了很多参数可以进行细粒度的控制。

- 将任务队列设置成有边界的队列
- 使用合适的 RejectionHandler - 自定义的 RejectionHandler 或 JDK 提供的默认 handler 。
- 如果在任务完成前后需要执行某些操作，可以重载beforeExecute(Thread, Runnable)和afterExecute(Runnable, Throwable)方法
- 重载 ThreadFactory ，如果有线程定制化的需求
- 在运行时动态控制线程池的大小（Dynamic Thread Pool）

# 参考链接

- [五种线程池的对比与使用](https://www.jianshu.com/p/135c89001b61)
- [Executors中的newSingleThreadExecutor和newFixedThreadPool(1)的区别](https://blog.csdn.net/zxm490484080/article/details/80949115)
- [线程池的种类，区别和使用场景](https://www.cnblogs.com/sachen/p/7401959.html)
- [JAVA线程池shutdown和shutdownNow的区别](http://xtu-xiaoxin.iteye.com/blog/649677)
- [线程池 FixedThreadPool vs CachedThreadPool](http://www.cnblogs.com/richaaaard/p/6599184.html)
