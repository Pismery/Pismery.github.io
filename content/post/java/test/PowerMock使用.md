---
title: "PowerMock使用"
discriptions: "PowerMock使用"
date: 2018-11-28T21:30:42+08:00
author: Pismery Liu
archives: "2018"
tags: [测试,Java]
categories: [Java]
showtoc: true
---
<!--more-->

# PowerMock

PowerMockito的优势在于能够mock静态方法，final方法，私有方法，构造函数，相当于弥补了mockito的不足。

> 基本使用

powerMockito具有两个重要的注解：

- @RunWith(PowerMockRunner.class)
- @PrepareForTest( { ClassWithEgStaticMethod.class })

两个注解当使用时必须成对使用。当需要Mock(静态,final，private)方法和使用whenNew方法时，需要使用这两个注解，其中PrepareForTest中的参数是被mock的方法所在的类。


> 注意事项

1. 因为兼容性Mockito要2.10.0以上的版本 并且powermock中的api-mockito2使用2.0以上的版本


> 示例

```
## pom.xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.0.3.RELEASE</version>
</parent>
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>    
        <artifactId>spring-boot-starter-test</artifactId>  ## Mockito->2.15.0
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.powermock</groupId>
        <artifactId>powermock-module-junit4</artifactId>
        <version>2.0.0-RC.4</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.powermock</groupId>
        <artifactId>powermock-api-mockito2</artifactId>  ## 注意是mockito2不是mockito
        <version>2.0.0-RC.4</version>
        <scope>test</scope>
    </dependency>
</dependencies>

```

```
public class Employee {
    private String fName;

    public String getfName() {
        return fName;
    }

    public void setfName(String fName) {
        this.fName = fName;
    }
}

public class EmployeeService {
    public EmployeeService() {

    }

    private String getEmployeeCount(Employee employee) {
        throw new UnsupportedOperationException();
    }

    public static String updateEmployee(Employee employee) {
        return "";
    }

    public final String saveEmployee(Employee employee) {
        return "";
    }

    public static final String deleteEmployee(Employee employee) {
        return "";
    }

    public String getEmployeeSum(Employee employee) {
        return getEmployeeCount(employee);
    }
    
    public String getEmployeeName() {
        Employee employee = new Employee();
        return employee.getfName();
    }
}

public class EmployeeController {
    private EmployeeService employeeService;

    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    public void holdLife(Employee employee) {
        System.out.println("saveEmployee: "+employeeService.saveEmployee(employee));
        System.out.println("getEmployeeSum: "+employeeService.getEmployeeSum(employee));
        System.out.println("updateEmployee: "+employeeService.updateEmployee(employee));
        System.out.println("deleteEmployee: "+employeeService.deleteEmployee(employee));
        System.out.println("getEmployeeName: "+employeeService.getEmployeeName());
    }
}
```

```
## Test

@RunWith(PowerMockRunner.class)
public class EmployeeControllerTest {

    @Test
    @PrepareForTest(EmployeeService.class)
    public void holdLife() throws Exception {
        EmployeeService employeeService = PowerMockito.mock(EmployeeService.class, Mockito
                .withSettings()
                .name("Mock_EmployeeService")
        );
        PowerMockito.mockStatic(EmployeeService.class);
        EmployeeController employeeController = new EmployeeController(employeeService);
        Employee employee = new Employee();
        employee.setfName("mock name");

        //mock private 方法
        when(employeeService.getEmployeeSum(employee)).thenCallRealMethod();
        when(employeeService, "getEmployeeCount",any()).thenReturn("mock get employee count");

        //mock new 方法
        when(employeeService.getEmployeeName()).thenCallRealMethod();
        whenNew(Employee.class).withNoArguments().thenReturn(employee);
        //mock final 方法
        when(employeeService.saveEmployee(employee)).thenReturn("mock save employee");
        //mock static 方法
        when(EmployeeService.updateEmployee(employee)).thenReturn("mock update employee");
        //mock static final 方法
        when(EmployeeService.deleteEmployee(employee)).thenReturn("mock delete employee");

        employeeController.holdLife(employee);

        Mockito.verify(employeeService).saveEmployee(employee);
    }
}

## 结果
saveEmployee: mock save employee
getEmployeeSum: mock get employee count
updateEmployee: mock update employee
deleteEmployee: mock delete employee
getEmployeeName: mock name
```