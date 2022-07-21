---
title: "「MySQL 45 讲」- 表复制"
discriptions: "「MySQL 45 讲」- 表复制"
date: 2020-10-11T15:27:12+08:00
author: Pismery Liu
archives: "2020"
tags: [MySQL,极客时间笔记]
categories: []
showtoc: true
---

本文主要讲解 MySQL 中迁移表数据的一些方法；分别是

- mysqldump 方法
- 导出 CSV 文件
- 物理拷贝方法

<!--more-->

# MySQL 表复制

## 准备工作

首先，我们先创建两个 DB，分别是 db1 和 db2，并在两个 DB 上创建同一个表 t

```SQL
create database db1;
use db1;

create table t(id int primary key, a int, b int, index(a))engine=innodb;
delimiter ;;
  create procedure idata()
  begin
    declare i int;
    set i=1;
    while(i<=1000)do
      insert into t values(i,i,i);
      set i=i+1;
    end while;
  end;;
delimiter ;
call idata();

create database db2;
create table db2.t like db1.t;
```

## mysqldump 方法

MySQL 提供了 mysqldump 命令，用于导出 MySQL 数据；下面我们介绍一些常用的参数：

- 「--no-create-info」：表示不导出表创建语句
- 「--single-transaction」：表示导出数据不需要对表加锁，而实采用 START TRANSACTION WITH CONSISTENT SNAPSHOT 的方法；
- 「--add-locks」：设置为 0，表示在输出的文件结果里，不增加" LOCK TABLES t WRITE;" 
- 「--set-gtid-purged」：设置为 off，表示不输出跟 GTID 相关的信息；
- 「--where」：导出数据的过滤条件；
- 「--result-file」：指定输出文件路径
- 「-–skip-extended-insert」：表示将一行数据使用一个 insert 语句，不进行合并；

下面我们通过 mysqldump 命令导出 db1 中表 t 中 a > 900 的数据至指定文件中；

打开 cmd 界面输入如下命令：

```sh
mysqldump -h127.0.0.1 -P3306 -uroot -p --add-locks=0 --no-create-info --single-transaction  --set-gtid-purged=OFF db1 t --where="a>900" --result-file=e:/Document/t.sql
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20201011111749.png)

下面我们加上参数 「-–skip-extended-insert」 看看结果：

```sh
mysqldump -h127.0.0.1 -P3306 -uroot -p --add-locks=0  --no-create-info --single-transaction  -–skip-extended-insert --set-gtid-purged=OFF db1 t --where="a>900" --result-file=e:/Document/t.sql
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20201011112159.png)


通过 mysqldump 命令导出了文件，接下来我们可以通过 命令 source 来导入数据；

```sql
mysql -h127.0.0.1 -P3306 -p -uroot db2 -e "source e:/Document/t.sql"
```

在这里补充一下， source 是 MySQL 客户端的命令工具，它的功能是将文件中的 sql 以分号分割，一条条地发送到 MySQL 服务端执行；因此，在慢查询日志和 binlog 都是记录的实际执行的 sql 而不是 source 命令；


## 导出 CSV 文件

说完 mysqldump 的导出导入方式，下面让我们看看让导出 CSV 文件的方式，步骤如下：

1. 设置 MySQL 参数 secure_file_priv;
2. 创建好相应的目标表；
3. 通过 select ... into outfile '' 命令导出 CSV 文件;
4. 通过 load data [local] infile '' into table xxx 命令导入数据；

> 设置参数 secure_file_priv;

MySQL 中通过 select ... into outfile 导出文件是受参数 secure_file_priv 限制的；该参数的设置规则如下：

- 如果设置为 NULL，则表示禁止 select into outfile 操作，这是默认设置；
- 如果设置为空串，则表示不限制文件生成位置，此为不安全设置，不推荐用于生产；
- 如果设置为表示路径的字符串，则要求生成文件只能放在设置的指定目录下；

