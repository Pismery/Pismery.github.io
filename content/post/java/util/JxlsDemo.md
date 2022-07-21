---
title: "JxlsDemo"
discriptions: "JxlsDemo"
date: 2019-05-12T22:35:32+08:00
author: Pismery Liu
archives: "2019"
tags: [工具类,Java]
categories: [Java]
showtoc: true
---
<!--more-->


# JXLS

JXLS 是 Java 导出 Excel 的一个工具包，尽管 POI 工具包已经可以满足所有的需求，但是有时候操作还是比较复杂，且有一定的代码量，而 JXLS 在生成 Excel 方面显得更加方便好用；下面开始介绍 JXLS 工具包

基本介绍：

1. 可以通过 Java 或 Excel 批注的方式编写指令；
2. 在 Excel 的第一个单元格需要指定模板范围；
3. 单元格可通过 ${} 方式获取上下文对象的值；
4. 指令中可通过 "" 方式获取上下文；



## 指令介绍

JXLS 中其采用了 [Apache JEXL](http://commons.apache.org/proper/commons-jexl/reference/syntax.html) 指令表达式，下面介绍一些常用的指令；

### jx:each 循环

```
jx:each(items="employees" var="employee" lastCell="D4" area="[A4，D4]" select="employee.payment > 2000")
```

> 参数介绍

参数名称 | 示例 | 介绍
---|---|---
items | items="employees" | 表示遍历上下文中的集合对象 employees
var | var="employee" | 表示遍历值设为 employee,在遍历区域可以通过 ${employee} 方式访问
lastCell | lastCell="D4" | 表示指令的结束位置
direaction | direction ="RIGHT" | 输出的方向向下(DOWN)或向右(RIGHT),默认为DOWN
area | areas=["A8:F8","A13:F13"] | 循环的区域，多个可用 「,」 分隔
select | select="employee.payment > 2000" | 过滤条件
groupBy | groupBy="name" | 依据 employee 中 name 进行分组，分组后的集合可通过 nameGroup.items 来获取;
groupOrder | groupOrder="asc" | 指定分组排序(‘desc’ or ‘asc’) 
multisheet | multisheet ="sheets" | 循环上下文中的 sheets 对象，指定后会产生多个 sheet，指定后 each 的维度会变为 sheet，不需要指定 area；
shiftMode | shiftMode ="adjacent"| 	adjacent 指定后通过添加行的方式向指定方向输出，inner: 则为通过添加单元格的方式向指定方向输出，默认为inner；

### jx:if 条件判断

```
jx:if(condition="employee.payment <= 20000", lastCell="E9", areas=["A9:E9","A18:E18"])
```

> 参数介绍

参数名称 | 示例 | 介绍
---|---|---
condition | condition="employee.payment <= 20000" | if 条件判断表达式
lastCell | lastCell="E9" | 指令结束位置
areas | areas=["A9:E9","A18:E18"] | 如果为 true 使用 A9:E9 单元格模板渲染，反之使用 A18:E18；

### jx:updateCell 动态输出公式

```
jx:updateCell(lastCell="E4" updater="totalCellUpdater")
```

> 参数介绍

参数名称 | 示例 | 介绍
---|---|---
updater | updater="totalCellUpdater" | totalCellUpdater 是上下文中的一个对象，并且该对象必须实现 CellDataUpdater 接口

> 示例 

```
static class TotalCellUpdater implements CellDataUpdater{
    /**
    * cellData 批注对应的单元格
    * targetCell 输出的单元格
    * context  模板中的上下文通过getVar(变量名)来获取传入的对象
    */
    @Override
    public void updateCellData(CellData cellData, CellRef targetCell, Context context) {
        if( cellData.isFormulaCell() && cellData.getFormula().equals("SUM(E2)")){
            String resultFormula = String.format("SUM(E2:E%d)", targetCell.getRow());
            cellData.setEvaluationResult(resultFormula);
        }
    }
}
```

### jx:grid 输出一个表格

```
jx:grid(lastCell="A4" headers="headers" data="data" areas=[A3:A3, A4:A4] 
```

> 参数介绍

参数名称 | 示例 | 介绍
---|---|---
headers | headers="headers" | 循环的表头内容为List ，表头和表体没有必然的关系，可以多一列也可以少一列
data | data="datas" | 循环的表体内容为List<List>，当为 javabean 时 java 代码中需指定读取的属性名称
formatCells | formatCells="BigDecimal:C1,Date:D1" | 表示 BigDecimal 采用 C1 单元格方式渲染，Date 类型使用 D1 单元格方式渲染

> Java 示例

```Java
try(InputStream is = GridCommandDemo.class.getResourceAsStream("grid_template.xls")) {
    try(OutputStream os = new FileOutputStream("grid_output2.xls")) {
        Context context = new Context();
        context.putVar("headers", Arrays.asList("Name", "Birthday", "Payment"));
        context.putVar("data", employees);
        //当循环的表体为javabean时指定读取的属性，Sheet2!A1表示输出开始的位置
        JxlsHelper.getInstance().processGridTemplateAtCell(is, os, context, "name,birthDate,payment,bonus", "Sheet2!A1");
    }
}
```

## 完整示例

下面展示两种常用的使用方式，更多的使用 Demo 可参考[官方 Demo 仓库](https://bitbucket.org/leonate/jxls/src/master/)

> Maven

```xml
<dependency>
    <groupId>org.jxls</groupId>
    <artifactId>jxls</artifactId>
    <version>2.6.0</version>
</dependency>
<dependency>
    <groupId>org.jxls</groupId>
    <artifactId>jxls-poi</artifactId>
    <version>1.2.0</version>
</dependency>
<dependency>
    <groupId>org.jxls</groupId>
    <artifactId>jxls-jexcel</artifactId>
    <version>1.0.9</version>
</dependency>
```

> Model Bean

```Java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Department {
    private String name;
    private Employee chief;
    private List<Employee> staff = new ArrayList<>();
    private String link;
}


@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Employee {
    private String name;
    private Integer years;
    private Date birthDate;
    private BigDecimal payment;
    private BigDecimal bonus;
}
```


### Grid Demo

> Excel 模板

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190512221631.png)

> Java 

```Java
public class JXLSUtil {

    public static final String TEMPLATE_PATH = System.getProperty("user.dir") + "/src/main/resources/template/";
    public static final String REPORT_PATH = System.getProperty("user.dir") + "/src/main/resources/report/";

    public static void generateTableExcel(List<Employee> data) throws IOException {
        List<String> headers = Arrays.asList("Name", "BirthDate", "Payment", "Bonus");
        String objectProps = "name,birthDate,payment,bonus";
        try (InputStream is = new FileInputStream(new File(TEMPLATE_PATH, "simple_exporter_template.xlsx"))) {
            try (OutputStream os = new FileOutputStream(new File(REPORT_PATH,"simple_exporter_report.xlsx"))) {
                SimpleExporter simpleExporter = new SimpleExporter();
                simpleExporter.registerGridTemplate(is);
                simpleExporter.gridExport(headers, data, objectProps, os);
            }
        }
    }
}
```

```Java

public class JXLSUtilTest {
    @Test
    public void generateTableExcel() throws IOException {
        //Given
        List<Employee> staff = Arrays.asList(
                buildEmployee("IQ Chan1", new Date(), new BigDecimal(10000.01), new BigDecimal(0.15)),
                buildEmployee("IQ Chan2", new Date(), new BigDecimal(20000.05), new BigDecimal(0.25))
        );
        //When
        JXLSUtil.generateTableExcel(staff);
        //Then
    }
    
    private static Employee buildEmployee(String name, Date birthdate, BigDecimal payment, BigDecimal bonus) {
        return Employee.builder()
                .name(name)
                .birthDate(birthdate)
                .years(1)
                .payment(payment)
                .bonus(bonus)
                .build();
    }
}
```

> 运行结果

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190512222012.png)

