---
title: "Collectors使用"
discriptions: "Collectors使用"
date: 2018-11-15T06:06:28+08:00
author: Pismery Liu
archives: "2018"
tags: [工具类,Java]
categories: [Java]
showtoc: true
---

介绍 Collectors 工具类

<!--more-->

# Collectors

## 简介

Collectors是一个将流转化成一个值的规约操作，这个值可以是Collection，Set，value Object。通过Collectors可以实现一下功能：

1. Reducing stream to a single value
2. Group elements in a stream   
3. Partition elements in a stream

## 基本使用

> 操作类

```Java
@Getter
@Setter
@AllArgsConstructor
@EqualsAndHashCode
public static class Task {
    private final String id;
    private final String title;
    private final TaskType type;
    private final LocalDate createdOn;
    private boolean done = false;
    private Set tags = new HashSet<>();
    private LocalDate dueOn;
}


public enum TaskType {
    WRITE, READ
}
```

### toList, toSet, toCollection

将流收集为 List, Set 集合若想是自定义集合则使用 toCollection，集合必须继承于Collection。因此 toCollection 不能收集转化为 Map。

```Java
public static List<Task> collectToList(List<Task> list) {
    return list.stream().collect(Collectors.toList());
}

public static Set<Task> collectToSet(List<Task> list) {
    return list.stream().collect(Collectors.toSet());
}

public static LinkedHashSet collectToLinkedHashSet(List<Task> list) {
    return list.stream().collect(Collectors.toCollection(LinkedHashSet::new));
}
```

### toMap

toMap 方法有三个重载函数，参数如下：

1. keyMapper：a mapping function to produce keys
2. valueMapper：a mapping function to produce values
3. mergeFunction：a merge function, used to resolve collisions between alues associated with the same key (若不定义默认有重复 key 值会抛 IllegalStateException)
4. mapSupplier：a function which returns a new, empty Map into which the results will be inserted


```Java
## 方法声明
public static <T, K, U> Collector<T, ?, Map<K,U>> toMap(
        Function<? super T, ? extends K> keyMapper,
        Function<? super T, ? extends U> valueMapper) {
    return toMap(keyMapper, valueMapper, throwingMerger(), HashMap::new);
}

public static <T, K, U> Collector<T, ?, Map<K,U>> toMap(
        Function<? super T, ? extends K> keyMapper,
        Function<? super T, ? extends U> valueMapper,
        BinaryOperator<U> mergeFunction) {
    return toMap(keyMapper, valueMapper, mergeFunction, HashMap::new);
}

public static <T, K, U, M extends Map<K, U>> Collector<T, ?, M> toMap(
        Function<? super T, ? extends K> keyMapper,
        Function<? super T, ? extends U> valueMapper,
        BinaryOperator<U> mergeFunction,
        Supplier<M> mapSupplier) {
    BiConsumer<M, T> accumulator = (map, element) -> map.merge(keyMapper.apply(element),valueMapper.apply(element), mergeFunction);
    return new CollectorImpl<>(mapSupplier, accumulator, mapMerger(mergeFunction), CH_ID);
}
```

> 使用

```Java
public static HashMap<String, Task> collectToMap(List<Task> list) {
    //return list.stream().collect(Collectors.toMap(Task::getTitle, task -> task));
    return list.stream().collect(Collectors.toMap(Task::getTitle, Function.identity(), (t1, t2) -> t2, HashMap::new));
}

public static ConcurrentHashMap<String, Task> collectToConcurrentHashMap(List<Task> list) {
    return list.stream().collect(Collectors.toMap(Task::getTitle, Function.identity(), (t1, t2) -> t2, ConcurrentHashMap::new));
}

public static LinkedHashMap<String, Task> collectToLinkedHashMap(List<Task> list) {
    return list.stream().collect(Collectors.toMap(Task::getTitle, Function.identity(), (t1, t2) -> t2, LinkedHashMap::new));
}
```

### groupingBy，partitioningBy

groupingBy 使用更加广泛点，partitioningBy 返回的 Map 的 key 只能是 Boolean。

