---
title: "并发编程之 Atomic 原子类"
discriptions: "并发编程之 Atomic 原子类"
date: 2019-01-26T20:28:19+08:00
author: Pismery Liu
archives: "2019"
tags: [concurrent,Java]
categories: [Java]
showtoc: true
---

J.U.C Atomic 类通过 CAS 实现原子性操作。

<!--more-->

# Atomic 原子类

Atomic 原子类能够保证在多线程下的原子性。其内部是通过 CAS 机制实现的原子性操作。Atomic 原子类可以分为以下几类：

- 基本类型：AtomicInteger，AtomicLong，AtomicBoolean
- 数组类型：AtomicIntegerArray，AtomicLongArray，AtomicReferenceArray 
- 引用类型：AtomicReference，AtomicStampedRerence，AtomicMarkableReference 
- 更新器类：AtomicIntegerFieldUpdater、AtomicLongFieldUpdater、AtomicReferenceFieldUpdater
- Java8 新增类：DoubleAccumulator，DoubleAdder，LongAccumulator，LongAdder


## 基本类型


> 基本方法

```Java
public final int get() //获取当前的值
public final int getAndSet(int newValue)//获取当前的值，并设置新的值
public final int getAndIncrement()//获取当前的值，并自增
public final int getAndDecrement() //获取当前的值，并自减
public final int getAndAdd(int delta) //获取当前的值，并加上预期的值
boolean compareAndSet(int expect, int update) //如果输入的数值等于预期值，则以原子方式将该值设置为输入值（update）
```

> accumulateAndGet 方法

```Java
//x：表示 IntBinaryOperator 中第二个参数right，IntBinaryOperator 的返回值即最终结果值
public final int accumulateAndGet(int x, IntBinaryOperator accumulatorFunction) 

@FunctionalInterface
public interface IntBinaryOperator {
    int applyAsInt(int left, int right);
}
```
accumulateAndGet 是 Java8 新增的方法，其中 IntBinaryOperator 是函数式接口。

使用示例如下

```
public static void main(String[] args){
    //integer初始化为0
    AtomicInteger integer = new AtomicInteger();
    //0 + 2 = 2
    integer.accumulateAndGet(2,(old,x)-> old + x);
    System.out.println(integer.get());
}

##结果
2
```

> lazySet 方法

```Java
public final void set(int newValue)//设置新值
public final void lazySet(int newValue)//最终设置为newValue,使用 lazySet 设置之后可能导致其他线程在之后的一小段时间内还是可以读到旧的值。
```

首先，我们知道 volatile 底层通过内存屏障保证了数据的可见性。

1. 修改 volatile 变量保证立即从工作内存刷新至主存；
2. 读取 volatile 变量则使工作内存缓存失效，获取主内存数据；
3. 通过内存屏障防止指令重排序；

lazySet 方法修改值不会立即可见。主要用于底层代码的优化手段，其原理是通过减少内存屏障来提升性能。

Atomic类中的 set 方法中使用的变量就是 volatile 变量，从而实现修改后其他线程立即可见；volatile 变量写操作会加入 StoreLoad 和 StoreStore，而内存屏障也是一个消耗性能的操作，使用 lazySet 方法能够省去 StoreLoad 这个屏障，从而提升性能。

使用场景：

1. 在使用 lock 与 unlock 方法中间的共享变量可以不使用 volatile 变量，又或者说不需要立即可见，因为 lock，unlock 本身也有内存屏障保证可见性的功能，此时可以通过 lazyset 方式修改共享变量减少屏障的产生，提升性能。

> 示例

```Java
public class AtomicIntegerDemo {

    public static void main(String[] args) throws InterruptedException {
        AtomicInteger integer = new AtomicInteger();

        NormalIncrement normalIncrement = new NormalIncrement(0);

        ExecutorService threadPool = Executors.newFixedThreadPool(5);
        for (int i = 0; i < 1000; i++) {
            threadPool.submit(normalIncrement);
            threadPool.submit(integer::getAndIncrement);
        }


        Thread.sleep(1000);
        threadPool.shutdown();
        System.out.println("normalIncrement result:" + normalIncrement.getInteger());
        System.out.println("atomicIncrement result:" + integer.get());
    }


    @AllArgsConstructor
    @Getter
    static class NormalIncrement implements Runnable {
        private volatile Integer integer;

        @Override
        public void run() {
            integer = integer + 1;
        }
    }

}

//运行结果
normalIncrement result:993
atomicIncrement result:1000
```

从结果可以分析出 volatile 变量无法保证自增操作的原子性，而 Atomic 类则可以通过 CAS 的机制保证其原子性，不过仍存在 ABA 问题。

## 数组类型

与基本类型操作相似，就是方法的参数都多了一个 index 参数，指明数组中的哪一个值进行原子操作。

> 示例

