---
title: "「MySQL 45 讲」- 自增值处理"
discriptions: "「MySQL 45 讲」- 自增值处理"
date: 2020-10-08T20:16:07+08:00
author: Pismery Liu
archives: "2020"
tags: [MySQL,极客时间笔记]
categories: []
showtoc: true
---

本文主要讲解 MySQL 中自增值相关内容

<!--more-->

# MySQL 自增值

文章主要涉及以下知识点：

1. 自增值的生成逻辑；
2. 自增值不连续的几种原因；
3. 自增值的相关配置；

下面我们开始讲解自增值生成的基本逻辑；


## 自增值的修改逻辑

介绍自增值的修改逻辑之前，我们先看一下如何查看当前自增值，以及自增值的保存机制；

首先，我们可以通过 show create table [tableName] 命令查看自增值的当前值；

```SQL
CREATE TABLE `t` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `c` int(11) DEFAULT NULL,
  `d` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `c` (`c`)
) ENGINE=InnoDB;

insert into t value(null,1,1);

show create table t \G
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20201004155157.png)

我们已经了解了如何查看自增值，接下来，介绍 MySQL 是如何保存这个自增值的?

其实 MySQL 在不同的引擎，不同版本，处理保存自增值的方式是不一样的；

- 在 MyISAM 引擎中，自增值是保存在数据文件中；
- 在 InnoDB 引擎中：
    - 如果是 8.0 版本是将自增值的变更保存在 redo log 中，因此，重启的时候可以依靠 redo log 恢复为重启前的值；
    - 如果是 5.7 及以下版本，自增值是保存在内存里的，没有做持久化；重启后会将自增值设置为 max(id) + 1;

下面，我们再看看自增值的修改逻辑。

在 MySQL 中，自增值的设置有以下两个：

- auto_increment_offset：自增值的初始值，默认为 1；
- auto_increment_increment：自增值的增长步长，默认为 1；

> 在某些场景，例如双 Master 架构，并且要求双写的时候，往往会将
auto_increment_increment 设置为 2；Master 分别设置 auto_increment_offset 为 1 和 2; 从而保证自增字段不会冲突；


在 MySQL 中，如果字段 A 被设置为 AUTO_INCREMENT，则在插入一行数据时，将按以下逻辑修改自增值  ：

- 如果插入数据中，字段 A 的值为 null 或者 0:
    1. 获取当前表的自增值赋值到字段 A 中；
    2. 将当前自增值 + auto_increment_increment；
    3. 执行插入操作；
- 如果插入数据中，字段 A 指定了数值 X :
    - 如果当前自增值 Y > X，则不用修改自增值；
    - 如果 Y <= X，则修改当前自增值为 X + auto_increment_increment；


## 自增值不连续的几种原因

根据上述自增值修改逻辑，我们可以发现，对于 insert 语句，MySQL 首先获取当前自增值，然后更新当前自增值，最后才插入数据的；

出于性能考虑，如果后续语句执行失败，自增值是不会执行回滚操作的，从而导致自增值不连续；MySQL 只保证自增值是递增但不连续；

我们可以大致罗列导致自增值不连续的几个原因：

- insert 语句其他非自增字段不符合表数据要求，如违反唯一索引，数据格式不对，数据过长等等；
- 事务回滚；

此外，自增值的申请机制也会导致自增值的不连续；

对于 insert values 的语句，MySQL 能够知道插入的数据量，可以预先申请指定数量的自增值，这种情况不会导致自增值的不连续；

而对于批量插入数据的 SQL，如 

- insert ... select
- replace ... select
- load data

这种批量插入数据的语句，如果每插入一条数据申请自增值一次，很明显，不仅速度慢，而且会影响到并发性能；MySQL 采用了如下的批量申请策略：

第一次申请一个自增值，后续的申请自增值的数量都是上次申请的两倍；

这就导致，最后一次可能申请了过多的自增值，从而造成了自增值的不连续；示例如下：

```SQL
insert into t values(null, 2,2);
insert into t values(null, 3,3);
insert into t values(null, 4,4);

create table t2 like t;
insert into tt(c,d) select c,d from t;
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20201004164439.png)

可以看到，表 t 有四条数据，批量插入四条数据时，表 tt 的自增值变成为 8；申请流程如下：

1. 申请一个自增值，插入第一条数据（此时，自增值为 2）
2. 申请两个自增值，插入第二和第三条数据（此时，自增值为 4）
3. 申请四个自增值，插入第四条数据（此时，自增值为 8）


前面讲到，出于性能方面的考虑，MySQL 决定不回滚自增值，只保证自增值递增；那么具体是怎么影响性能呢？

我们可以考虑一个场景如下：

- 事务 A：申请了自增值 1，2；
- 事务 B：申请了自增值 3，4；
- 事务 B：提交事务；
- 事务 A：事务失败，回滚，此时如果回滚自增值为 1，则由于已经存在自增值 3，4，可能导致后续的自增值冲突；

如果要回滚自增值，并且避免自增值冲突，则有下面两个方案

1. 每次申请自增值时，都要确定自增值是否存在；这样本来一个快速的操作，就需要查找索引树了；
2. 申请自增值的锁，直到事务提交才释放，这就大大增加了自增值的锁粒度，从而影响并发性能；

综上，为了提高性能，MySQL 决定不回滚自增值，只保证自增值的递增；


## 自增值的相关配置

自 5.1.22 版本开始，MySQL 引入了参数 「innodb_autoinc_lock_mode」；

- 当参数为 0 时，即 MySQL 5.0 所采用的策略，申请自增值的锁，等到语句执行完才释放；
- 当参数为 1 时：
    - 对于普通 insert 语句，自增值申请后立即释放；
    - 对于批量插入语句，自增值仍然需要执行完语句，才释放锁；（ps: 此为 MySQL 5.X 版本的默认值）
- 当参数为 2 时，所有自增值都申请后立即释放；（ps: MySQL 8.0 版本后将此设置为默认值，同时参数「binlog_format」设置为 row）


善于思考的我们，不禁会想当「innodb_autoinc_lock_mode」值为 1 时，为什么对于批量插入语句需要等到语句执行完后，才能释放自增值的锁呢？

答案很简单，为了数据的一致性；我们知道，当 MySQL 「binlog_format」设置为 statement 的时候，binlog 记录的是语句级别的日志；

此时，遇到下面的场景：

Session A: 执行 insert ... select；
Session B: 在 Session A 执行过程中执行 insert 语句；

此时，假设 Session A 批量插入语句立即释放自增值的锁；则 Session B 的自增值是不确定的，而 binlog 只能记录这两句语句，如果发送给其他备库或者回滚数据库时，则无法保证自增值与原数据一致；

相信你可以发现，当我们将 「binlog_format」设置为 row 格时，binlog 记录的是数据级别的日志，就不会出现这种的情况了；

因此，这里也推荐使用 row 格式的 binlog，同时将「innodb_autoinc_lock_mode」设置为 2；

## 总结

首先，我们讲解了如何查看当前表自增值，以及 MySQL 是如何保存自增值的；

接着，我们说到，出于性能方面的考虑，MySQL 决定不回滚自增值只保证自增值递增；因此，我们可以知道，在申请自增值后，语句执行失败，或在事务回滚时，MySQL 会出现自增值不连续的情况；

MySQL 为了提高申请自增值的申请效率，在重复申请时，申请数量按指数形式增长；因此，最后一次申请过多的自增值，最终导致自增值的不连续；

最后，我们说到了自增值的策略配置「innodb_autoinc_lock_mode」，以及建议设置为 2，同时 binlog 采用 row 格式；


