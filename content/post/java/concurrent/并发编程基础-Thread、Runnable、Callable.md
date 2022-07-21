---
title: "并发编程基础-Thread、Runnable、Callable"
discriptions: "并发编程基础-Thread、Runnable、Callable"
date: 2018-11-29T21:57:58+08:00
author: Pismery Liu
archives: "2018"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---
<!--more-->

# Thread vs Runnable

> 示例代码

```
public class Demo extend Thread {
    public Demo() {
        super("Demo-Thread");
    }
    
    public void run() {
        //Code
    }
    
    public static void main(String[] args) {
        new Demo().start();
    }
}


public class Demo implements Runnable {
    public void run() {
        //Code
    }
    
    public static void main(String[] args) {
        new Thread(new Demo()).start();
    }
}
```

> 比较

1. 通过实现Runnable接口更好，在Java中只允许单继承，因此若继承了Thread则不能再继承其他类
2. 在多线程中，继承Thread的方式内存使用量更多，每个线程都包含一个与它关联的唯一对象，而实现Runnable接口，内存使用会更少。因为，许多线程可以共享相同的可运行实例。


# Callable、Future、Excutor

> Callable

Callable是一个接口，里面包含call方法，可以将线程的逻辑写在call方法里。相对于继承Thread和实现Runnable接口实现多线程，实现Callable接口的方式能够获取线程的返回值，并且可以通过Future来控制它的状态

```
@FunctionalInterface
public interface Callable<V> {
    /**
     * Computes a result, or throws an exception if unable to do so.
     *
     * @return computed result
     * @throws Exception if unable to compute a result
     */
    V call() throws Exception;
}
```

> Future

Future是接口，它拥有一组方法能够获取Callable对象并且管理它的状态的。

```
public interface Future<V> {

    boolean cancel(boolean mayInterruptIfRunning);
    boolean isCancelled();
    boolean isDone();

    V get() throws InterruptedException, ExecutionException;
    V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}
```

> 示例

```
@Slf4j
public class CallableDemo implements Callable<Integer> {

    private Integer number;

    public CallableDemo(Integer number) {
        this.number = number;
    }

    @Override
    public Integer call() throws Exception {
        int result = 1;
        if ((number == 0) || (number == 1)) {
            result = 1;
        } else {
            for (int i = 2; i <= number; i++) {
                result *= i;
                TimeUnit.MILLISECONDS.sleep(200);
            }
        }
        log.debug("Result for number - " + number + " -> " + result);
        return result;
    }

    public static void main(String[] args) throws ExecutionException, InterruptedException {
        ExecutorService executor = Executors.newFixedThreadPool(2);

        List<Future<Integer>> futureList = new ArrayList<>();

        for (int i = 0; i < 4; i++) {
            CallableDemo callableDemo = new CallableDemo(RandomUtils.randomInt(1,10));
            futureList.add(executor.submit(callableDemo));
        }

        futureList.forEach(integerFuture -> {
            try {
                log.debug("Future is done 1 - " + integerFuture.isDone());
                log.debug("Future result is - " + integerFuture.get());
                log.debug("Future is done 2- " + integerFuture.isDone());
            } catch (InterruptedException | ExecutionException e) {
                e.printStackTrace();
            }
        });

        executor.shutdown();
    }
}

```

> 运行结果

```
[main] DEBUG CallableDemo - Future is done 1 - false
[pool-1-thread-1] DEBUG CallableDemo - Result for number - 7 -> 5040
[main] DEBUG CallableDemo - Future result is - 5040
[main] DEBUG CallableDemo - Future is done 2 - true
[main] DEBUG CallableDemo - Future is done 1 - false
[pool-1-thread-2] DEBUG CallableDemo - Result for number - 8 -> 40320
[main] DEBUG CallableDemo - Future result is - 40320
[main] DEBUG CallableDemo - Future is done 2 - true
[main] DEBUG CallableDemo - Future is done 1 - false
[pool-1-thread-2] DEBUG CallableDemo - Result for number - 4 -> 24
[pool-1-thread-1] DEBUG CallableDemo - Result for number - 9 -> 362880
[main] DEBUG CallableDemo - Future result is - 362880
[main] DEBUG CallableDemo - Future is done 2 - true
[main] DEBUG CallableDemo - Future is done 1 - true
[main] DEBUG CallableDemo - Future result is - 24
[main] DEBUG CallableDemo - Future is done 2 - true

```

> 分析

当get方法调用完后，Future一定是Done状态，所以Future is done 2"均为true；"Future is done 1"看是否再调用get方法前是否执行完，所以可能true也可能false。

> 总结

Future接口方法有以下作用：

1. 能够控制多线程任务的状态：通过cancel方法停止任务，通过isDone方法判断任务是否完成.
2. 能够获取多线程任务的返回值：通过get方法获取call()方法的返回值,get方法是一个阻塞的方法，调用此方法会等待直到Callable对象执行完call方法，然后返回call方法的返回值。若get方法等待过程中，线程被打断，get方法抛出InterruptedException异常；若call方法抛出异常，get方法抛出ExecutionException异常。
3. get方法有另一个重载方法get(long timeout, TimeUnit unit),只等待指定时间若call方法没有执行完毕则返回null。
     