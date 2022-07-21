---
title: "并发编程之并发工具类-CountDownLatch"
discriptions: "并发编程之并发工具类-    CountDownLatch"
date: 2018-12-21T21:04:54+08:00
author: Pismery Liu
archives: "2018"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---

同步工具类 CountDownLatch 实现一个或多个线程阻塞等待其他他线程完成操作。

<!--more-->

# CountDownLatch

> 什么是 CountDownLatch

在 Java5 中 concurrent 包出现了一组解决多线程的工具类如 CountDownLatch、CyclicBarrier、BlockingQueue。本文介绍的CountDownLatch是一种同步工具类，实现一个或多个线程阻塞等待直到其他线程完成一系列操作的功能。

> CountDownLatch 如何工作

CountDownLatch 只有一个构造函数

```Java
public CountDownLatch(int count) {
    if (count < 0) throw new IllegalArgumentException("count < 0");
    this.sync = new Sync(count);
}
```

count 表示需要等待的线程数目，这个值只能被设置一次，构造出来后，不能够再重新设置这个计数值。

主线程在启动其他线程执行任务后，需要立刻调用 CountDownLatch 中 await() 方法，阻塞等待 CountDownLatch 中计数器的值为 0；

每当一个线程执行完毕，调用 CountDownLatch 中的 countDown 方法将计数器的值减一，所以每个线程需要维护一个 CountDownLatch 的引用。当计数器值为0表示所有线程执行完毕，主线程再继续向下运行。


> 应用场景

1. 需要线程需要等待其他多个线程执行完毕才开始执行，如:程序启动时，确保所有的子系统都启动成功才开始处理用户请求。


> 使用示例

模拟了一个应用程序启动类，它开始时启动了 n 个线程类，这些线程将检查外部系统并完成后调用 countDown 方法，并且启动类一直在阻塞等待着。一旦验证和检查了所有外部服务，那么启动类恢复执行。

```Java
public class CountDownLatchDemo {

    public static void main(String[] args) throws InterruptedException {
        System.out.println("Application is starting...");
        CountDownLatch latch = new CountDownLatch(3);

        ExecutorService executorService = Executors.newFixedThreadPool(3);

        executorService.submit(new NetworkHealthCheck(latch, "Network"));
        executorService.submit(new CacheHealthCheck(latch, "Cache"));
        executorService.submit(new DatabaseHealthCheck(latch, "Database"));

        latch.await();
        executorService.shutdown();
        System.out.println("Application is up");
    }


    private static class NetworkHealthCheck extends BasicHealthChecker {
        public NetworkHealthCheck(CountDownLatch lock, String serviceName) {
            super(lock, serviceName);
        }

        @Override
        protected void verifyService() {
            try {
                System.out.println("Network is checking...");
                Thread.sleep(500L);
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                System.out.println("Network is up...");
            }
        }
    }

    private static class CacheHealthCheck extends BasicHealthChecker {
        public CacheHealthCheck(CountDownLatch lock, String serviceName) {
            super(lock, serviceName);
        }


        @Override
        protected void verifyService() {
            try {
                System.out.println("Cache is checking...");
                Thread.sleep(100L);
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                System.out.println("Cache is up...");
            }
        }
    }


    private static class DatabaseHealthCheck extends BasicHealthChecker {
        public DatabaseHealthCheck(CountDownLatch lock, String serviceName) {
            super(lock, serviceName);
        }

        @Override
        protected void verifyService() {
            try {
                System.out.println("Database is checking...");
                Thread.sleep(200L);
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                System.out.println("Database is up...");
            }
        }
    }

    private static abstract class BasicHealthChecker implements Callable<Boolean> {

        private CountDownLatch lock;
        private String serviceName;

        public BasicHealthChecker(CountDownLatch lock, String serviceName) {
            this.lock = lock;
            this.serviceName = serviceName;
        }

        @Override
        public Boolean call() {
            try {
                verifyService();
                return true;
            } catch (Exception e) {
                return false;
            } finally {
                System.out.println(serviceName + " is checked");
                if (lock != null) {
                    lock.countDown();
                }
            }
        }


        protected abstract void verifyService();
    }

}

## 运行结果
Application is starting...
Cache is checking...
Network is checking...
Database is checking...
Cache is up...
Cache is checked
Database is up...
Database is checked
Network is up...
Network is checked
Application is up
```


> 参考连接

- [什么时候使用 CountDownLatch ](http://www.importnew.com/15731.html)
- [Java concurrency – CountDownLatch Example](https://howtodoinjava.com/java/multi-threading/when-to-use-countdownlatch-java-concurrency-example-tutorial/)