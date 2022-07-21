---
title: "「MySQL 45 讲」- Group By 操作处理"
discriptions: "「MySQL 45 讲」- Group By 操作处理"
date: 2020-09-30T21:05:43+08:00
author: Pismery Liu
archives: "2020"
tags: [MySQL,极客时间笔记]
categories: []
showtoc: true
---

本文主要讲解 MySQL 对 group by 的处理流程；

<!--more-->
# MySQL Group By 操作处理

## 前置条件

为了方便我们讲解，我们用如下 SQL 初始化表 t1；

```SQL
CREATE TABLE `t1` (
  `id` int(11) NOT NULL,
  `a` int(11) DEFAULT NULL,
  `b` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `a` (`a`)
) ENGINE=InnoDB;

drop procedure idata;
delimiter ;;
create procedure idata()
begin
  declare i int;
  set i=1;
  while(i<=1000)do
    insert into t1 values(i, i, i);
    set i=i+1;
  end while;
end;;
delimiter ;
call idata();
```

## 基本执行流程

下面我们先看看 Explain 一条简单的 group by 语句结果；

```SQL
explain select id%10 as m, count(*) as c from t1 group by m;
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20200930210936.png)

我们可以看到 Extra 字段有三个信息：

- Using index，表示这个语句使用了覆盖索引，选择了索引 a，不需要回表；
- Using temporary，表示使用了临时表；
- Using filesort，表示需要排序；

 MySQL 的具体执行流程如下：
 
 1. 创建一个内存临时表，字段有 m 和 c，其中 m 设置为主键；
 2. 扫描表 t1 的索引 a，依次取出 id 值，计算 id % 10 的结果 m1，进行如下操作；
    1. 如果内存临时表不存在 m1, 则插入数据 (m1, 1);
    2. 如果内存临时表已存在 m1, 则将相应行的 c 加一;
3. 遍历表 t1 结束后，再通过 sort buffer 进行排序，得到结果集返回给客户端；
 
 ![](https://gitee.com/pismery/imageshack/raw/master/img/20200930193141.png)

从上面的执行流程，我们可以发现，MySQL 默认会对最终结果进行排序；如果返回结果不需要排序，我们可以通过 order by null 来告诉 MySQL 不需要排序；

下面是相应的 explain 结果，可以看到没有了 Using filesort 的字样；

```SQL
explain select id%10 as m, count(*) as c from t1 group by m order by null;
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20200930211035.png)

需要另外说明的是，上面的 group by 由于只有 10 条记录，内存临时表可以装得下，所以全程只使用内存临时表；如果装不下则会将内存临时表转化成磁盘临时表；

补充说明一下: 

- 磁盘临时表默认存储引擎可查看 'internal_tmp_disk_storage_engine' 
- 内存临时表默认存储引擎可查看 'default_tmp_storage_engine'
- 内存临时表大小设置可查看 'tmp_table_size'

```SQL
show variables where variable_name = 'internal_tmp_disk_storage_engine' \G;
show variables where variable_name = 'default_tmp_storage_engine' \G;
show variables where variable_name = 'tmp_table_size' \G;
```

## group by 优化方式 - 索引；

可以看到，无论是内存临时表还是磁盘临时表，都需要构建一个带有唯一索引的表，执行代价都比较高，如果表数据量大时，性能会很低；

那有什么方式可以避免创建临时表呢? 

首先，我们可以思考一下，为什么一定要使用临时表？原因是 group by 的字段是无序的，系统需要保留统计数值，因此需要构建这样的一张表；

思路的关键就在 group by 的字段是无序的；如果 group by 的字段本身是有序的，则可以遍历获取最终统计结果；

例如：如果 id % 10 是按如下顺序进行统计的：

```
0,0,0,0,1,1,2,2,2,3;
```

这种情况，遇到第一个 1， 则表示扫描完所有的 0；遇到第一个 2, 则表示扫描完所有的 1；

需要字段有序输入，我们可以自然想到索引，因为索引本身就是有顺序的；

下面我们可以按照这个思路优化一下 SQL;

1. 新增一个字段 z，这个字段值始终设置为 id % 10;
2. 为字段 z 创建一个索引；

```SQL
alter table t1 add column z int generated always as(id % 10), add index(z);

explain select z as m, count(*) as c from t1 group by z;
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20200930211215.png)

可以看到 extra 字段只剩下 Using index 的字样了，表示只是用了覆盖索引；


##  group by 优化方式 - 直接排序；

日常开发过程中，能够通过添加索引解决 group by 的性能稳定，那是最好了；但是总会出于各种考虑，无法添加这样的一个索引；这样就不可避免的需要我们先排序再 group by 了；

MySQL 同样提供了 SQL_BIG_RESULT，这个 hint 告知优化器按如下方式执行 group by 语句

```SQL
explain select SQL_BIG_RESULT id%10 as m, count(*) as c from t1 group by m;
```

1. 初始化一个 sort buffer，确认放入字段 m;
2. 扫描表 t1 的索引 a，依次取出里面的 id 值, 将 id%100 的值存入 sort_buffer 中；
3. 扫描完成后，对 sort_buffer 的字段 m 做排序（如果 sort_buffer 内存不够用，就会利用磁盘临时文件辅助排序）；
4. 排序完成后，就得到了一个有序数组。
5. 遍历有序数组，得到最终 group by 结果集，返回给客户端；

下面我们看看 explain 的结果，可以发现 extra 没有了 Using temporary 的字样，表示没有使用内存临时表；

![](https://gitee.com/pismery/imageshack/raw/master/img/20200930211303.png)

## 总结

首先，我们通过简单的 group by 语句，发现其正常流程中会使用临时表和 sort buffer 进行排序；

然后，讲解到如果结果不需要排序，可以通过 order by null 的方式避免排序；

接着，由于 group by 需要临时表存取数据，我们提出了通过索引的方式，将 group by 字段排好序，从而优化 group by 流程；

最后, 日常开发总由于各种原因无法新增索引，我们又提出通过 SQL_BIG_Result 的方式告知优化器直接先通过 sort buffer 排序，再统计数值；从而避免创建临时表；