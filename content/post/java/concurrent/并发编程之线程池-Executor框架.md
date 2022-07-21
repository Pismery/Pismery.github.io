---
title: "并发编程之线程池-Executor框架"
discriptions: "并发编程之线程池-Executor框架"
date: 2018-12-09T08:50:27+08:00
author: Pismery Liu
archives: "2018"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---

Executor 框架线程池框架。

<!--more-->

# Executor 框架

> 类图

![](https://ws1.sinaimg.cn/large/006xNbipgy1fxw54dzfh4j30o60k2t9q.jpg)

> 基本介绍

Java 中线程池的顶级接口是 Executor，但是 Executor 只是执行线程的工具，真正的线程池接口是 ExecutorService。其中实现的线程池有 ThreadPoolExecutor, ScheduledThreadPoolExecutor, ForkJoinPool;

线程池中比较重要的几个类

类 | 介绍
---|---
ExecutorService | 线程池接口
ScheduledExecutorService | 能和Timer/TimerTask类似，解决那些需要任务重复执行的问题。
ThreadPoolExecutor | ExecutorService的默认实现。
ScheduledThreadPoolExecutor | 继承ThreadPoolExecutor的ScheduledExecutorService接口实现，周期性任务调度的类实现。
ForkJoinPool | 使用Fork/Join模式，实现任务分解多核运行。



## 接口介绍

Executor 框架中有三个接口

- Executor: 一个运行新任务的简单接口；
- ExecutorService: 在 Executor 基础上添加了一些用来管理执行器生命周期和任务生命周期的方法；
- ScheduleExecutorService: 在 ExecutorService 基础上，支持定期执行任务

### Executor

> 源码

```
public interface Executor {
    void execute(Runnable command);
}
```

这个接口用来替代线程的创建与启动。例如

```
## Thread 启动
Thread thread = new Thread();
thread.run();

## Executor 启动
Thread thread = new Thread();
executor.execute(thread);
```

对于不同的 Executor 实现，execute() 方法可能是创建一个新线程并立即启动，也有可能是使用已有的工作线程来运行传入的任务，也可能是根据设置线程池的容量或者阻塞队列的容量来决定是否要将传入的线程放入阻塞队列中或者拒绝接收传入的线程。

### ExecutorService

> 介绍

ExecutorService 接口继承自 Executor 接口，提供了管理终止的方法，以及可为跟踪一个或多个异步任务执行状况而生成 Future 的方法。增加了shutDown()，shutDownNow()，invokeAll()，invokeAny() 和 submit() 等方法。

> 源码

```Java
## 一个线程池操作的接口
public interface ExecutorService extends Executor {
    void shutdown();
    List<Runnable> shutdownNow();
    
    isShutdown();
    isTerminated();
    
    <T> Future<T> submit(Callable<T> task);
    <T> Future<T> submit(Runnable task, T result);
    Future<?> submit(Runnable task);
    void execute(Runnable command); //继承Executor而来
    
    boolean awaitTermination(long timeout, TimeUnit unit)
        throws InterruptedException;
    <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit)
        throws InterruptedException;
    <T> T invokeAny(Collection<? extends Callable<T>> tasks)
        throws InterruptedException, ExecutionException;

}
```

> submit vs execute

- submit()，提交一个线程任务，可以接受回调函数的返回值，适用于需要处理返回着或者异常的业务场景;
- execute()，执行一个任务，没有返回值;

### ScheduledExecutorService

ScheduledExecutorService 扩展 ExecutorService 接口并增加了 schedule 方法。调用 schedule 方法可以在指定的延时后执行一个 Runnable 或者 Callable 任务。ScheduledExecutorService 接口还定义了按照指定时间间隔定期执行任务的 scheduleAtFixedRate() 方法和 scheduleWithFixedDelay() 方法。


## ThreadPoolExecutor

> 介绍

ThreadPoolExecutor 继承自 AbstractExecutorService，也是实现了 ExecutorService 接口。

### 重要字段解释

```Java
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
private static final int COUNT_BITS = Integer.SIZE - 3;
private static final int CAPACITY   = (1 << COUNT_BITS) - 1;

// Packing and unpacking ctl
private static int runStateOf(int c)     { return c & ~CAPACITY; }
private static int workerCountOf(int c)  { return c & CAPACITY; }
private static int ctlOf(int rs, int wc) { return rs | wc; }
```

ctl 是对线程池的运行状态和线程池中有效线程的数量进行控制的一个字段， 它包含两部分的信息: 线程池的运行状态 (runState) 和线程池内有效线程的数量 (workerCount)，这里可以看到，使用了 Integer 类型来保存，高 3 位保存runState，低29位保存workerCount。COUNT_BITS=Integer.SIZE-3=32-3=29，CAPACITY就是 1 左移 29 位减 1（29 个 1），这个常量表示 workerCount 的上限值，大约是 5 亿。

- runStateOf(int c)：获取运行状态；
- workerCountOf(int c)：获取活动线程数；
- ctlOf(int rs, int wc)：获取运行状态和活动线程数的值。

### 构造方法

```Java
## 构造函数声明
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory
                          RejectedExecutionHandler handler) {
    ...
}
```

> 参数解释

参数 | 解释
---|---
corePoolSize | 线程池核心线程数(最小线程数)
maximumPoolSize | 最大线程数
keepAliveTime | 线程存活时间(线程闲置时间，超过则被回收移除)
unit | 时间单位
workQueue | 缓存阻塞队列
threadFactory | 线程工厂
handler | 线程被拒绝时执行handler

**workQuene**: 保存等待执行的任务的阻塞队列，当提交一个新的任务到线程池以后, 线程池会根据当前线程池中正在运行着的线程的数量来决定对该任务的处理方式，主要有以下几种处理方式：

- SynchronousQueue: 如果不希望任务在队列中等待而是希望将任务直接移交给工作线程，可使用 SynchronousQueue 作为等待队列。SynchronousQueue 机制是要将一个元素放入 SynchronousQueue 中，必须有另一个线程正在等待接收这个元素。只有在使用无界线程池或者有饱和策略时才建议使用该队列。
- LinkedBlockingQueue: 如果使用这种方式，那么线程池中能够创建的最大线程数就是 corePoolSize，而maximumPoolSize 就不会起作用了。当线程池中所有的核心线程都是 RUNNING 状态时，这时一个新的任务提交就会放入等待队列中。
- ArrayBlockingQueue: 使用该方式可以将线程池的最大线程数量限制为 maximumPoolSize，这样能够降低资源的消耗，但同时这种方式也使得线程池对线程的调度变得更困难，因为线程池线程数目和队列的容量都是有限的值，需要合理的设置这两个值,以达到尽可能的降低线程池对资源的消耗和吞吐率达到一个相对合理的范围的要求。

设置线程池线程数目和队列的容量(PS:找到提高线程池的吞吐量和降低资源消耗的平衡)

1. 如果需要降低系统资源( CPU 使用率,上下文切换开销)的消耗，可以设置较低的线程池容量和较高的阻塞队列容量。但这样同时会降低整个线程池处理任务的吞吐量。
2. 如果整个线程池容量过小，导致提交任务经常阻塞，可以通过 setMaximumPoolSize() 方法来重新设定提高线程池的容量，提高处理任务的吞吐量。
3. 如果阻塞队列容量较小，一般需要增大线程池的容量，以避免任务经常性提交失败。但是若线程池容量过大，提交任务数目过多，会导致上下文切换频繁，反而会降低处理任务的吞吐量。

总的来说，线程池容量过大过小都会降低线程池处理任务吞吐量，阻塞队列大小是为了在合适的线程池容量时确保高峰时期能够容纳足够的任务，使得任务不会提交失败。

**handler**： 表示线程池的饱和策略。如果阻塞队列满了并且没有空闲的线程，这时如果继续提交任务，就需要采取一种策略处理该任务。线程池提供了 4 种策略：

- AbortPolicy：直接抛出异常，这是默认策略；
- CallerRunsPolicy：用调用者所在的线程来执行任务；
- DiscardOldestPolicy：丢弃阻塞队列中靠最前的任务，并执行当前任务；
- DiscardPolicy：直接丢弃任务；


### 线程池执行流程

1. 当前线程数小于 corePoolSize 时，新提交任务将创建一个新线程执行任务，即使此时线程池中存在空闲线程。
2. 当前线程数等于 corePoolSize 时，新提交任务将被放入 workQueue 中，等待线程池中任务调度执行
3. 当 workQueue 已满，且当前线程数小于 maximumPoolSize，新提交任务会创建新线程执行任务
4. 当 workQueue 已满，且当前线程数等于 maximumPoolSize 时，新提交任务由 RejectedExecutionHandler 处理
5. 当线程池中超过 corePoolSize 线程，空闲时间达到 keepAliveTime时，关闭空闲线程
6. 当设置 allowCoreThreadTimeOut(true) 时，线程池中 corePoolSize 线程空闲时间达到 keepAliveTime 也将关闭

> 补充

ThreadPoolExecutor 中，线程池任务队列采用 LinkedBlockingQueue 队列的话，那么不会拒绝任何任务（因为队列大小没有限制），这种情况下，ThreadPoolExecutor 最多仅会按照最小线程数来创建线程，也就是说线程池大小被忽略了。

如果线程池任务队列采用 ArrayBlockingQueue 队列的话，假定线程池的最小线程数为 4，最大为 8 所用的ArrayBlockingQueue 最大为 10。随着任务到达并被放到队列中，线程池中最多运行 4 个线程（即最小线程数）。即使队列完全填满，也就是说有 10 个处于等待状态的任务，ThreadPoolExecutor 也只会利用 4 个线程。如果队列已满，而又有新任务进来，此时才会启动一个新线程，这里不会因为队列已满而拒接该任务，相反会启动一个新线程。新线程会运行队列中的第一个任务，为新来的任务腾出空间。

这个算法背后的理念是：该池大部分时间仅使用核心线程（4 个），即使有适量的任务在队列中等待运行。这时线程池就可以用作节流阀。如果挤压的请求变得非常多，这时该池就会尝试运行更多的线程来清理；这时第二个节流阀—最大线程数就起作用了。


### 线程池状态

```Java
// runState is stored in the high-order bits
private static final int RUNNING    = -1 << COUNT_BITS;
private static final int SHUTDOWN   =  0 << COUNT_BITS;
private static final int STOP       =  1 << COUNT_BITS;
private static final int TIDYING    =  2 << COUNT_BITS;
private static final int TERMINATED =  3 << COUNT_BITS;

```

- RUNNING ：能接受新提交的任务，并且也能处理阻塞队列中的任务；
- SHUTDOWN：关闭状态，不再接受新提交的任务，但却可以继续处理阻塞队列中已保存的任务。在线程池处于 RUNNING 状态时，调用
shutdown()方法会使线程池进入到该状态。（finalize() 方法在执行过程中也会调用 shutdown() 方法进入该状态）；
- STOP：不能接受新任务，也不处理队列中的任务，会中断正在处理任务的线程。在线程池处于 RUNNING 或 SHUTDOWN 状态时，调用 shutdownNow() 方法会使线程池进入到该状态；
- TIDYING：如果所有的任务都已终止了，workerCount (有效线程数) 为0，线程池进入该状态后会调用 terminated() 方法进入 TERMINATED 状态。
- TERMINATED：在 terminated() 方法执行完后进入该状态，默认 terminated() 方法中什么也没有做。

### 线程池的关闭

**shutdown()**: 当调用此方法，线程池状态变为 SHUTDOWN 状态。此时，则不能再往线程池中添加任何任务，否则将会抛出 RejectedExecutionException 异常。但是，此时线程池不会立刻退出，直到添加到线程池中的任务都已经处理完成，才会退出。

**shutdownNow()**: 线程池的状态立刻变成 STOP 状态，并 interrupt() 方法试图停止所有正在执行的线程，不再处理还在池队列中等待的任务，返回那些未执行的任务。注意由于终止线程是通过 Thread.interrupt() 方法来实现的，但是这种方法只有线程sleep, wait, Condition, 定时锁等情况下才能终止。所以，shutdownNow() 也不意味着一定立即退出。

**awaitTermination(long timeOut, TimeUnit unit)**: 此方法是一个阻塞方法，直到所有任务结束(返回 true )，等待超时时间到(返回 false )，线程被打断(抛出 InterruptedException)。调用此方法后线程池还能够添加新的任务。

总结:

- 优雅关闭，允许新任务进入：awaitTermination
- 优雅关闭，不允许新任务进入：shutdown
- 立即关闭：shutdownNow

### 线程池监控

通过线程池提供的参数进行监控。线程池里有一些属性在监控线程池的时候可以使用

- getTaskCount：线程池已经执行的和未执行的任务总数；
- getCompletedTaskCount：线程池已完成的任务数量，该值小于等于taskCount；
- getLargestPoolSize：线程池曾经创建过的最大线程数量。通过这个数据可以知道线程池是否满过，也就是达到了maximumPoolSize；
- getPoolSize：线程池当前的线程数量；
- getActiveCount：当前线程池中正在执行任务的线程数量。

通过这些方法，可以对线程池进行监控，在 ThreadPoolExecutor 类中提供了几个空方法，如 beforeExecute 方法， afterExecute 方法和 terminated 方法，可以扩展这些方法在执行前或执行后增加一些新的操作，例如统计线程池的执行任务的时间等，可以继承自 ThreadPoolExecutor 来进行扩展。


## ScheduledThreadPoolExecutor

### 介绍

ScheduledThreadPoolExecutor 是用来支持周期性任务调度的。在此之前是使用 Timer 和 TimerTask 或者其它第三方工具来完成。但是 Timer 有以下缺陷

- Timer 是单线程的，因此如果某个 TimerTask 执行时间过长，影响其他任务调度
- Timer 调度对系统时间敏感，使用的绝对时间 
- Timer 不会捕获 TimerTask 的异常，又因为是单线程，所以一旦 TimerTask 出现异常线程终止，则后续 Task 均得不到执行。

ScheduledThreadPoolExecutor 实现方式概要：

- 继承 ThreadPoolExecutor 来重用线程池的功能，将 Task 封装成 ScheduledFutureTask，而 ScheduledFutureTask 是基于相对时间的，所以不受系统时间改变的影响。
- ScheduledFutureTask 实现了 java.lang.Comparable 接口和 java.util.concurrent.Delayed 接口，所以有两个重要的方法：compareTo 和 getDelay。compareTo 方法用于比较任务之间的优先级关系，如果距离下次执行的时间间隔较短，则优先级高；getDelay 方法用于返回距离下次任务执行时间的时间间隔；
- 内部定义了 DelayedWorkQueue，它是一个有序队列，会通过每个任务按照距离下次执行时间间隔的大小来排序；
- ScheduledFutureTask 继承自 FutureTask，可以通过返回 Future 对象来获取执行的结果。

因此相较于 Timer，ScheduledThreadPoolExecutor 具有基于相对时间、多线程运行，Task 的执行不会影响其他线程执行 Task。


> 构造函数

```Java
public class ScheduledThreadPoolExecutor extends ThreadPoolExecutor implements ScheduledExecutorService {

    public ScheduledThreadPoolExecutor(int corePoolSize, ThreadFactory threadFactory ,RejectedExecutionHandler handler) {
        super(corePoolSize, Integer.MAX_VALUE, 0, NANOSECONDS,
              new DelayedWorkQueue(), threadFactory, handler);
    }
    
}
```

从源码看出 ScheduledThreadPoolExecutor 仍是继承自 ThreadPoolExecutor。使用的是 DelayedWorkQueue 作为阻塞队列。

### 设置和执行任务

```Java
public class ScheduledThreadPoolExecutor extends ThreadPoolExecutor implements ScheduledExecutorService {
    public void execute(Runnable command) {
        schedule(command, 0, NANOSECONDS);
    }
    public Future<?> submit(Runnable task) {
        return schedule(task, 0, NANOSECONDS);
    }
    
    public ScheduledFuture<?> schedule(Runnable command,long delay,TimeUnit unit) {
        ...
    }
    public <V> ScheduledFuture<V> schedule(Callable<V> callable,long delay,TimeUnit unit) {
        ...
    }
    
    public ScheduledFuture<?> scheduleWithFixedDelay(Runnable command,long initialDelay,long delay, TimeUnit unit) {
        ...
    }
    public ScheduledFuture<?> scheduleAtFixedRate(Runnable command,long initialDelay,long period,TimeUnit unit) {
        ...
    }
}
```

> execute、submit、schedule

从源码上看 execute 和 submit 就是调用 schedule 方法只是没有延迟执行，是立即执行。

schedule 方法参数中 delay 表示延时时间，unit 表示时间单位


> scheduleWithFixedDelay、scheduleAtFixedRate

- scheduleWithFixedDelay: 周期性的执行任务，nextBeginTime = lastEndTime + delayTime
- scheduleAtFixedRate: 周期性的执行任务，nextBeginTime = lastBeginTime + delayTime;如果 Task 执行时间大于 lastBeginTime+delayTime 则等待 Task 执行完后立即执行下一个任务。


```Java
## scheduleWithFixedDelay
private static void fixedDelayDemo() throws InterruptedException {
        ScheduledExecutorService threadPool = Executors.newScheduledThreadPool(1);

        threadPool.scheduleWithFixedDelay(
                () -> log.debug(Thread.currentThread().getName() + ":scheduleWithFixedDelay Senior 1")
                , 1L
                , 1L
                , TimeUnit.SECONDS
        );
        Thread.sleep(5000L);
        threadPool.shutdown();
    }

## 结果
pool-1-thread-1:scheduleWithFixedDelay Senior 1
pool-1-thread-1:scheduleWithFixedDelay Senior 1
pool-1-thread-1:scheduleWithFixedDelay Senior 1
pool-1-thread-1:scheduleWithFixedDelay Senior 1

## 分析
下一个任务执行时在上一个任务执行完后延时 1s，所以 5s 时间内只能执行 4 次
```


```Java
## scheduleAtFixedRate Senior 1: 执行时间小于间隔时间
 ScheduledExecutorService threadPool = Executors.newScheduledThreadPool(1);
        threadPool.scheduleAtFixedRate(
                () ->log.debug(Thread.currentThread().getName() + ":scheduleAtFixedRate Senior 1")
                , 1L
                , 1L
                , TimeUnit.SECONDS
        );
        Thread.sleep(5500L);
        threadPool.shutdown();
## 结果
pool-1-thread-1:scheduleAtFixedRate Senior 1
pool-1-thread-1:scheduleAtFixedRate Senior 1
pool-1-thread-1:scheduleAtFixedRate Senior 1
pool-1-thread-1:scheduleAtFixedRate Senior 1
pool-1-thread-1:scheduleAtFixedRate Senior 1

## 分析

线程睡眠 5500ms 是为了避免因为系统运行不精确问题，导致可能 5s 只运行 4 次。
下一个任务执行时在上一个任务开始执行延时 1s，而执行任务时间小于 1s，所以 5s 时间内能执行 5 次
```

```Java
## scheduleAtFixedRate Senior 2: 执行时间 2s 大于间隔时间 1s
private static void fixedRateSenior2() throws InterruptedException {
    ScheduledExecutorService threadPool = Executors.newScheduledThreadPool(1);
    threadPool.scheduleAtFixedRate(
            () -> {
                try {
                    Thread.sleep(2000L);
                    log.debug(Thread.currentThread().getName() + ":scheduleAtFixedRate execute time more than delay time");
                } catch (InterruptedException e) {
                   log.debug(Thread.currentThread().getName() + ":sleep interrupt...");
                }
            }
            , 1L
            , 1L
            , TimeUnit.SECONDS
    );

    Thread.sleep(5500L);
    threadPool.shutdownNow();
}

## 结果
pool-1-thread-1:scheduleAtFixedRate execute time more than delay time
pool-1-thread-1:scheduleAtFixedRate execute time more than delay time
pool-1-thread-1:sleep interrupt...

## 分析
下一个任务执行时在上一个任务开始执行延时 1s，而执行任务时间 2s，所以 5s 内能够运行 2 次，第三次运行中间， shutDownNow 打断线程睡眠。
```

## ForkJoinPool

### 介绍

Fork\Join 框架：Java7 提供的一个用于并行执行任务的框架，将大任务拆分成小任务分别解决再合并小任务的结果得到大任务的结果。

ForkJoinPool：Java7 新增的线程池，用来支持 Fork\Join 框架的特殊线程池。

ForkJoinTask：定义一个可以并行和合并的任务，其实现了 Future 接口。具有两个抽象子类:

- RecursiveAction:  无返回值的任务
- RecursiveTask: 有返回值的任务

> compute 使用模板

```
if(任务足够小) {
    解决任务;
}eles {
    拆分任务;
    执行拆分任务等待执行结果;
    合并执行结果;
}
```


### 使用示例

```Java 
## RecursiveTask：求数组的和

public static void main(String[] args) throws InterruptedException, ExecutionException {
    ForkJoinPool forkJoinPool = new ForkJoinPool();
    int size = 10;
    int sum = 0;
    long[] array = new long[size];
    for (int i = 0; i < size; i++) {
        array[i] = i;
        sum += i;
    }

    ForkJoinTask<Integer> task = forkJoinPool.submit(new SumArrayTask(array));

    log.debug("Array result:" + sum + ";compute result:" + task.get());
}

public class SumArrayTask extends RecursiveTask<Integer> {
    private final static int THRESHOLD = 5;
    private final long[] array;
    private final int low, high;

    public SumArrayTask(long[] array, int low, int high) {
        this.array = array;
        this.low = low;
        this.high = high;
    }

    public SumArrayTask(long[] array) {
        this(array, 0, array.length);
    }

    @Override
    protected Integer compute() {
        int sum = 0;
        if (high - low < THRESHOLD) {
            for (int i = low; i < high; i++) {
                sum += array[i];
            }
            log.debug("{}: sub task[{},{}] result - {}", Thread.currentThread().getName(), low, high, sum);
            return sum;
        }

        int mid = low + (high - low) / 2;

        SumArrayTask left = new SumArrayTask(array, low, mid);
        SumArrayTask right = new SumArrayTask(array, mid, high);
        invokeAll(left, right);

        sum = left.join() + right.join();
        log.debug("{}: Join task result - {}" , Thread.currentThread().getName(), sum);

        return sum;
    }
}

## 结果
ForkJoinPool-1-worker-0: sub task[7,10] result - 24
ForkJoinPool-1-worker-1: sub task[0,2] result - 1
ForkJoinPool-1-worker-2: sub task[5,7] result - 11
ForkJoinPool-1-worker-3: sub task[2,5] result - 9
ForkJoinPool-1-worker-2: Join task result - 35
ForkJoinPool-1-worker-1: Join task result - 10
ForkJoinPool-1-worker-1: Join task result - 45
Array result:45;compute result:45

## 分析
测试的计算机只有四核，所以总共 4 个线程计算结果，将子结果分别计算好后，合并任务至最终结果
```

```Java
## RecursiveAction: 将数组每一个值自增

public static void main(String[] args) throws InterruptedException, ExecutionException {
    ForkJoinPool forkJoinPool = new ForkJoinPool();
    int size = 10;
    long[] array = new long[size];
    for (int i = 0; i < size; i++) {
        array[i] = i;
    }

    log.debug("Before"+Arrays.toString(array));
    forkJoinPool.execute(new IncrementTask(array, 0, size));

    forkJoinPool.awaitTermination(2, TimeUnit.SECONDS);
    forkJoinPool.shutdown();
    log.debug("After"+Arrays.toString(array));
}

@Slf4j
public class IncrementTask extends RecursiveAction {
    private static final int THRESHOLD = 2;
    private final long[] array;
    private final int low, high;

    public IncrementTask(long[] array, int low, int high) {
        this.array = array;
        this.low = low;
        this.high = high;
    }

    public IncrementTask(long[] array) {
        this(array, 0, array.length);
    }

    @Override
    protected void compute() {
        if (high - low < THRESHOLD) {
            for (int i = low; i < high; i++)
                log.debug(Thread.currentThread().getName() + ":" + array[i]++);
        } else {
            int mid = low + (high - low) / 2;
            IncrementTask left = new IncrementTask(array, low, mid);
            IncrementTask right = new IncrementTask(array, mid, high);

            left.fork();
            right.fork();
        }
    }
}

## 结果
Before[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
ForkJoinPool-1-worker-1:9
ForkJoinPool-1-worker-1:8
ForkJoinPool-1-worker-1:7
ForkJoinPool-1-worker-1:6
ForkJoinPool-1-worker-1:5
ForkJoinPool-1-worker-1:4
ForkJoinPool-1-worker-2:1
ForkJoinPool-1-worker-1:3
ForkJoinPool-1-worker-3:2
ForkJoinPool-1-worker-2:0
After[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
```

# 参考链接

- [threadPoolExecutor 中的 shutdown() 、 shutdownNow() 、 awaitTermination() 的用法和区别](https://blog.csdn.net/u012168222/article/details/52790400)
- [多线程（五） Fork/Join 框架介绍及实例讲解](https://blog.csdn.net/lishehe/article/details/46563785)
- [深入理解Java线程池：ScheduledThreadPoolExecutor](https://www.jianshu.com/p/925dba9f5969)
- [深入理解Java线程池：ThreadPoolExecutor](http://www.ideabuffer.cn/2017/04/04/%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3Java%E7%BA%BF%E7%A8%8B%E6%B1%A0%EF%BC%9AThreadPoolExecutor/)