```Java
public class AtomicArrayDemo {

    public static void main(String[] args) {
        AtomicIntegerArray atomicIntegerArray = new AtomicIntegerArray(
                new int[]{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
        );

        for (int i = 0; i < 10; i++) {
            atomicIntegerArray.accumulateAndGet(i, 10, (y, x) -> x+y);
            System.out.println("int[" + i + "]:" + atomicIntegerArray.get(i));
        }
    }
}

## 运行结果
int[0]:10
int[1]:11
int[2]:12
int[3]:13
int[4]:14
int[5]:15
int[6]:16
int[7]:17
int[8]:18
int[9]:19
```

```Java
public class AtomicIntegerArrayDemo

	public static void main(String[] args) {
		int temvalue = 0;
		int[] nums = { 1, 2, 3, 4, 5, 6 };
		AtomicIntegerArray i = new AtomicIntegerArray(nums);
		
		temvalue = i.getAndSet(0, 2);
		System.out.println("temvalue:" + temvalue + ";  i:" + i);
		temvalue = i.getAndIncrement(0);
		System.out.println("temvalue:" + temvalue + ";  i:" + i);
		temvalue = i.getAndAdd(0, 5);
		System.out.println("temvalue:" + temvalue + ";  i:" + i);
	}

}

## 运行结果
temvalue:1;  i:[2, 2, 3, 4, 5, 6]
temvalue:2;  i:[3, 2, 3, 4, 5, 6]
temvalue:3;  i:[8, 2, 3, 4, 5, 6]
```

## 引用类型

引用类型有以下三个类

- AtomicReference: 引用类型原子类
- AtomicStampedRerence: 带有版本号的引用类型原子类
- AtomicMarkableReference: 带有标记的引用类型原子类

可以把 AtomicMarkableReference 当作只有两个版本号的 AtomicStampedRerence

> 示例

```Java
//AtomicStampedRerence
public class AtomicStampedReferenceDemo {

    public static void main(String[] args) throws InterruptedException {
        AtomicStampedReference<Integer> atomicStampedReference = new AtomicStampedReference<>(0, 0);

        ExecutorService threadPool = Executors.newFixedThreadPool(5);
        for (int i = 0; i < 1000; i++) {
            threadPool.submit(() -> {
                for (; ; ) {//自旋操作
                    int stamp = atomicStampedReference.getStamp();
                    Integer value = atomicStampedReference.getReference();
                    if (atomicStampedReference.compareAndSet(value, new Integer(value + 1), stamp, stamp + 1))
                        break;
                }
            });
        }
        threadPool.shutdown();
        threadPool.awaitTermination(1, TimeUnit.DAYS);
        System.out.println("atomicIncrement reference:" + atomicStampedReference.getReference());
        System.out.println("atomicIncrement stamp:" + atomicStampedReference.getStamp());

    }
}

## 运行结果
atomicIncrement reference:1000
atomicIncrement stamp:1000
```

## 更新器类

更新器类能够原子性的操作对象的成员变量，内部原理是通过反射和 CAS 实现的。

- AtomicIntegerFieldUpdater
- AtomicLongFieldUpdater
- AtomicReferenceFieldUpdater

使用 Updater 方式：

1. 更新器类成员属性要声明为 staic final
2. 目标操作对象的成员变量必须为 volatile
3. AtomicIntegerFieldUpdater 操作目标要为 int 类型，不能是 Integer 类型；要操作 Integer 类型，则使用 AtomicReferenceFieldUpdater

> 示例

```Java
@Slf4j
public class AtomicFieldUpdaterDemo implements Runnable {
    private static final AtomicIntegerFieldUpdater<AtomicFieldUpdaterDemo> intUpdater
            = AtomicIntegerFieldUpdater.newUpdater(AtomicFieldUpdaterDemo.class, "i");
    private static final AtomicLongFieldUpdater<AtomicFieldUpdaterDemo> longUpdater
            = AtomicLongFieldUpdater.newUpdater(AtomicFieldUpdaterDemo.class, "l");
    private static final AtomicReferenceFieldUpdater<AtomicFieldUpdaterDemo, Integer> refUpdater
            = AtomicReferenceFieldUpdater.newUpdater(AtomicFieldUpdaterDemo.class, Integer.class, "integer");

    private volatile int i = 0;
    private volatile long l = 0;
    private volatile Integer integer = 0;


    public static void main(String[] args) throws InterruptedException {
        ExecutorService executorService = Executors.newFixedThreadPool(5);
        AtomicFieldUpdaterDemo demo = new AtomicFieldUpdaterDemo();

        IntStream.range(0, 10).forEach(i -> executorService.submit(demo));

        Thread.sleep(1000L);
        executorService.shutdown();

        demo.getResult();
    }

    public void getResult() {
        log.debug("Result int :" + i);
        log.debug("Result long :" + l);
        log.debug("Result Integer :" + integer);
    }

    @Override
    public void run() {
        intUpdater.incrementAndGet(this);
        longUpdater.incrementAndGet(this);
        refUpdater.updateAndGet(this, (integer) -> integer + 1);
    }
}

// 运行结果
AtomicFieldUpdaterDemo - Result int :10
AtomicFieldUpdaterDemo - Result long :10
AtomicFieldUpdaterDemo - Result Integer :10
```

## Java8 新增类

### Adder 类

