---
title: "Kafka基础"
discriptions: "Kafka基础"
date: 2021-05-05T21:28:17+08:00
author: Pismery Liu
archives: "2021"
tags: [Java,MS,kafka]
categories: [Java]
showtoc: true
draft: true
---

目前系统设计中，消息队列是一个非常重要的中间件；目前市面上有许多消息队列的中间件，本文主要介绍 kafka 的一些基本概念；

<!--more-->

消息队列的三大作用：

1. 解耦
2. 异步
3. 削峰

应用场景：

- 应用系统监控，系统活动跟踪
- 日志聚合
- 流计算处理
- 数据中转


kafka: scalar 语言编写，起源于 LinkedIn ；

设计目标：

1. O(1) 复杂度持久化能力，面对 TB 级的数据也能保准常数级的复杂度访问数据；
2. 高吞吐率；
3. 同时支持离线和实时的数据处理；
4. 保证每个 Partition 顺序处理；
5. 支持水平扩展；

基本概念：

1. Broker: kafka 集群包含一个或多个服务器，这种服务器称为 broker;
2. Topic: 每条 kafka 消息都有一个类别；这个类别就是 Topic; 默认持久化;
3. Partition: 是物理上的概念，一个 Topic 包含一个或多个 Partition;
4. Producer: 负责生产 kafka 的消息
5. Consumer: 负责消费 kafka 的消息
6. Counsumer Group: 每个 consumer 属于特定的 Consumer Group; 组内 Topic 相当于 Queue;
 Topic 是消费订阅模式会将消息发送给所有消费者组；所以每个消费者组都会消费所有消息，但消息会被消费者组内的某一个消费者消费；

Topic 特性

- 通过 Paritition 增加可扩展性
- 通过顺序写入达到高吞吐
- 通过多副本增加容错性

一个 Topic 几个 partition 合适？
单个机器不建议大量的 partition;也不建议有大量 Topic;
因为 partition 对应着一个数据文件，多个数据文件读写就意味着随机 IO 读写；
一个文件是顺序读写，多个文件就变随机了； 控制一个机器 parition 在 十来 个量级

同一个 partition 在一个 consumer group 中，只有一个消费者；所以如果消息放到同一个 partition 中，对于一个 consumer group 是顺序消费的；


生产者确认模式：

- ack = 0: 只管发送不管有没有写入；
- ack = 1: Leader 写入成功，表示写入成功；
- ack = -1/all: 写入至最小副本数，表示写入成功；

生产者发送模式：

- 同步发送： KafkaProducer.send(ProducerRecord).get(); or  KafkaProducer.send(ProducerRecord), KafkaProducer.flush();
- 异步发送： KafkaProducer.send(ProducerRecord);  or KafkaProducer.send(ProducerRecord,(metadata,exception) -> {});

生产者顺序保证：

1. set "max.in.flight.requests.per.connection" = 1
2. 同步发送；

生产者消息可靠性传输：

1. set "enable.idempotence" = true  => 此时 "ack" 会设置为 all
2. set "transaction.id" =  xxx
3. KafkaProducer.beginTransaction();
4. KafkaProducer.abortTransaction();
5. KafkaProducer.commitTransaction();

触发 rebalance 场景

- cosumer 挂了；
- 新增 consumer； 
- Topic 新增 partition；
- 新 Topic 匹配已有订阅正则；

消费者 offset 消费模式
同步提交

1. 关闭自动提交 set "enable.auto.commit"  = false;
2. 同步提交消费消息 consumer.commitSync();

异步提交

1. 关闭自动提交 set "enable.auto.commit"  = false;
2. 异步提交消费消息 consumer.commitAsync();

自动提交

1. 打开自动提交 set "enable.auto.commit"  = true;
2. 设置自动提交窗口 set "auto.commit.interval.ms" = 5000;
自定义 offset seek: consumer.subscrible(List(Topic), new ConsumberRebalanceListener() {});  