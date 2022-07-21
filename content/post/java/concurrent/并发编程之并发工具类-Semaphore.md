---
title: "并发编程之并发工具类-Semaphore"
discriptions: "并发编程之并发工具类-Semaphore"
date: 2018-12-21T21:05:18+08:00
author: Pismery Liu
archives: "2018"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---

同步工具类 Semaphore 实现信号量的功能，具有公平锁和非公平锁两种方式。

<!--more-->

# Semaphore(信号量)

> 前置概念

公平锁：进入先检测等待队列是否有等待线程，若没有或者是第一个则获取锁，否则在队列中排队 FIFO。

非公平锁：进入直接获取锁，获取失败了才加入等待队列排队。

> 基本介绍

在Java中，synchronized 和 lock 锁实现了多线程环境下，保证只有一个线程能够访问共享资源。但是，在另一类场景中，共享资源有多个副本能够同时使用，如打印文件具有多台打印机。面对这类场景，Java 提供了资源的多副本的并发访问控制，Semaphore(信号量) 就是其中的一种。

Semaphore(信号量) 原理：其内部维护了一个计数器，计数器的数值表示剩余的共享资源个数。一个线程若要访问共享资源则需要获取信号量，若计数器值大于等于 1 ，则先将计数器的值减一，再访问共享资源。若计数器值为 0，则线程进入休眠状态，直到计数器值不为零会唤醒线程去争夺计数器。


> 使用

```Java
## 声明

//默认使用非公平锁
public Semaphore(int permits) {
    sync = new NonfairSync(permits);
}

//true：使用公平锁;false：使用非公平锁
public Semaphore(int permits, boolean fair) {
    sync = fair ? new FairSync(permits) : new NonfairSync(permits);
}
```

```Java
## 模板

Semaphore semaphore = new Semaphore(10,true);
semaphore.acquire();
//do something here
semaphore.release();
```

以下模拟多台打印机作业的并发使用

```Java
public static void main(String[] args) throws InterruptedException {
    PrinterQueue printerQueue = new PrinterQueue(3);

    List<Thread> threads = Stream
            .generate(() -> new Thread(new PrintJob(printerQueue)))
            .limit(5)
            .collect(Collectors.toList());

    threads.forEach(Thread::start);

    for (Thread thread : threads) {
        thread.join();
    }

}
```

```Java
private static class PrintJob implements Runnable {
    private PrinterQueue printerQueue;

    public PrintJob(PrinterQueue printerQueue) {
        this.printerQueue = printerQueue;
    }

    @Override
    public void run() {
        printerQueue.printJob(new Object());
    }
}
```

```Java
@Slf4j
private static class PrinterQueue {
    private Semaphore semaphore;

    /**
     * True: free
     * False: working
     */
    private boolean[] printers;

    private Semaphore printerLock;

    public PrinterQueue(int num) {
        this.semaphore = new Semaphore(num, true);
        this.printerLock = new Semaphore(1, true);
        this.printers = new boolean[num];
        for (int i = 0; i < num; i++) {
            printers[i] = true;
        }
    }

    public void printJob(Object document) {
        int assignPrinter = -1;
        try {
            semaphore.acquire();

            assignPrinter = getPrinter();

            int duration = RandomUtils.randomInt(100, 1000);
            log.debug("{}: Printer:{},Cost:{},Time::{}"
                    , Thread.currentThread().getName()
                    , assignPrinter
                    , duration + "ms"
                    , LocalDateTime.now());

            Thread.sleep(duration);

        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            log.debug("{}: The print job is done...", Thread.currentThread().getName());
            releasePrinter(assignPrinter);
            semaphore.release();
        }
    }

    private void releasePrinter(int printer) {
        try {
            printerLock.acquire();
            printers[printer] = true;
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            printerLock.release();
        }
    }


    private int getPrinter() {
        int assignPrinter = -1;
        try {
            printerLock.acquire();
            for (int i = 0; i < printers.length; i++) {
                if (printers[i]) {
                    assignPrinter = i;
                    printers[i] = false;
                    break;
                }
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            printerLock.release();
        }
        return assignPrinter;
    }
}

## 运行结果

Thread-1: Printer:1,Cost:267ms,Time:2018-12-05T21:45:11.233
Thread-0: Printer:0,Cost:340ms,Time:2018-12-05T21:45:11.233
Thread-2: Printer:2,Cost:377ms,Time:2018-12-05T21:45:11.233
Thread-1: The print job is done...
Thread-3: Printer:1,Cost:736ms,Time:2018-12-05T21:45:11.527
Thread-0: The print job is done...
Thread-4: Printer:0,Cost:717ms,Time:2018-12-05T21:45:11.593
Thread-2: The print job is done...
Thread-3: The print job is done...
Thread-4: The print job is done...

## 分析
5个线程Threod-0 -- Thread-4 竞争Printer1,Printer2,Printer3。
所有三个线程抢到资源后，其中一个Done了，下一个线程才能抢到。
```


> 参考链接

- [Control concurrent access to multiple copies of a resource using Semaphore](https://howtodoinjava.com/java/multi-threading/control-concurrent-access-to-multiple-copies-of-a-resource-using-semaphore/)
- [Java中Semaphore(信号量)的使用](https://blog.csdn.net/zbc1090549839/article/details/53389602)