Java8 中，在 J.U.C 中 atomic 包下新增了类 DoubleAdder, LongAdder，与 AtomicLong 一样，使用了 CAS 机制来确保操作的原子性；在性能方面会比 Atomic 类更加高；「ps：Java8 中不存在 IntegerAdder」

首先，我们知道在高并发的情况下，CAS 机制容易出现更新失败，自旋的可能性大大增高；而 Adder 类采用「热点分离」解决了这个问题；

「热点分离」：将一个值拆分为几份 cell，不同的线程通过操作不同 cell 实现值的原子操作；这样就实现了多线程操作更新不同的值，大大减少的碰撞的发生；举个例子：线程 A，B 对值 8 进行自增操作，将 8 拆分为 5 和 3 两个 cell 从而，线程 A 自增 5，线程 B 自增 3，最终结果在合并为 10；同样实现了多线程下的原子性操作；「ps：Adder 类没有乘法除法操作」

但是，在并发不是很高的情况下，若还需要将值拆分为 cell 再合并为最后结果，这将导致效率方面不如 Atomic 类；为了减少这样的消耗，Adder 类采用了「自适应」来解决这个问题；

「自适应」：初始情况下，操作与 Atomic 类一样，不会拆分为 cell；发生 CAS 碰撞，才会拆分为 cell，每次碰撞都会增加 cell 个数；这样就实现了，在低并发的情况下，性能与 Atomic 类差距不大；在高并发时，只要 cell 个数足够多时，将不会发生碰撞，大大提高效率；

> 示例

```Java
@Slf4j
public class AdderDemo implements Runnable{
    LongAdder longAdder = new LongAdder();
    DoubleAdder doubleAdder = new DoubleAdder();

    @Override
    public void run() {
        longAdder.increment();
        doubleAdder.add(1D);
    }

    private void getResult() {
        log.debug("Result longAdder:" + longAdder);
        log.debug("Result doubleAdder:" + doubleAdder);
    }

    public static void main(String[] args) throws InterruptedException {
        ExecutorService executorService = Executors.newFixedThreadPool(100);
        AdderDemo adderDemo = new AdderDemo();

        IntStream.range(0,1000).forEach(i -> executorService.submit(adderDemo));

        Thread.sleep(1000L);
        executorService.shutdown();
        adderDemo.getResult();
    }
}

## result
AdderDemo - Result longAdder:1000
AdderDemo - Result doubleAdder:1000.0
```

### Accumulator 类

Accumulator 类相当于是 Adder 类的加强版，Adder 类中只能做简单的加减法，并且初始值都是 0；而 Accumenlator 类能够设置初始值和计算方式；

下面是 LongAccumulator 类中的构造函数源码实现

```Java
//构造函数
public LongAccumulator(LongBinaryOperator accumulatorFunction,
                       long identity) {
    this.function = accumulatorFunction;
    base = this.identity = identity;
}

// LongBinaryOperator 定义
@FunctionalInterface
public interface LongBinaryOperator {

    /**
     * Applies this operator to the given operands.
     *
     * @param left the first operand
     * @param right the second operand
     * @return the operator result
     */
    long applyAsLong(long left, long right);
}
```

参数：

- LongBinaryOperator： 定义计算的方式
- identity： 设置初始值；

> 示例

计算由 10 个线程产生的 [0,2000) 之间的数的最大值；

```Java
@Slf4j
public class AccumulatorDemo {
    public static void main(String[] args) throws InterruptedException {
        LongAccumulator accumulator = new LongAccumulator(Long::max, Long.MIN_VALUE);
        ExecutorService executorService = Executors.newFixedThreadPool(10);

        IntStream.range(0, 10).forEach(i -> executorService.submit(() -> {
            Random random = new Random();
            long value = J8RandomUtils.randomInt(0, 2000);
            log.debug("Random value: " + value);
            accumulator.accumulate(value);
        }));

        Thread.sleep(1000L);
        executorService.shutdown();

        log.debug("Max value: " + accumulator.longValue());
    }
}


//结果
AccumulatorDemo - Random value: 1557
AccumulatorDemo - Random value: 1970
AccumulatorDemo - Random value: 1582
AccumulatorDemo - Random value: 632
AccumulatorDemo - Random value: 1422
AccumulatorDemo - Random value: 1701
AccumulatorDemo - Random value: 1409
AccumulatorDemo - Random value: 275
AccumulatorDemo - Random value: 1149
AccumulatorDemo - Random value: 44
AccumulatorDemo - Max value: 1970
```


# 参考链接

- [Java JUC 之 Atomic 系列 12 大类实例讲解和原理分解](https://blog.csdn.net/xh16319/article/details/17056767)
- [Atomic 原子类介绍
](https://github.com/Snailclimb/JavaGuide/blob/master/Java%E7%9B%B8%E5%85%B3/Multithread/Atomic.md) 
- [Java 8 并发教程：原子变量和 ConcurrentMap](https://segmentfault.com/a/1190000006051340)
- [LongAdder and LongAccumulator in Java](https://www.baeldung.com/java-longadder-and-longaccumulator)