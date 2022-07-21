---
title: "自增Id"
discriptions: "自增Id"
date: 2021-05-05T21:29:20+08:00
author: Pismery Liu
archives: "2021"
tags: []
categories: []
showtoc: true
draft: true
---
<!--more-->


自增ID 实现方式：
- 数据库自增
- sequence
- 模拟 seq： 建立一个表， select for update; 设置步长 2000； 性能高，但 ID 不连续；
- UUID
- 时间戳+随机数
- snowflake