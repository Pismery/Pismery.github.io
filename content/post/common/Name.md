---
title: "Java 函数命名范式"
discriptions: "Java 函数命名范式"
date: 2021-12-22T15:49:23+08:00
author: Pismery Liu
archives: "2021"
tags: []
categories: []
showtoc: true
draft: false
---

日常开发时，方法命名总是让人头大，本文主要记录一些好的函数命名范式；

<!--more-->

## 判断型方法

- is: 表示是否符合 Xxx 状态，如 isDeleted(), isClosed();
- can: 表示是否能够执行 Xxx 操作，如 canOrder(), canDelete();
- has/inlcude/contain: 表示对象是否持有所期待的数据和属性，如 hasVip();
- should,needs: 表示需要某种状态，shouldVip(), needsVVip;

## 获取数据型方法

- get: 直接从对象，数据结构获取数据;
- calculate/calc: 经过计算获取的数据;
- valueOf/of/from: 从一个对象转换成另一个对象；
- query/find: 查询数据库获取的数据;
- fetch: 经过网络接口获取的数据;
- load: 读取文件获取的数据;
- parse: 从文件获取经过解析的数据;
- build: 需要多步构建的数据;


## 回调方法

- beforeXxx, afterXxx
- preXxx, postXxx
- onXxx

## 常用类命名

- AbstractXxx/BaseXxx： 抽象类
- XxxEnum: 枚举类
- XxxUtils: 工具类
- XxxConstant: 常量类
- XxxxException: 异常类
- XxxVO, XxxDTO, XxxDO, XxxDAO: 领域模型类
- XxxBuilder, XxxFactor, XxxStrategy: 设计模式类
- XxxTest: 测试类
- XxxController, XxxService, XxxDAO: MVC 类 

## 验证类与验证方法

- XxxValidator: xxx 验证器；
- validateXxx(): 验证Xxx；

## 参考链接

- [告别编码5分钟，命名2小时！史上最全的Java命名规范参考！](https://www.cnblogs.com/liqiangchn/p/12000361.html)