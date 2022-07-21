---
title: "SiftingAppender"
discriptions: "SiftingAppender"
date: 2019-05-02T21:40:34+08:00
author: Pismery Liu
archives: "2019"
tags: [Java,log]
categories: [Java]
showtoc: true
---

通过 Logback 的 SiftingAppender 实现按线程分配 log 文件 文件。
<!--more-->

# SiftingAppender

```XML
<configuration scan="true" scanPeriod="60 seconds" debug="false">

    <property name="USER_HOME" value="E:\\Workspace\\java\\idea\\study\\basic\\log" />
    <appender name="SIFT" class="ch.qos.logback.classic.sift.SiftingAppender">
        <discriminator>
            <key>threadGroupId</key>
            <defaultValue>unknown</defaultValue>
        </discriminator>
        <sift>
            <appender name="FILE-${threadGroupId}" class="ch.qos.logback.core.FileAppender">
                <file>${USER_HOME}/sift/SIFT-${threadGroupId}.log</file>
                <append>false</append>
                <layout class="ch.qos.logback.classic.PatternLayout">
                    <pattern>%d [%thread] %level %mdc %logger{35} - %msg%n</pattern>
                </layout>
            </appender>
        </sift>
    </appender>
    <root level="DEBUG">
        <appender-ref ref="SIFT"/>
    </root>
</configuration>
```

```Java
@Slf4j
public class LogbackDemo implements Runnable{

    private String counterName;

    public LogbackDemo(String counterName) {
        this.counterName = counterName;
    }

    public void run() {
        MDC.put("threadGroupId", counterName);
        log.info("start counter {}", counterName);
        MDC.remove("threadGroupId");
    }

    public static void main(String[] args) {
        ExecutorService executorService = Executors.newFixedThreadPool(5);
        for (int i = 0; i < 10; ++i) {
            executorService.execute(new LogbackDemo(String.valueOf(i)));
        }
        executorService.shutdown();
    }
}
```

> 运行结果下图

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190502213827.png)