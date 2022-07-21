---
title: "Spring 事务处理失效"
discriptions: "Spring 事务处理失效"
date: 2020-07-12T14:52:40+08:00
author: Pismery Liu
archives: "2020"
tags: [Java,Spring,Transaction]
categories: [Java]
showtoc: true
---

本文重点介绍 Spring 事务处理的几个失效的场景和相关解决方案；

<!--more-->

# Spring 事务处理失效

在日常业务开发过程中，事务处理在保证数据一致性起到了重要作用；而 Java 中常用 Spring 的声明式事务控制事务；即 Spring 注解 @Transaction；

Spring 的声明式事务依旧是 JDBC 的事务 API 上的封装实现；其通过 AOP 的方式对指定方法动态增强，为方法添加事务的功能；默认的 AOP 实现方式是动态代理；动态代理的实现方式有 JDK 代理和 CGLIB 代理，Spring 会根据指定条件判断使用哪种动态代理实现；大致实现如下：

```Java
public class DefaultAopProxyFactory implements AopProxyFactory, Serializable {

	@Override
	public AopProxy createAopProxy(AdvisedSupport config) throws AopConfigException {
		if (config.isOptimize() || config.isProxyTargetClass() || hasNoUserSuppliedProxyInterfaces(config)) {
			Class<?> targetClass = config.getTargetClass();
			if (targetClass == null) {
				throw new AopConfigException("TargetSource cannot determine target class: " +
						"Either an interface or a target is required for proxy creation.");
			}
			if (targetClass.isInterface() || Proxy.isProxyClass(targetClass)) {
				return new JdkDynamicAopProxy(config);
			}
			return new ObjenesisCglibAopProxy(config);
		}
		else {
			return new JdkDynamicAopProxy(config);
		}
	}

	/**
	 * Determine whether the supplied {@link AdvisedSupport} has only the
	 * {@link org.springframework.aop.SpringProxy} interface specified
	 * (or no proxy interfaces specified at all).
	 */
	private boolean hasNoUserSuppliedProxyInterfaces(AdvisedSupport config) {
		Class<?>[] ifcs = config.getProxiedInterfaces();
		return (ifcs.length == 0 || (ifcs.length == 1 && SpringProxy.class.isAssignableFrom(ifcs[0])));
	}

}
```

对于 AOP 方面有机会再另行讨论；我们回到主题，先总结一下，导致 Spring 事务处理异常的情况：

- 没有通过 Spring Bean 的方式调用事务方法；
- 在不使用 AspectJ 实现代理情况下，对非 public 方法进行 @Transaction 申明；
- 异常被 catch 没有抛出；
- 抛出的异常为 checked exception「受检异常」；
- 数据库本身不支持事务，如 MySQL 的 MyISAM 存储引擎；

下面逐一分析以上几种事务处理异常的情况；

## 没有通过 Spring Bean 的方式调用事务方法；

首先，先看看错误示例

```Java
@Service
public class PersonService {

    public void updatePerson() {
        doUpdatePerson();
    }

    @Transaction
    public void doUpdatePerson() {
        ....
    }
}
```

我们知道 Spring 是通过动态代理的方式实现声明式事务的；因此，要想对方法实现事务控制，必须通过 Spring 增强后的代理对象来调用方法；类内部方法自调用没有经过 Spring Bean 动态增强，最终方法 doUpdatePerson 没有事务控制；

解决方式也很简单，下面展示三种方式：

> 方式一

通过 Autowired 自身，再用 Autowied 进来的 Bean 来调用相应方法即可；

```Java
@Service
public class PersonService {
    @Autowired
    private PersonService self;

    public void updatePerson() {
        self.doUpdatePerson();
    }

    @Transaction
    public void doUpdatePerson() {
        ....
    }
}
```

> 方式二

将方法移动到另一个类中，再 Autowird 新的类，来调用

```Java
@Service
public class PersonService {
    @Autowired
    private PersonDoService doService;

    public void updatePerson() {
        doService.doUpdatePerson();
    }
}

@Service
public class PersonDoService {
    @Transaction
    public void doUpdatePerson() {
        ....
    }
}
```

> 方式三

通过 ApplicationContext 的 getBean 方法获取增强代理对象；

```Java
@Service
public class PersonService {
    @Autowired
    private ApplicationContext ctx;

    public void updatePerson() {
        PersonService self = (PersonService) ctx.getBean("personService");
        self.doUpdatePerson();
    }

    @Transaction
    public void doUpdatePerson() {
        ....
    }
}
```



日常开发过程中，建议使用方式二；方式一的实现方式，一方面对于不了解 Spring 事务的同事，可能会十分疑惑这样的设计；另一方面其还可能引入循环依赖的问题；

下面我们看看会导致循环依赖问题的示例：

```Java
@Service
public class PersonService {
    @Autowired
    private PersonService self;

    public void updatePerson() {
        self.doUpdatePerson();
    }

    @Transaction
    @Aync
    public void doUpdatePerson() {
        ....
    }
}
```

