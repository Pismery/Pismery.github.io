---
title: "并发编程之并发工具类-CyclicBarrier"
discriptions: "并发编程之并发工具类-CyclicBarrier"
date: 2018-12-21T21:05:00+08:00
author: Pismery Liu
archives: "2018"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---

同步工具类 CyclicBarrer 实现一组线程相互等待，直到所有线程到达屏障。

<!--more-->

# CyclicBarrier

CyclicBarrier 用来实现一组线程被阻塞在屏障前，直到最后一个线程到达屏障前，再打开屏障唤醒所有线程继续运行的场景。又因为 Barrier 被释放后能够继续重用，所以叫循环屏障或循环栅栏。

> 构造 CyclicBarrier

```Java
public CyclicBarrier(int parties, Runnable barrierAction) {
    if (parties <= 0) throw new IllegalArgumentException();
    this.parties = parties;
    this.count = parties;
    this.barrierCommand = barrierAction;
}

public CyclicBarrier(int parties) {
    this(parties, null);
}
```

如上图源码，CyclicBarrier 有两个构造函数。下面介绍参数意思：

- parties：表示阻塞的线程数。
- barrierAction：当所有线程到达屏障时，先执行 barrierAction，再打开屏障，主要用于实现更复杂的场景。


> 源码分析 api

从下面的 CyclicBarrier 源码，发现 CyclicBarrier 是依赖 ReentrantLock 和 Condition 实现的。注意 Generation 是 CyclicBarrier 更新换代的标志，同一批次线程属于同一代，当正常打开屏障则会更新换代。broken 表示是否屏障是否被破坏。

```Java
public class CyclicBarrier {
    private static class Generation {
        boolean broken = false;
    }
    /** The lock for guarding barrier entry */
    private final ReentrantLock lock = new ReentrantLock();
    /** Condition to wait on until tripped */
    private final Condition trip = lock.newCondition();
    /** The number of parties */
    private final int parties;
    /* The command to run when tripped */
    private final Runnable barrierCommand;
    /** The current generation */
    private Generation generation = new Generation();
    
    //还需等待的线程数目，当执行newgeneration或者屏障打开重制为parties
    private int count;
}
```

CyclicBarrier 最重要的方法就是 await 方法，下面分析 await 方法的源码实现

```Java
//方法作用: 打开屏障(即唤醒所有等待的线程)，重制count值，更新generation
private void nextGeneration() {
    // signal completion of last generation
    trip.signalAll();
    // set up next generation
    count = parties;
    generation = new Generation();
}

//方法作用: Sets current barrier generation as broken and wakes up everyone
private void breakBarrier() {
    generation.broken = true;
    count = parties;
    trip.signalAll();
}


public int await() throws InterruptedException, BrokenBarrierException {
    try {
        return dowait(false, 0L);
    } catch (TimeoutException toe) {
        throw new Error(toe); // cannot happen
    }
}

private int dowait(boolean timed, long nanos)
    throws InterruptedException, BrokenBarrierException,
           TimeoutException {
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        final Generation g = generation;
        
        //如果屏障被破坏，抛出BrokenBarrierException异常
        if (g.broken)
            throw new BrokenBarrierException();
        
        //如果线程被中断，破坏屏障并抛出InterruptedException异常
        if (Thread.interrupted()) {
            breakBarrier();
            throw new InterruptedException();
        }
        
        int index = --count;
        //若最后一个线程到达则执行ranAction，并调用nextGeneration，打开屏障，唤醒所有线程运行。
        if (index == 0) {  // tripped
            boolean ranAction = false;
            try {
                final Runnable command = barrierCommand;
                if (command != null)
                    command.run();
                ranAction = true;
                nextGeneration();
                return 0;
            } finally {
                //如果barrierCommand执行异常，执行breakBarrier破坏屏障，唤醒所有等待线程，
                if (!ranAction)
                    breakBarrier();
            }
        }

        // loop until tripped, broken, interrupted, or timed out
        for (;;) {
            try {
                if (!timed)
                    trip.await();
                else if (nanos > 0L)
                    nanos = trip.awaitNanos(nanos);
            } catch (InterruptedException ie) {
                if (g == generation && ! g.broken) {
                    breakBarrier();
                    throw ie;
                } else {
                    // We're about to finish waiting even if we had not
                    // been interrupted, so this interrupt is deemed to
                    // "belong" to subsequent execution.
                    Thread.currentThread().interrupt();
                }
            }
            
            //如果被唤醒后，屏障被破坏
            if (g.broken)     
                throw new BrokenBarrierException();
            //如果被唤醒后屏障没有被破坏，并且已经更新为下一代，则正常返回退出。
            if (g != generation) 
                return index;
            
            //如果等待超时则破坏屏障，抛出异常；
            if (timed && nanos <= 0L) {
                breakBarrier();
                throw new TimeoutException();
            }
        }
    } finally {
        lock.unlock();
    }
}
```

从源码可以分析出 await 方法处理逻辑如下：

1. 当最后一个线程未到达前，所有线程被阻塞；
2. 若有线程被中断，则破坏屏障所有线程抛出 BrokenBarrierException；
3. 若有线程等待超时，则破坏屏障并唤醒其他线程后抛出 TimeoutException，其他线程发现屏障被破坏后抛出 BrokenBarrierException；
4. 若主动调用此 barrier 的 reset() 方法，则破坏屏障所有线程抛出 BrokenBarrierException；并更新 Generation;
5. 若上述情况未发生，最后一个线程到达，则唤醒所有线程继续运行。


> 使用示例

模拟开会，等待所有人到齐后再开会

```Java
public class CyclicBarrierDemo {
    private static final CyclicBarrier cyclicBarrier =  new CyclicBarrier(5,
            ()-> System.out.println("All people arrived,start the meeting")
    );


    public static void main(String[] args) {
        List<Person> people = Arrays.asList(
                new Person("n1"),
                new Person("n2"),
                new Person("n3"),
                new Person("n4"),
                new Person("n5")
        );

        ExecutorService executorService = Executors.newFixedThreadPool(5);

        people.forEach(person -> executorService.execute(person));

        executorService.shutdown();
    }


    @AllArgsConstructor
    private static class Person implements Runnable {

        private String name;

        @Override
        public void run() {
            System.out.println(name+" attended...");

            try {
                cyclicBarrier.await();
            } catch (InterruptedException | BrokenBarrierException e) {
                e.printStackTrace();
            }
        }
    }
}

## 结果
n2 attended...
n1 attended...
n3 attended...
n4 attended...
n5 attended...
All people arrived,start the meeting
```

> 参考链接

- [【死磕Java并发】—–J.U.C之并发工具类：CyclicBarrier](http://cmsblogs.com/?p=2241)