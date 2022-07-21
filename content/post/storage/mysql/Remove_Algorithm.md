---
title: "「MySQL 45 讲」- Buffer Pool 淘汰算法"
discriptions: " Buffer Pool 淘汰算法"
date: 2020-09-22T21:07:23+08:00
author: Pismery Liu
archives: "2020"
tags: [MySQL,极客时间笔记]
categories: []
showtoc: true
---

本文为 「极客时间- MySQL 实战 45 讲」 的学习笔记；主要为了加深理解；

<!--more-->

# MySQL Buffer Pool 淘汰算法

我们知道，数据库服务器的内存空间比磁盘数据页空间小得多，但是为什么 MySQL 在查询大表时不会出现 OOM 呢?

实际上原因很简单，MySQL 创建了一块内存空间 Buffer Pool 来管理数据页，当 Buffer Pool 的数据页满了，就会淘汰旧的数据页，加载新的数据页至 Buffer Pool 中，从而解决了内存空间不足的问题；

Buffer Pool 的大小可以通过参数 「innodb_buffer_pool_size」来设置 ，建议设置为实际可用物理内存的 60% 到 80%；

Buffer Pool 不可避免需要淘汰数据页，腾出足够空间加载新的数据页，下面我们谈谈 Buffer Pool 中的淘汰算法

## Buffer Pool 的淘汰算法

Buffer Pool 的淘汰算法采用了一种改进版本的 LRU 「最近最少使用」算法；

我们先了解一下标准 LRU 算法的规则：

1. 在访问队列中的数据时，将数据移动到队首；
2. 载入新数据时，将新元素加入队首，如果队列已满，则移除队尾元素；

标准 LRU 算法，虽然看上去没问题，但是 Buffer Pool 有一个重要的职责，就是减少磁盘 IO, 从而加快查询速度，而这依赖一个重要的指标「内存命中率」；一个稳定的线上服务，「内存命中率」一般要在 99% 以上；

「内存命中率」数值，可查看命令 show engine innodb status 返回结果中的字段 「Buffer pool hit rate」；


回到淘汰算法，如果 Buffer Pool 采用标准的 LRU 算法，当我们查询一个大表甚至是一个冷数据大表时，很可能会淘汰大量的热数据，从而导致「内存命中率」突然下降；这是一个稳定的数据库服务不可接受的，因此 MySQL 对 LRU 算法做了相应的改良；

改造后的 LRU 算法规则如下：

1. 将 Buffer Pool 分割成两段，队列头部的 5/8 区间为 young 区间，剩下的空间为 old 区间；
2. 若访问数据页在 young 区间，则将数据移至队首；
3. 若访问数据页在 old 区间，则判断数据页存在时间是否超过 「innodb_old_blocks_time」 毫秒，如果超过则移至队首；否则保持位置不变；(ps: 「innodb_old_blocks_time」 默认值 1000 毫秒)
4. 加载新的数据页，将新数据页添加至 old 区间头部，即整个 Buffer Pool 的 5/8 的位置；如果 Buffer Pool 已满，则淘汰队尾数据页；


按照改造后的 LRU 算法，查询大表或冷数据大表时，我们可以发现

1. 在查询过程中，新的数据页被添加到 old 区域，不会影响 young 区域；
2. 虽然一个数据页有多条数据，但通常按顺序查询，所以一般访问时间不会超过 1 s；从而数据页保留在了 old 区域；
3. 由于在 old 区域，所以当热数据回来，可以很快地淘汰掉这些冷数据；