示例很简单，只是在原来的基础上加上了注解 @Async，来实现方法异步的增强；此时启动 Spring 容器将会启动异常，错误信息如下：

```
org.springframework.beans.factory.BeanCurrentlyInCreationException: Error creating bean with name 'personService': 
Bean with name 'personService' has been injected into other beans [personService] in its raw version as part of a circular reference, 
but has eventually been wrapped. This means that said other beans do not use the final version of the bean. 
This is often the result of over-eager type matching - consider using 'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.
```

错误信息意思是，初始化 personService 时，此对象已经注入 personService 注入，形成了循环依赖；解决方式也很简单，通过 @Lazy 注解实现延迟加载即可；实现如下：

```Java
@Service
public class PersonService {
    @Autowired
    @Lazy
    private PersonService self;

    public void updatePerson() {
        self.doUpdatePerson();
    }

    @Transaction
    @Aync
    public void doUpdatePerson() {
        ....
    }
}
```

## 在不使用 AspectJ 实现代理情况下，对非 public 方法进行 @Transaction 申明

错误示例如下：

```Java
@Service
public class PersonService {
    @Autowired
    private PersonService self;

    public void updatePerson() {
        self.doUpdatePerson1();
        self.doUpdatePerson2();
        self.doUpdatePerson3();
    }

    @Transaction
    protected void doUpdatePerson1() {
        ....
    }

    @Transaction
    default void doUpdatePerson2() {
        ....
    }

    @Transaction
    private void doUpdatePerson3() {
        ....
    }
}
```

解决方式：将事务方法设置为 public 方法；

##  异常被 catch 没有抛出

方法出现异常，本希望事务进行回滚操作，但是以下代码却发现，事务未回滚，正常提交；

```Java
@Service
public class PersonService {
    @Transaction
    public void updatePerson() {
        try {
            doUpdatePerson();
        } catch(Exception e) {
            log(e);
        }
    }

    private void doUpdatePerson() {
        ....
        throw new RunTimeExcpetion();
    }

}
```

Spring 处理事务逻辑如下：

```Java
try {
   // This is an around advice: Invoke the next interceptor in the chain.
   // This will normally result in a target object being invoked.
   retVal = invocation.proceedWithInvocation();
}
catch (Throwable ex) {
   // target invocation exception
   completeTransactionAfterThrowing(txInfo, ex);
   throw ex;
}
finally {
   cleanupTransactionInfo(txInfo);
}
```

只有当 Spring 捕获到了异常，才能够执行 completeTransactionAfterThrowing 方法进行事务回滚；因此，当我们方法将异常捕获后，没有抛出则不会进行事务回滚；

解决方案如下：

```Java
@Service
public class PersonService {
    @Transaction
    public void updatePerson() {
        try {
            doUpdatePerson();
        } catch(Exception e) {
            log(e);
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
        }
    }

    private void doUpdatePerson() {
        ....
        throw new RunTimeExcpetion();
    }

}
```

通过 TransactionAspectSupport.currentTransactionStatus().setRollbackOnly() 显示设置 RollbackOnly，使得事务进行回滚

##  抛出的异常为 checked exception「受检异常」

有时候我们抛出了异常，但是事务还是没有回滚，下面我们看看示例：

```Java
@Service
public class PersonService {
    @Transaction
    public void updatePerson() throws IOException{
        doUpdatePerson();
    }

    private void doUpdatePerson() throws IOException{
        ....
        readFile();
    }

}
```

当读取文件时，会抛出一个受检异常 IOException；但是 Spring 默认情况下，出现 RuntimeException（非受检异常）或 Error 的时候，Spring 才会回滚事务。

Spring 官方解释是受检异常一般是业务异常或者是另一种方法返回值，出现这样的异常，业务可能还能完成，因此不会主动回滚；而 Error 或 RuntimeException 代表了非预期的结果，应该回滚；

解决方案:

> 方式一

如果希望自己处理异常，但仍要回滚事务；

```Java
@Service
public class PersonService {
    @Transaction
    public void updatePerson(){
        try {
            doUpdatePerson();
        } catch(Exception e) {
            log(e);
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
        }
    }

    private void doUpdatePerson() throws IOException{
        ....
        readFile();
    }

}
```

> 方式二

使用 rollbackFor 指定需要回滚的异常；

```Java
@Service
public class PersonService {
    @Transaction(rollbackFor = Exception.class)
    public void updatePerson() throws IOException{
        doUpdatePerson();
    }

    private void doUpdatePerson() throws IOException{
        ....
        readFile();
    }

}
```

##  数据库本身不支持事务，如 MySQL 的 MyISAM 存储引擎

这种情况解决方案就更换 MySQL 存储引擎为 InnoDB；

# 参考资料

- 「极客时间」Java业务开发常见错误100例 之 06 | 20%的业务代码的Spring声明式事务，可能都没处理正确
- 「极客时间」每日一课 之 内部方法调用时，为什么Spring AOP增强不生效？
