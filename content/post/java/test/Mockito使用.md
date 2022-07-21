---
title: "Mockito使用"
discriptions: "Mockito使用"
date: 2018-11-14T20:05:35+08:00
author: Pismery Liu
archives: "2018"
tags: [测试,Java]
categories: [Java]
showtoc: true
---
<!--more-->

# Mockito

## 初始化注解

> 背景

使用@Mock,@spy,@InjectMock等注解需要先初始化才能使用。


> 1. 在测试类上使用@RunWith(MockitoJUnitRunner.class)注解。

```
@RunWith(MockitoJUnitRunner.class)
public class XxxTest {
}
```

> 2. 在测试方法调用前使用MockitoAnnotations.initMocks(this);

```
public class XxxTest {
    @Before
    public void initMocks(){
        MockitoAnnotations.initMocks(this);
    } 
}
```

> 3. 在测试类中使用MockitoRule

```
public class XxxTest {
    @Rule
    public MockitoRule rule = MockitoJUnit.rule();
}
public class XxxTest {
    //严格模式
    @Rule
    public MockitoRule rule = MockitoJUnit.rule().strictness(Strictness.STRICT_STUBS);
}
```
## Mock and Spy 训练

```
## Mock 训练

Object mock = Mock(new List);
when(mock.method).thenReturn();

## Spy 训练
List list = new LinkedList();
List spy = spy(list);

//Impossible: real method is called so spy.get(0) throws IndexOutOfBoundsException (the list is yet empty)
when(spy.get(0)).thenReturn("foo");

//You have to use doReturn() for stubbing
doReturn("foo").when(spy).get(0);
```
## @InjectMock
> 注入方式: 优先级：1>2>3

    1. 构造器注入
    2. set方法注入
    3. 属性注入

> 注入过程

    1. 找最长的构造器注入，如果不符合直接找空构造器;
    2. 如果空构造器不存在，则注入失败报exception;
    3. 如果空构造器存在，则通过set方法注入;
    4. 如果set方法不存在，则通过属性注入;

> 注意事项

    1. 如果通过构造器注入,则只按类型注入。@Mock()中name属性无效，且后声明的覆盖前声明的。
    2. 如果最长构造器不合则直接找空构造器，不会找最符合的构造器
    3. 如果通过set方法或属性注入，若有重复类型的属性。
        1. 只有一个@Mock且不指定name属性，则按注入类中的注入目标的变量名的比较小的优先注入。
        2. 若有多个@Mock且不指定name属性, 则默认按变量名为name
        注入,若找不到则报exception。
        3. 如果存在相同类型需要注入则最好设置好@Mock的name属性。

> mock static field
    
    1. 通过构造函数注入。**

### examples
```
public class InjectMockTest {
	
	@Mock private ArticleCalculator calculator;
    @Mock(name = "database") private ArticleDatabase dbMock; // note the mock name attribute
    
    @InjectMocks private ArticleManager manager;
    @Before public void initMocks() {
        MockitoAnnotations.initMocks(this);
    }
    
    @Test 
    public void shouldDoSomething() {
    	when(calculator.calculator()).thenReturn("mock calculator");
    	when(dbMock.select()).thenReturn("mock ArticleDatabase");
    	
        manager.initiateArticle();
    }
	
}

public class ArticleCalculator {
	public String calculator() {
		System.out.println("ArticleCalculator.calculator");
		return "ArticleCalculator.calculator";
	}
}

public class ArticleDatabase {
	public String select() {
		System.out.println("ArticleDatabase.select");
		return "ArticleDatabase.select";
	}
}
```

#### 构造注入
```
public class ArticleManager {
	private ArticleCalculator calculator;
	private ArticleDatabase database;

	public ArticleManager(ArticleCalculator calculator, ArticleDatabase database) {
		super();
		this.calculator = calculator;
		this.database = database;
	}
	
	public void initiateArticle() {
		System.out.println(calculator.calculator());
		System.out.println(database.select());
	}
}
```
#### set方法注入
```
public class ArticleManager {
	private ArticleCalculator calculator;
	private ArticleDatabase database;

	public ArticleManager() {
	}
	
	public void setCalculator(ArticleCalculator calculator) {
		this.calculator = calculator;
	}

	public void setDatabase(ArticleDatabase database) {
		this.database = database;
	}

	public void initiateArticle() {
		System.out.println(calculator.calculator());
		System.out.println(database.select());
	}
}
```
#### 属性注入
```
public class ArticleManager {
	private ArticleCalculator calculator;
	private ArticleDatabase database;

	public ArticleManager() {
	}
	
	public void initiateArticle() {
		System.out.println(calculator.calculator());
		System.out.println(database.select());
	}
}
```


## ArgumentCaptor

> 介绍: 
    
用于捕获传入方法的参数

> 使用场景:

在某些场景中，不光要对方法的返回值和调用进行验证，同时需要验证一系列交互后所传入方法的参数。那么我们可以用参数捕获器来捕获传入方法的参数进行验证，看它是否符合我们的要求。
    
```
//例1
//当多次调用时，argument.getValue()返回最后一次调用的参数
ArgumentCaptor<PhonePo> argument = ArgumentCaptor.forClass(PhonePo.class);

verify(mockedPhonePoRepository, times(2)).saveAndFlush(argument.capture());
assertThat(argument.getValue().getPhoneNo()).isEqualTo("456");


//例2
//当多次调用时使用argument.getAllValues()获取所有参数
ArgumentCaptor<PhonePo> argument = ArgumentCaptor.forClass(PhonePo.class);

verify(mockedPhonePoRepository, times(2)).saveAndFlush(argument.capture());
List<PhonePo> argumentList = argument.getAllValues();
assertThat(argumentList.get(0).getPhoneNo()).isEqualTo("123");
assertThat(argumentList.get(1).getPhoneNo()).isEqualTo("456");

verify(mockedPhonePoRepository, times(2)).saveAndFlush(any());

```
> 注意事项

    1. 要先capture()在getValue();
    2. 当多次调用时，argument.getValue()返回最后一次调用的参数


### ArgumentCaptor + doAnswer + vertify使用实例

```
```