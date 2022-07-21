---
title: "OrderByUtils"
discriptions: "OrderByUtils"
date: 2019-12-15T22:26:56+08:00
author: Pismery Liu
archives: "2019"
tags: [工具类, Java]
categories: [Java]
showtoc: true
---

<!--more-->

# Order by 操作

排序问题是日常开发中经常遇到的问题，以下是 Java 解决各类排序问题的一些例子，以供大家参考。

## 单字段排序

对于排序问题，Java 提供了两种解决方案一种是实现接口 Comparable 的 compareTo 方法，另一种是使用 Comparator 工具类；两者都能实现排序的功能。日常开发中，我更倾向使用工具类 Comparator 的方式，理由如下：

1. 对于某一个对象，我们需要多种排序方式时，实现接口的方式则难以实现；而工具类 Comparator 可以提供不同的 Comparator，从而很好地实现这样的需求；
2. Java 8 中通过 Lambda 引入了更多的 Api 使得使用 Comparator 代码更加易懂，简单。

### 单字段升序排序

本文所有示例，采用 Employee 类作为待排列表的元素，下面是 Employee 类的定义

```Java
@Data
@AllArgsConstructor
private static class Employee {
    private Integer id;
    private String name;
    private Integer age;
    private Position position;
}

private enum Position {
    BRAND_1, BRAND_2, BRAND_3, BRAND_4
}
```

首先，先通过根据 Employee 中 name 字段升序排序的例子，看看如何使用接口和工具类的方式实现；

> 实现接口 Comparable 方式

```
@Data
@AllArgsConstructor
private static class Employee implements Comparable<Employee>{
    private Integer id;
    private String name;
    private Integer age;
    private Position position;

    @Override
    public int compareTo(Employee employee) {
        return this.name.compareTo(employee.getName());
    }
}

@Test
public void orderBy_single_string_java7_asc() {
    //Given
    System.out.println("orderBy_single_string_comparable_asc");
    //When
    Collections.sort(singleList);

    singleList.forEach(System.out::println);
}
```

> 使用工具类 Comparator 方式

```Java
// Java 7 实现
@Test
public void orderBy_single_string_java7_asc() {
    //Given
    System.out.println("orderBy_single_string_java7_asc");
    //When

    Collections.sort(singleList, new Comparator<Employee>() {
        @Override
        public int compare(Employee o1, Employee o2) {
            return o1.getName().compareTo(o2.getName());
        }
    });

    singleList.forEach(System.out::println);
}
```

```Java
// Java 8 实现
@Test
public void orderBy_single_string_java8_asc() {
    //Given
    System.out.println("orderBy_single_string_java8_asc");
    //When
    singleList.sort(Comparator.comparing(Employee::getName));

    singleList.forEach(System.out::println);
}
```

> 运行结果

