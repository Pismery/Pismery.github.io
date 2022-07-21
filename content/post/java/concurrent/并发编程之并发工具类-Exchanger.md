---
title: "并发编程之并发工具类 Exchanger"
discriptions: "并发编程之并发工具类 Exchanger"
date: 2019-03-02T20:47:12+08:00
author: Pismery Liu
archives: "2019"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---

<div></div>

<!--more-->

# Exchanger

Exchanger 是 Jdk5 之后提供的一个并发工具类，用于两个线程之间交互数据；下面是官方 api 的描述


```Java
/**
 * A synchronization point at which threads can pair and swap elements
 * within pairs.  Each thread presents some object on entry to the
 * {@link #exchange exchange} method, matches with a partner thread,
 * and receives its partner's object on return.  An Exchanger may be
 * viewed as a bidirectional form of a {@link SynchronousQueue}.
 * Exchangers may be useful in applications such as genetic algorithms
 * and pipeline designs.
 */
```

简单表示为下列几点：

1. 以同步的方式对成对线程之间进行数据交换
2. 一个 Exchanger 可以视为一个双向同步队列
3. 适用于基因算法和流水线场景

> 源码

```Java
public V exchange(V x) throws InterruptedException {
    Object v;
    Object item = (x == null) ? NULL_ITEM : x; // translate null args
    if ((arena != null ||
         (v = slotExchange(item, false, 0L)) == null) &&
        ((Thread.interrupted() || // disambiguates null return
          (v = arenaExchange(item, false, 0L)) == null)))
        throw new InterruptedException();
    return (v == NULL_ITEM) ? null : (V)v;
}

public V exchange(V x, long timeout, TimeUnit unit)
        throws InterruptedException, TimeoutException {
    Object v;
    Object item = (x == null) ? NULL_ITEM : x;
    long ns = unit.toNanos(timeout);
    if ((arena != null ||
         (v = slotExchange(item, true, ns)) == null) &&
        ((Thread.interrupted() ||
          (v = arenaExchange(item, true, ns)) == null)))
        throw new InterruptedException();
    if (v == TIMED_OUT)
        throw new TimeoutException();
    return (v == NULL_ITEM) ? null : (V)v;
}
```

执行流程如下：

当一个线程调用 exchange 方法时

- 如果其对应的线程已经调用了 exchange 方法，则唤醒对应线程进行数据交换后各自返回。
- 如果对应线程还未调用 exchange 方法，则线程阻塞，等待对应线程调用 exchange 方法；
- 如果线程在等待过程中，线程被中断，则抛出中断异常；如果线程等待超时，则抛出超时异常

JDK6 以后 Exchanger 实现采用了类似 ConcurrentHashMap 的分段锁方式，将内部的 Stack 分为 多个片段 Slot，线程 ID(Thread.getId()) 哈希值相同的会落在同一个 Slot 上。默认是 32 个 Slot, JDK 还会根据运行环境 CPU 核数进行一定的优化；

> 示例

1. 生产者每秒产生一个数字 i, 消费者消费生产者生产的数字后交换为 0；




```Java
public class ExchangerDemo {
    // 用于控制线程执行，这里可以不使用 volatile 也能保证线程间的可见性；
    // 原因是采用了 System.out.print 内部有 sychronzied 此时会自动去获取主存的值；
    private static boolean done = false;

    static class ExchangerProducer implements Runnable {
        private Exchanger<Integer> exchanger;

        public ExchangerProducer(Exchanger<Integer> exchanger) {
            this.exchanger = exchanger;
        }

        @Override
        public void run() {
            int product = 0;

            for (int i = 0; i < 3; i++) {
                product = i;
                if (exchanger != null) {
                    try {
                        TimeUnit.SECONDS.sleep(1);
                        System.out.println("Producer produce:" + product);
                        exchanger.exchange(i);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }
            done = true;
        }
    }

    static class ExchangerConsumer implements Runnable {
        private Exchanger<Integer> exchanger;

        public ExchangerConsumer(Exchanger<Integer> exchanger) {
            this.exchanger = exchanger;
        }

        @Override
        public void run() {
            int i = 0;
            while (!done && exchanger != null) {
                try {
                    TimeUnit.SECONDS.sleep(1);
                    Integer exchange = exchanger.exchange(i);
                    System.out.println("Consumer:" + exchange);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }


    public static void main(String[] args) {
        Exchanger<Integer> exchanger = new Exchanger<>();
        ExecutorService threadPool = Executors.newFixedThreadPool(2);
        threadPool.submit(new ExchangerProducer(exchanger));
        threadPool.submit(new ExchangerConsumer(exchanger));

        threadPool.shutdown();
    }
}

//运行结果
Producer produce:0
Consumer:0
Producer produce:1
Consumer:1
Producer produce:2
Consumer:2
```


场景：用于校对工作，如某些银行流水需要手动输入，为了避免录入错误，因此，让 A 和 B 分别录入，两者录入在各自 Excel 中，系统需要校对两份 Excel；


```Java
public class ExchangerDemo2 {

    public static void main(String[] args) {
        final Exchanger<String> excelContent = new Exchanger<>();

        ExecutorService threadPool = Executors.newFixedThreadPool(2);

        threadPool.submit(() -> {
            try {
                TimeUnit.SECONDS.sleep(2); //模拟录入时间
                excelContent.exchange("content");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });


        threadPool.submit(() -> {
            try {
                TimeUnit.SECONDS.sleep(1); //模拟录入时间
                String a = "content";
                String b = excelContent.exchange(a);
                System.out.println("A和B数据是否一致：" + a.equals(b) + ",A录入的是："
                        + a + ",B录入是：" + b);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

        });

        threadPool.shutdown();
    }
}

// 运行结果
A和B数据是否一致：true,A录入的是：content,B录入是：content
```

# 参考文章

- [java Exchanger 原理](https://blog.csdn.net/coslay/article/details/45242581)