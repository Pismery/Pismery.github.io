---
title: "Logback"
discriptions: "Logback"
date: 2019-05-01T18:25:30+08:00
author: Pismery Liu
archives: "2019"
tags: [Java,log]
categories: [Java]
showtoc: true
---

<!--more-->

# Logback

Spring Boot 默认采用的日志框架就是 Logback; Logback 是 Log4j 创建者 Ceki Gülcü 创建的；下面介绍一下 Logback 的一些特性；

- 与 Log4j 相比更高的性能和更小的初始加载内存空间；
- Logback 经过了非常充分的测试；作者认为这就足以成为 Logback 的原因了
- Logback 很好的兼容了 slf4j, 并且通过 slf4j 开发者能够无需修改任何代码切换日志框架为 Log4j 或 j.u.l
- 文档更加充足且时常更新
- 不仅支持 XML 配置，0.9.22 版本后支持 Groovy 配置；而 Groovy 配置相较于 XML 配置更加直观、简单；
- 支持自动化读取配置
- 更优雅的处理 IO 异常导致的日志错误；当文件服务暂时性的不可用时，不需要重启应用，只要文件服务恢复，自动会将日志恢复回来；
- 自动移除过老的日志记录和自动压缩日志；
- Prudent mode（谨慎模式）尽管 Logback 运行在不同的 JVM 中也能够确保安全的写入同一个日志文件中；
- Lilith 类似 Log4j 中的 chainsaw 是日志访问查看器，但是 Lilith 的设计能够处理大量的日志数据
- 支持条件配置 if, then, else; 这样能够通过一个配置环境配置开发、测试、生产环境的配置；
- Filters, 有时候由于日志过多，我们会叫日志配置级别调的较高，当系统出现问题时，我们希望打印某方面的 debug 级别的日志而不想讲所有 debug 日志打印；此时可以使用 Filters 的使用；
- SiftingAppender 一个功能强大的 Appender, 能够通过指定参数拆分文件，如根据用户 seesion 拆分文件，为每一个用户记录一份日志文件
- 错误日志更加详细，能够打印出 jar 包的版本号

## Logback 使用

Logback 配置文件默认查找规则如下：

1. 查找类目录下的 logback-test.xml 文件;
2. 如果不存在，查找类目录下的 logback.groovy 文件
3. 如果不存在，查找类目录下的 logback.xml 文件；
4. 如果不存在，默认使用 BasicConfigurator, 创建最小化配置；等价于如下配置

```xml
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n </pattern>   
        </encoder> 
    </appender>
    
    <root level="INFO">
        <appender-ref ref="DEBUG" />
    </root> 
</configuration>
```

### Configuration

configuration 有以下三个参数配置

- scan: true 表示定期扫描配置，刷新日志行为；false 表示不扫描；
- scanPeriod: 配置扫描周期；如 60 seconds；
- debug: true 表示打印 logback 自身信息；

示例如下

```xml
<configuration scan="true" scanPeriod="60 seconds" debug="false">
</configuration>
```


### Appender 

Appender 主要用于设置日志的输出目标对象，可以是 Console(控制台)，文件，远程 Sorket 服务，数据库(Mysql, PostreSQL等)，JMS，Unix Syslog 守护进程等；

Appender 继承关系如下图

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190501151955.png)

#### ConsoleAppender

ConsoleAppender 将日志信息输出至控制台，有如下子节点配置

- encoder：格式化日志信息
- target： System.out (默认)或者 System.err


#### FileAppender

FileAppender 将日志信息输出至文件中，有如下子节点配置

- file：被写入的文件名，可以是绝对路径，也可以是相对路径；**不建议使用相对路径**
- append：true（默认） 表示向文件后添加日志信息；false 表示清空现存文件，重新写入；
- encoder：格式化日志信息
- prudent：是否安全的写入

#### RollingFileAppender

RollingFileAppender 滚动记录文件，先将日志记录到指定文件，当符合某个条件时，将日志记录到其他文件。有如下子节点配置

- file：被写入的文件名，可以是绝对路径，也可以是相对路径；**不建议使用相对路径**
- append：true（默认） 表示向文件后添加日志信息；false 表示清空现存文件，重新写入；
- encoder：格式化日志信息
- prudent：是否安全的写入
- rollingPolicy: 设置发生 rolling 的操作
    - TimeBasedRollingPolicy
    - SizeAndTimeBasedRollingPolicy
    - FixedWindowRollingPolicy
- triggeringPolicy：设置如何触发 rolling 操作
    - SizeBasedTriggeringPolicy

> 示例配置

