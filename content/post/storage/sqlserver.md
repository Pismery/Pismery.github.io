---
title: "Sqlserver"
discriptions: "Sqlserver"
date: 2019-04-21T21:03:34+08:00
author: Pismery Liu
archives: "2019"
tags: [database]
categories: []
showtoc: true
---

sqlServer 的基本操作，用于日常工作查询； 

<!--more-->



## View 操作

```sql
-- create view
IF EXISTS (select 1 from sys.objects where name= 'VMName' and type = 'V')
	DROP VIEW VMName
GO
CREATE VIEW VMName AS
SELECT * FROM TableName WHERE ....
GO

-- drop view
IF EXISTS (select 1 from sys.objects where name= 'VMName' and type = 'V')
	DROP VIEW VMName
GO
```


## Procedure 操作

```sql
--create procedures
create proc proc_logRecord_pismery
 @fileName varchar(200),
 @stepName varchar(50)
as
begin
	update #pismery_log set executeTime = t1.excuteTime
	from 
	(
		select a.logid,datediff(mi,a.startTime,getdate()) as excuteTime
		from 
		(
			select top 1 logId,startTime
			from #pismery_log
			order by logid desc
		) a
	)t1,#pismery_log t2
	where t1.logid = t2.logid;
	insert into #pismery_log(fileName,stepName,startTime) values (@fileName,@stepName,getdate());
end

--check procedures
sp_helptext proc_logRecord_pismery	

--drop procedures
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[procedureName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[procedureName]
GO 

-- search in precedures
select a.name, m.definition from sysobjects a, sys.sql_modules m
where a.id = m.object_id and a.xtype = 'P' and lower(m.definition) like '%content%'

```


## Sequence 操作

```sql
-- 创建 sequence
create sequence XXXSeqName
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 9999999999999
CYCLE  

-- 查询 sequence 
SELECT * FROM sys.sequences where name = 'XXXSeqName'

-- 删除 sequence 
DROP sequence XXXSeqName

-- 获取 sequence 值
select NEXT VALUE FOR XXXSeqName

-- 根据表重制 sequence 值
declare @restart_sequence int,
@sql varchar(1024);	
set @restart_sequence=(select isnull(max([Id]), 0)+1 from dbo.TblName);
set @sql ='alter sequence dbo.XXXSeqName restart with '+   cast(@restart_sequence as varchar(10))
exec(@sql) 

```

> 示例

```
if exists (SELECT 1 FROM sys.sequences where name = 'MySeq')
    DROP sequence MySeq

create sequence MySeq
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 9999999999999
CYCLE  

```

## Table 操作

```
查看表：exec sp_help 表名
查看列： exec sp_columns 表名
查看列：select * from information_schema.columns where table_name = '表名' 

添加列：alter table 表名 add 列名 varchar(55)
删除列：alter table 表名 drop column 列名
添加主键： alter table TblName ADD CONSTRAINT pk_name primary key(pkColumn)
修改列名称：exec sp_rename '表名.字段名' , '新名', 'column'
修改列类型：alter table 表名 alter column 列名 varchar(22)
```

> 示例

```sql

-- 添加列
if not exists (select top 1 1 from syscolumns where id=object_id('TblName') and name='ColumnName')
	alter table TblName add ColumnName varchar(5)

if exists (select top 1 1 from syscolumns where id=object_id('TblName') and name='ColumnName')
	alter table TblName drop COLUMN ColumnName
alter table TblName add TreatyType varchar(5)

-- 添加非空列
alter table [table] add NewColumn varchar(10)   	--添加一个可以为空的新列
go
update [table] set NewColumn=''			--设置新列的值为''
go
ALTER TABLE [table] ALTER COLUMN
NewColumn varchar(10) not null				--设置新列为非空
go

	
-- 添加主键
if not exists (select top 1 1 from sysobjects where parent_obj in (select id from sysobjects where name='TblName') and xtype='pk')
	ALTER TABLE TblName ADD CONSTRAINT pk_name primary key(pkColumn)
	
if exists (select top 1 1 from sysobjects where parent_obj in (select id from sysobjects where name='TblName') and xtype='pk')
    ALTER TABLE TblReinGBNParm drop CONSTRAINT pk_name 
ALTER TABLE TblName ADD CONSTRAINT pk_name primary key(pkColumn)
	

```


## 自带函数操作

### 查询表的数据行数

```sql
SELECT  a.name, b.rows
FROM sysobjects AS a 
INNER JOIN sysindexes AS b ON a.id = b.id
WHERE (a.type = 'u') AND (b.indid IN (0, 1))
ORDER BY b.rows DESC


sp_spaceused tableName
```

### 跨服务器跨数据库表传输操作

> 从其他数据库导入本地  

```sql
SELECT * 
INTO localTableName 
FROM openrowset('SQLOLEDB' , 'ServerName' ; 'account' ; 'password' ,DatabaseName.dob.remoteTableName);
```

> 把本地表导入远程表 

```sql
insert openrowset( 'SQLOLEDB ', 'sql服务器名 '; '用户名 '; '密码 ',数据库名.dbo.表名) 
select *from 本地表 
```


### Date 函数

函数 | 描述
---|---
GETDATE()	| 返回当前日期和时间
DATEPART()	| 返回日期/时间的单独部分
DATEADD()	| 在日期中添加或减去指定的时间间隔
DATEDIFF()	| 返回两个日期之间的时间
CONVERT()	| 用不同的格式显示日期/时间

### Convert 用法

> 用法

1. CONVERT() 函数是把日期转换为新数据类型的通用函数。
2. CONVERT() 函数可以用不同的格式显示日期/时间数据


> 语法

```sql
CONVERT(data_type(length),data_to_be_converted,Style ID)
```


> style 参照表

Style ID | Style 格式
---|---
100 | 或者 0	mon dd yyyy hh:miAM （或者 PM）
101	| mm/dd/yy
102	| yy.mm.dd
103	| dd/mm/yy
104	| dd.mm.yy
105	| dd-mm-yy
106	| dd mon yy
107	| Mon dd, yy
108	| hh:mm:ss
109 | 或者 9	mon dd yyyy hh:mi:ss:mmmAM（或者 PM）
110	| mm-dd-yy
111	| yy/mm/dd
112	| yymmdd
113 | 或者 13	dd mon yyyy hh:mm:ss:mmm(24h)
114	| hh:mi:ss:mmm(24h)
120 | 或者 20	yyyy-mm-dd hh:mi:ss(24h)
121 | 或者 21	yyyy-mm-dd hh:mi:ss.mmm(24h)
126	| yyyy-mm-ddThh:mm:ss.mmm（没有空格）
130	| dd mon yyyy hh:mi:ss:mmmAM
131	| dd/mm/yy hh:mi:ss:mmmAM



### Date to string

```
select CONVERT(VARCHAR(23),GETDATE(),101) AS [MM/DD/YYYY] 
## 结果
MM/DD/YYYY
11/20/2018


select 
    Case 
        When isDate(DateColmun)=0 Then cast(null as datetime) 
        Else cast(GETDATE() as VARCHAR(23)) 
    END AS [String Date] 
## 结果
String Date
Nov 20 2018  9:25AM
```