### Each and IF 指令示例

> Excel 模板

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190512222620.png)

> Java 

```Java
public class JXLSUtil {

    public static final String TEMPLATE_PATH = System.getProperty("user.dir") + "/src/main/resources/template/";
    public static final String REPORT_PATH = System.getProperty("user.dir") + "/src/main/resources/report/";

    public static void generateExcel(Map<String, Object> model, String templateName, String reportName) throws IOException {
        try (InputStream is = new FileInputStream(new File(TEMPLATE_PATH, templateName))) {
            File reportPath = new File(REPORT_PATH);
            if (!reportPath.exists())
                reportPath.mkdir();

            try (OutputStream os = new FileOutputStream(new File(REPORT_PATH, reportName))) {
                Context ctx = new Context();
                model.forEach(ctx::putVar);
                JxlsHelper.getInstance().processTemplate(is, os, ctx);
            }
        }
    }
}
```

```Java
public class JXLSUtilTest {
    @Test
    public void generateExcel_each_if_command() throws IOException {
        //Given
        List<Employee> hrStaff = getStaffList("IQ Chan1", "IQ Chan2");
        List<Employee> itStaff = getStaffList("Pismery1", "Pismery2");
        Employee hr_chief = buildEmployee("HR Chief", new Date(), new BigDecimal(30000.05), new BigDecimal(0.5));
        Employee it_chief = buildEmployee("IT Chief", new Date(), new BigDecimal(30000.05), new BigDecimal(0.5));
        List<Department> departmentList = Arrays.asList(
                buildDepartment("HR", hr_chief, "HR Link", hrStaff),
                buildDepartment("IT", it_chief, "IT Link", itStaff)
        );
        Map<String, Object> model = new HashMap<>();
        model.put("departments", departmentList);
        model.put("employees", hrStaff);
        //When
        JXLSUtil.generateExcel(model, "each_if_demo_template.xlsx","each_if_demo_report.xlsx");
        //Then
    }

    @NotNull
    private List<Employee> getStaffList(String staff1, String staff2) {
        return Arrays.asList(
                buildEmployee(staff1, new Date(), new BigDecimal(10000.01), new BigDecimal(0.15)),
                buildEmployee(staff2, new Date(), new BigDecimal(20000.05), new BigDecimal(0.25))
        );
    }


    private static Employee buildEmployee(String name, Date birthdate, BigDecimal payment, BigDecimal bonus) {
        return Employee.builder()
                .name(name)
                .birthDate(birthdate)
                .years(1)
                .payment(payment)
                .bonus(bonus)
                .build();
    }

    private static Department buildDepartment(String name, Employee chief, String link, List<Employee> staff) {
        return Department.builder()
                .name(name)
                .chief(chief)
                .link(link)
                .staff(staff)
                .build();
    }
}
```

> 运行结果

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190512222945.png)