我们可通过 show global variables like 'secure_file_priv' 查看参数；要注意的是这个参数只能通过修改配置文件设置，并且在修改配置文件后，需要重启 MySQL 服务端；

![](https://gitee.com/pismery/imageshack/raw/master/img/20201011135910.png)

![](https://gitee.com/pismery/imageshack/raw/master/img/20201011140021.png)

> 创建好相应的目标表

创建目标表 db2.t，表 t 我们在准备阶段通过 create table db2.t like db1.t; 的方式创建好了，这里我们再提供另外的方式创建目标表；

第一种，通过 show create table 命令获取创建表命令

```SQL
show create table t \G
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20201011141643.png)


第二种，通过 mysqldump 命令导出创建表语句的文件；

```SQL
mysqldump -h127.0.0.1 -P3306 -p -uroot --single-transaction  --set-gtid-purged=OFF db1 t --tab=e:/Document
```

此命令会在 'e:/Document' 目录下生成 [tableName].txt 和 [tableName].sql 两个文件，其中 txt 文件是表数据，sql 文件是创建表语句;

> 导出 CSV 文件

参数 secure_file_priv 设置好以后，下面我们通过 CSV 文件方式将数据库 db1 中的表 t 中 a > 900 的记录导入数据库 db2 的表 t 中；

1. 通过下面的命令将 SQL 的结果集导出；

```SQL
select * from db1.t where a>900 into outfile 'e:/Document/t.csv';
```

下面是使用 select ... into outfile 的一些注意事项：

1. 命令生成的文件是放在服务端的，不是客户端；
2. 命令不会自动覆盖文件，因此需要确保指定文件不存在于服务端；

> 导入 CSV 文件数据

CSV 文件准备好了，下面我们通过 load data 命令导入数据；

```SQL
load data infile 'e:/Document/t.csv' into table db2.t;
load data local infile 'e:/Document/t.csv' into table db2.t;
```

![](https://gitee.com/pismery/imageshack/raw/master/img/20201011142731.png)

![](https://gitee.com/pismery/imageshack/raw/master/img/20201011142754.png)

这里需要提醒的是， local 参数的作用；

- 不加 local，是读取服务端的文件，这个文件必须在 secure_file_priv 指定的目录或子目录下；
- 加上 local，读取的是客户端的文件，只要 MySQL 客户端有访问这个文件的权限即可。这时候，MySQL 客户端会先把本地文件传给服务端；

## 物理拷贝方法

无论是 mysqldump 还是导出 CSV 文件的方式，实际上都是逻辑导数据的方式，即需要从源表读取数据，生成文本，再导入目标表中；

下面将介绍一种实现物理复制文件的方式复制数据；(ps: 这要求使用 5.6 版本引入的可传输表空间(transportable tablespace) 的方法才能实现)

假若我们需要将源数据表 db1.t 导入到目标表 db2.t，那么操作步骤如下：

1. 执行命令 alter table db2.t discard tablespace; 移除目标表的 ibd 文件；
2. 执行命令 flush table db1.t for export; 生成源数据表的 cfg 文件；
3. 将源数据表的 ibd 文件和 cfg 文件拷贝至目标表所在 db 的数据目录中；
4. 执行命令 unlock tables; 此时源数据表 cfg 文件会表移除；
5. 执行命令 alter table db2.t import tablespace; 导入拷贝过来的 ibd 文件数据；

![](https://gitee.com/pismery/imageshack/raw/master/img/20201011150144.png)

这里需要注意的是，在执行第二步的 flush table for export 时，整个源数据表会处于只读状态，直到执行 unlick tables 命令才释放读锁；

## 总结

到这里我们就讲完了 3 种表复制的方式了，下面我们总结一下三种方式的优缺点；

- 物理拷贝的方式，速度最快，但是只支持全表复制；
- CSV 文件的方式，最灵活，可以使用 join 等 sql 的语法，但是还需要额外导出建表语句；
- mysqldump 方式，能够实现单表的简单 where 条件筛选导出，但无法做到 join 操作；