> 函数声明

```Java
public static <T, K> Collector<T, ?, Map<K, List<T>>> groupingBy(Function<? super T, ? extends K> classifier) {
    return groupingBy(classifier, toList());
}

public static <T> Collector<T, ?, Map<Boolean, List<T>>> partitioningBy(Predicate<? super T> predicate) {
    return partitioningBy(predicate, toList());
}

public static <T, D, A> Collector<T, ?, Map<Boolean, D>> partitioningBy(
    Predicate<? super T> predicate,
    Collector<? super T, A, D> downstream) {

    ...

}
```

> 示例

```Java
public static Map<TaskType, List<Task>> groupByTaskType(List<Task> list) {
    return list.stream().collect(Collectors.groupingBy(task -> task.getType()));
}

public static Map<Boolean, List<Task>> partitionByTaskType(List<Task> list) {
    return list.stream().collect(
            Collectors.partitioningBy(task -> task.getType().equals(TaskType.READ))
    );
}
```

### joining

用于字符串连接，具有三个重载函数

> 函数声明 

```Java
public static Collector<CharSequence, ?, String> joining(
        CharSequence delimiter,
         CharSequence prefix,
        CharSequence suffix) {
    return new CollectorImpl<>(
            () -> new StringJoiner(delimiter, prefix, suffix),
            StringJoiner::add, StringJoiner::merge,
            StringJoiner::toString, CH_NOID);
}

public static Collector<CharSequence, ?, String> joining(CharSequence delimiter) {
    return joining(delimiter, "", "");
}

public static Collector<CharSequence, ?, String> joining() {
    return new CollectorImpl<CharSequence, StringBuilder, String>(
            StringBuilder::new, StringBuilder::append,
            (r1, r2) -> { r1.append(r2); return r1; },
            StringBuilder::toString, CH_NOID);
}
```

> 示例

```Java
public static String joinTite(List<Task> taskList) {
    return taskList.stream()
            .map(Task::getTitle)
            .collect(Collectors.joining(",", "[", "]"));
}

## 结果
["getTitle1","getTitle2","getTitle3","getTitle4"]


public static String joinTite(List<Task> taskList) {
    return taskList.stream()
            .map(Task::getTitle)
            .collect(Collectors.joining());
}
## 结果
"getTitle1getTitle2getTitle3getTitle4"


public static String joinTite(List<Task> taskList) {
    return taskList.stream()
            .map(Task::getTitle)
            .collect(Collectors.joining(","));
}
## 结果
"getTitle1,getTitle2,getTitle3,getTitle4"


```

### averaging, counting, summing

用于基本类型计算统计

> 使用示例

```Java
public static void collectToValue(List<Task> list) {
    Double average = list.stream().collect(Collectors.averagingInt(Task::getValue));
    log.debug("task list average: " + average);


    List<Long> integerList = Arrays.asList(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L);
    average = integerList.stream().collect(Collectors.averagingInt(value -> value.intValue())); //4.5
    log.debug("integer list  (averagingInt) average: " + average);
    average = integerList.stream().collect(Collectors.averagingLong(value -> value)); //4.5
    log.debug("integer list  (averagingLong) average: " + average);
    average = integerList.stream().collect(Collectors.averagingDouble(value -> value)); //4.5
    log.debug("integer list  (averagingDouble) average: " + average);


    IntSummaryStatistics collect = integerList.stream().collect(Collectors.summarizingInt(value -> value.intValue()));
    log.debug("integer list (IntSummaryStatistics) average: " + collect.getAverage()); //4.5
    log.debug("integer list (IntSummaryStatistics) getMax: " + collect.getMax()); //1
    log.debug("integer list (IntSummaryStatistics) getMin: " + collect.getMin()); //8
    log.debug("integer list (IntSummaryStatistics) getSum: " + collect.getSum()); //1+2+..+8 = 36
    log.debug("integer list (IntSummaryStatistics) getCount: " + collect.getCount()); //8
    log.debug("integer list (Collectors) counting: " + integerList.stream().collect(Collectors.counting())); //8
}
```