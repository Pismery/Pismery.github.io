---
title: "初识Try Finally"
discriptions: "初识Try Finally"
date: 2019-02-17T11:35:32+08:00
author: Pismery Liu
archives: "2019"
tags: [Java,basic]
categories: [Java]
showtoc: true
---

一文了解 Try Finally 执行顺序。

<!--more-->

# Try catch finally

> 示例程序

```Java
public class TryFinallyDemo {
    public int field = 0;

    public int test() {
        int i1 = 0;
        try {
            ++field;
            return ++i1;
        } finally {
            ++field;
            ++i1;
        }
    }

    public static void main(String[] args) {
        TryFinallyDemo tryFinallyDemo = new TryFinallyDemo();
        System.out.println("test result:"+ tryFinallyDemo.test());
        System.out.println("tryFinallyDemo.field:"+ tryFinallyDemo.field);
    }

}

## 结果
test result:1
tryFinallyDemo.field:2
```

基本认知: 

- return 语句执行了方法就结束返回了
- finally 语句在无论try发生什么都会执行

因此，下意识认为 try 里面有 return 则先执行 finally 再执行 return ，执行了两次 ++i，应该返回 2，而结果出乎预料的是 1。从最终结果发现似乎是先 return 再执行 finally 语句块的。

查看[Java 官方文档](https://docs.oracle.com/javase/tutorial/essential/exceptions/finally.html)是这么说明 finally 语句块。

The finally block always executes when the try block exits. This ensures that the finally block is executed even if an unexpected exception occurs. But finally is useful for more than just exception handling — it allows the programmer to avoid having cleanup code accidentally bypassed by a return, continue, or break. Putting cleanup code in a finally block is always a good practice, even when no exceptions are anticipated.

> Note: If the JVM exits while the try or catch code is being executed, then the finally block may not execute. Likewise, if the thread executing the try or catch code is interrupted or killed, the finally block may not execute even though the application as a whole continues.

简单来说就是。finally 语句块保证在 try 块结束退出时执行。就算 try 块使用了 return, continue, break 来退出语句块，也会保证执行。并且建议我们对于资源的关闭都使用 finally 语句块来确保执行，尽管没有任何可捕获的异常。

> 注意：存在 try, catch 语句块执行了，finally 语句块未被执行的情况，如 JVM 直接退出「System.exit()」或者一个线程执行 try, catch 语句块时突然被直接 interrupt 或者 killed，这样即使整个程序仍在执行，还是不会再执行 finally 语句块。

通过测试程序运行结果，初步分析出先执行了 return 语句再执行 finally 语句块，然而，这也不符合 return 的语义了。经过 debug 发现，在方法退出前，i2 已经自增到 2 最后确返回 1，这也不符合 debug 的结果。

通过翻看[官方的jvm规范](https://docs.oracle.com/javase/specs/jvms/se7/html/jvms-4.html#jvms-4.10.2.5)，就能够知道其真正的执行流程：

> If the try clause executes a return, the compiled code does the following:

> 1. Saves the return value (if any) in a local variable.
> 2. Executes a jsr to the code for the finally clause.
> 3. Upon return from the finally clause, returns the value saved in the local variable.

> If an exception is thrown in the try clause, this exception handler does the following:

> 1. Saves the exception in a local variable.
> 2. Executes a jsr to the finally clause.
> 3. Upon return from the finally clause, rethrows the 


简单来说：

- 如果 try 里面有 return 语句则先执行 return 语句并将结果保存在本地局部变量表，然后执行 finally 语句块,最后返回执行 return 语句保存在局部变量的值。
- 如果 try 语句块发生异常则将异常保存在本地局部变量表，执行 finally 语句块，最后返回异常。
- 补充：当 try 语句有 return 语句 finally 也有 return 语句则会忽略 try 语句中的 return 语句。

> 补充

try catch 语句块在没有抛出异常的情况下是不影响性能的，若出现异常则会导致几百倍的性能影响。所以不要通过异常来判断业务逻辑，这样严重影响性能。