![](https://cdn.jsdelivr.net/gh/Pismery/Picture/img20191215215403.png)


### 单字段降序排序

下面根据 name 字段进行降序排序，可以感受到 Lambda 使得代码更清晰易懂；

```Java
// Java 7 实现
@Test
public void orderBy_single_string_java7_desc() {
    //Given
    System.out.println("orderBy_single_string_java7_desc");
    //When
    Collections.sort(singleList, new Comparator<Employee>() {
        @Override
        public int compare(Employee o1, Employee o2) {
            return o2.getName().compareTo(o1.getName()); //o2 compare o1
        }
    });

    singleList.forEach(System.out::println);
}


// Java 8 实现
@Test
public void orderBy_single_string_java8_desc() {
    //Given
    System.out.println("orderBy_single_string_java8_desc");
    //When
    singleList.sort(Comparator.comparing(Employee::getName).reversed());

    singleList.forEach(System.out::println);
}
```

> 运行结果

![](https://cdn.jsdelivr.net/gh/Pismery/Picture/img20191215215146.png)

### 根据枚举字段 position 排序

下面是根据枚举字段 position 进行降序排序，看看枚举类型是如何排序的。

> Java 7

```Java
// Java 7 实现
@Test
public void orderBy_single_enum_java7_desc() {
    //Given
    System.out.println("orderBy_single_enum_java7_desc");
    //When
    Collections.sort(singleList, new Comparator<Employee>() {
        @Override
        public int compare(Employee o1, Employee o2) {
            return o2.getPosition().compareTo(o1.getPosition());
        }
    });

    singleList.forEach(System.out::println);
}

// Java 8 实现
@Test
public void orderBy_single_enum_java8_desc() {
    //Given
    System.out.println("orderBy_single_enum_java8_desc");
    //When
    singleList.sort(Comparator.comparing(Employee::getPosition).reversed());

    singleList.forEach(System.out::println);
}
```

> 运行结果

![](https://cdn.jsdelivr.net/gh/Pismery/Picture/img20191215220424.png)


## 多字段排序

日常开发中，多字段的排序也十分常见，下面根据字段 name(asc), age(asc), position(desc) 进行排序，看看如何实现多字段的排序；

> Java 7

```Java
@Test
public void orderBy_multiple_java7_desc() {
    //Given
    System.out.println("orderBy_multiple_java8_asc");
    //When
    Collections.sort(multipleList, new Comparator<Employee>() {
                @Override
                public int compare(Employee o1, Employee o2) {
                    int result;
                    result = o1.getName().compareTo(o2.getName());
                    if (result != 0) {
                        return result;
                    }

                    result = o1.getAge().compareTo(o2.getAge());
                    if (result != 0) {
                        return result;
                    }

                    return o2.getPosition().compareTo(o1.getPosition());
                }
            }
    );

    multipleList.forEach(System.out::println);
}
```

> Java 8

```Java
public class OrderUtils {
    @SafeVarargs
    public static <T> void orderBy(List<T> list, Comparator<T>... comparators) {
        if (comparators == null || comparators.length == 0) {
            throw new IllegalArgumentException("No comparator!...");
        }

        Comparator<T> combineComparator = comparators[0];
        for (int i = 1; i < comparators.length; i++) {
            combineComparator = combineComparator.thenComparing(comparators[i]);
        }
        list.sort(combineComparator);
    }
}


@Test
public void orderBy_multiple_java8_desc() {
    //Given
    System.out.println("orderBy_multiple_java8_asc");
    //When
    OrderUtils.orderBy(multipleList
            , Comparator.comparing(Employee::getName)
            , Comparator.comparing(Employee::getAge)
            , Comparator.comparing(Employee::getPosition).reversed()
    );

    multipleList.forEach(System.out::println);
}
```

> 运行结果

![](https://cdn.jsdelivr.net/gh/Pismery/Picture/img20191215221220.png)

### 自定义排序

有时，我们可能还需要自定义排序规则，下面根据 name(asc)， age(asc)， position(customer) 排序；

字段 position 自定义顺序规则：Brand_2 > Brand_1 > Brand_4 > Brand_3


```Java
private static Integer customerPositionWeight(Employee employee) {
    switch (employee.getPosition()) {
        case BRAND_1: return 2;
        case BRAND_2: return 1;
        case BRAND_3: return 4;
        case BRAND_4: return 3;
        default: throw new IllegalArgumentException();
    }
}
```

> java 7

```Java
@Test
public void orderBy_multiple_java7_customer() {
    //Given
    System.out.println("orderBy_multiple_java7_customer");
    //When
    Collections.sort(multipleList, new Comparator<Employee>() {
                @Override
                public int compare(Employee o1, Employee o2) {
                    int result;
                    result = o1.getName().compareTo(o2.getName());
                    if (result != 0) {
                        return result;
                    }

                    result = o1.getAge().compareTo(o2.getAge());
                    if (result != 0) {
                        return result;
                    }

                    Integer o1Weight = customerPositionWeight(o1);
                    Integer o2Weight = customerPositionWeight(o2);
                    return o1Weight.compareTo(o2Weight);
                }
            }
    );

    multipleList.forEach(System.out::println);
}
```

> Java 8

```Java
@Test
public void orderBy_multiple_java8_customer() {
    //Given
    System.out.println("orderBy_multiple_java8_customer");
    //When

    OrderUtils.orderBy(multipleList
            , Comparator.comparing(Employee::getName)
            , Comparator.comparing(Employee::getAge)
            , (o1, o2) -> {
                Integer o1Weight = customerPositionWeight(o1);
                Integer o2Weight = customerPositionWeight(o2);

                return o1Weight.compareTo(o2Weight);
            }
    );

    //Then
    multipleList.forEach(System.out::println);
}
```

> 运行结果

![](https://cdn.jsdelivr.net/gh/Pismery/Picture/img20191215221804.png)