```xml
<!-- TimeBasedRollingPolicy-->
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <!-- Support multiple-JVM writing to the same log file -->
    <prudent>true</prudent>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
        <fileNamePattern>logFile.%d{yyyy-MM-dd}.log</fileNamePattern>
        <maxHistory>30</maxHistory> 
        <totalSizeCap>3GB</totalSizeCap>
    </rollingPolicy>
    
    <encoder>
        <pattern>%-4relative [%thread] %-5level %logger{35} - %msg%n</pattern>
    </encoder>
</appender> 

<!-- Size and time based rolling policy-->
<appender name="ROLLING" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>mylog.txt</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
    <!-- rollover daily -->
        <fileNamePattern>mylog-%d{yyyy-MM-dd}.%i.txt</fileNamePattern>
        <!-- each file should be at most 100MB, keep 60 days worth of history, but at most 20GB -->
        <maxFileSize>100MB</maxFileSize>    
        <maxHistory>60</maxHistory>
        <totalSizeCap>20GB</totalSizeCap>
    </rollingPolicy>
    
    <encoder>
        <pattern>%msg%n</pattern>
    </encoder>
</appender>

<!-- FixedWindowRollingPolicy-->
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>test.log</file>
    
    <rollingPolicy class="ch.qos.logback.core.rolling.FixedWindowRollingPolicy">
        <fileNamePattern>tests.%i.log.zip</fileNamePattern>
        <minIndex>1</minIndex>
        <maxIndex>3</maxIndex>
    </rollingPolicy>
    
    <triggeringPolicy class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy">
        <maxFileSize>5MB</maxFileSize>
    </triggeringPolicy>
    <encoder>
        <pattern>%-4relative [%thread] %-5level %logger{35} - %msg%n</pattern>
    </encoder>
</appender>
```


### Encoder vs Layout

Appender 内能够通过 encoder 和 layout 配置日志输出的格式；两者配置方式如下：

```xml
<appender name="Encoder" class="ch.qos.logback.core.ConsoleAppender">
    <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
        <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n </pattern>   
    </encoder> 
</appender>

<appender name="Encoder" class="ch.qos.logback.core.ConsoleAppender">
    <layout class="ch.qos.logback.classic.PatternLayout">
        <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </layout>
</appender>
```

> encoder

encoder 功能是将一个 event 事件转换成一组 btye 数组，再将数据写入目标对象中；其是在 0.9.19之后的版本引进的，之后的版本 FileAppender及其子类都期望使用 encoder 而不使用 layout；

encoder 可配置标签 

- immediateFlush 默认值为 true； 表示立即刷新日志至输出目标对象；这样即时项目没有正常关闭也能够记录到所有日志到磁盘中；如果设置为 false ，能够处理大概 5 倍的 logger 接入量，但是非正常关闭项目时可能丢失日志
- outputPatternAsHeader 默认值为 false; 如果为 true 则日志开头会打印 pattern 信息如：#logback.classic pattern: %d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n

```xml
<appender name="FILE" class="ch.qos.logback.core.FileAppender"> 
    <file>foo.log</file>
    <encoder><!--默认就是PatternLayoutEncoder类-->
        <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        <!-- this quadruples logging throughput --> 
        <immediateFlush>false</immediateFlush> <outputPatternAsHeader>true</outputPatternAsHeader>
    </encoder> 
</appender>
```

**注意不要在 logback 中使用相对路径配置日志文件路径**

> layout

layout 功能是将一个 event 事件转换成字符串，后通过 java.io.writer 将字符串写入目标对象中；

### Logger

Logger 是日志的记录器，能够配置指定的应用 context，定义日志级别，指定 appender；Logger 之间存在父子关系，其中根 Logger 用 root 标签表示，如下配置中，3 的父 Logger 是 2，2 的父 Logger 是根 Logger 1； 

```xml
<!-- 3-->
<logger name="com.pismery.basic.log" level="TRACE" additivity="true">
    <appender-ref ref="STDOUT"/>
</logger>
<!-- 2-->
<logger name="com.pismery.basic" level="INFO" additivity="false">
    <appender-ref ref="STDOUT"/>
</logger>
<!-- 1-->
<root level="ERROR">
    <appender-ref ref="STDOUT"/>
</root>
```

参数解释

- name: 指定包路径下的使用此 Logger 配置；
- level: 指定日志级别；若子 Logger 没有设置，默认使用父 Logger 的 level;
- additivity: 指定是否将日志信息向父亲传递；注意传递的日志信息，打印级别按子 Logger 的；


## 完整的配置示例

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <!--
       说明：
       1、日志级别及文件
           日志记录采用分级记录，级别与日志文件名相对应，不同级别的日志信息记录到不同的日志文件中
           例如：error级别记录到log_error_xxx.log或log_error.log（该文件为当前记录的日志文件），而log_error_xxx.log为归档日志，
           日志文件按日期记录，同一天内，若日志文件大小等于或大于2M，则按0、1、2...顺序分别命名
           例如log-level-2013-12-21.0.log
           其它级别的日志也是如此。
       2、文件路径
           若开发、测试用，在Eclipse中运行项目，则到Eclipse的安装路径查找logs文件夹，以相对路径../logs。
           若部署到Tomcat下，则在Tomcat下的logs文件中
       3、Appender
           FILEERROR对应error级别，文件名以log-error-xxx.log形式命名
           FILEWARN对应warn级别，文件名以log-warn-xxx.log形式命名
           FILEINFO对应info级别，文件名以log-info-xxx.log形式命名
           FILEDEBUG对应debug级别，文件名以log-debug-xxx.log形式命名
           stdout将日志信息输出到控制上，为方便开发测试使用
    -->
    <contextName>SpringBootDemo</contextName>
    <property name="LOG_PATH" value="D:\\JavaWebLogs" />
    <!--设置系统日志目录-->
    <property name="APPDIR" value="SpringBootDemo" />

    <!-- 日志记录器，日期滚动记录 -->
    <appender name="FILEERROR" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 正在记录的日志文件的路径及文件名 -->
        <file>${LOG_PATH}/${APPDIR}/log_error.log</file>
        <!-- 日志记录器的滚动策略，按日期，按大小记录 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/${APPDIR}/error/log-error-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>2MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <append>true</append>
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>error</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <!-- 日志记录器，日期滚动记录 -->
    <appender name="FILEWARN" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 正在记录的日志文件的路径及文件名 -->
        <file>${LOG_PATH}/${APPDIR}/log_warn.log</file>
        <!-- 日志记录器的滚动策略，按日期，按大小记录 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/${APPDIR}/warn/log-warn-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>2MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        
        <append>true</append>
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>warn</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <!-- 日志记录器，日期滚动记录 -->
    <appender name="FILEINFO" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 正在记录的日志文件的路径及文件名 -->
        <file>${LOG_PATH}/${APPDIR}/log_info.log</file>
        <!-- 日志记录器的滚动策略，按日期，按大小记录 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/${APPDIR}/info/log-info-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>2MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        
        <append>true</append>
        
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <!-- 此日志文件只记录info级别的 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>info</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>
    
    <!-- 日志记录器，日期滚动记录 FILEINFO 写法2-->
    <appender name="ROLLING" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_PATH}/${APPDIR}/log_info.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <!-- rollover daily -->
            <fileNamePattern>${LOG_PATH}/${APPDIR}/info/log-info-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!-- each file should be at most 100MB, keep 60 days worth of history, but at most 20GB -->
            <maxFileSize>2MB</maxFileSize>
            <maxHistory>60</maxHistory>
            <totalSizeCap>20GB</totalSizeCap>
        </rollingPolicy>
        <encoder>
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <!-- 此日志文件只记录info级别的 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>info</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>
    

    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <!--encoder 默认配置为PatternLayoutEncoder-->
        <encoder>
            <pattern>===%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger Line:%-3L - %msg%n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <!--此日志appender是为开发使用，只配置最底级别，控制台输出的日志级别是大于或等于此级别的日志信息-->
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>debug</level>
        </filter>
    </appender>
    
    <!--日志异步到数据库 --> 
    <appender name="DB" class="ch.qos.logback.classic.db.DBAppender">
        <connectionSource class="ch.qos.logback.core.db.DriverManagerConnectionSource">
           <!--连接池 --> 
            <dataSource class="com.mchange.v2.c3p0.ComboPooledDataSource">
                <driverClass>com.mysql.jdbc.Driver</driverClass>
                <url>jdbc:mysql://127.0.0.1:3306/databaseName</url>
                <user>usrname</user>
                <password>password</password>
            </dataSource>
        </connectionSource>
    </appender>
    
    
    <!-- show parameters for hibernate sql 专为 Hibernate 定制 --> 
    <logger name="org.hibernate.type.descriptor.sql.BasicBinder"  level="TRACE" />  
    <logger name="org.hibernate.type.descriptor.sql.BasicExtractor"  level="DEBUG" />  
    <logger name="org.hibernate.SQL" level="DEBUG" />  
    <logger name="org.hibernate.engine.QueryParameters" level="DEBUG" />
    <logger name="org.hibernate.engine.query.HQLQueryPlan" level="DEBUG" />  
    
    <!--myibatis log configure--> 
    <logger name="com.apache.ibatis" level="TRACE"/>
    <logger name="java.sql.Connection" level="DEBUG"/>
    <logger name="java.sql.Statement" level="DEBUG"/>
    <logger name="java.sql.PreparedStatement" level="DEBUG"/>
    
    
    <!-- 生产环境下，将此级别配置为适合的级别，以免日志文件太多或影响程序性能 -->
    <logger name="org.springframework" level="WARN" />
    <logger name="org.hibernate" level="WARN" />
    <root level="INFO">
        <appender-ref ref="FILEERROR" />
        <appender-ref ref="FILEWARN" />
        <appender-ref ref="FILEINFO" />

        <!-- 生产环境将请stdout,testfile去掉 -->
        <appender-ref ref="STDOUT" />
    </root>
</configuration>
```


