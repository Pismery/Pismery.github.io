---
title: "GetParameterName"
discriptions: "GetParameterName"
date: 2019-04-22T21:08:54+08:00
author: Pismery Liu
archives: "2019"
tags: [工具类,Java]
categories: [Java]
showtoc: true
---

近期，自己在实现 Spring MVC 功能时，发现通过 Java 反射不能够获取到方法的参数名称；因此，查阅了一下资料，特此记录

<!--more-->

# 获取参数名称

Java 文件经过编译生成的 class 文件，将方法的参数名称丢弃了；这也就导致通过 Java 的反射机制无法直接获取到方法的参数名；Java 8 以后可通过设置编译器参数 -parameters 能够编译生成的 class 文件包含参数表，这样就能够通过反射机制直接获取参数名；若没有 Java 8，则可通过字节码工具包 ASM 或 Javassist 获取；

下面分别演示三种方式获取方法的参数名；

1. Java8 + 设置编译器参数 -parameters + 反射 Method.getParameters();
2. 使用 javassist
3. 使用 asm



## 设置编译器参数

> idea 设置方式

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190418214458.png)

> mavan 设置方式

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <version>3.3</version>
    <configuration>
        <source>1.8</source>
        <target>1.8</target>
        <compilerArgs>
            <arg>-parameters</arg>
        </compilerArgs>
    </configuration>
</plugin>
```


```Java
package org.pismery.mvc.util;

import java.lang.reflect.Method;
import java.lang.reflect.Parameter;

public class ParameterNameUtil {

    /**
     * 获取指定类指定方法的参数名
     * @param method 要获取参数名的方法
     * @return 按参数顺序排列的参数名列表，如果没有参数，则返回null
     */
    public static String[] getMethodParameterNamesJava8(final Method method) {
        Parameter[] parameters = method.getParameters();
        if (parameters == null || parameters.length == 0) {
            return null;
        }
        String[] result = new String[parameters.length];
        for (int i = 0, length = parameters.length; i < length; i++) {
            result[i] = parameters[i].getName();
        }
        return result;
    }
}

```

## 使用 javaassist

```Java
package org.pismery.mvc.util;

import javassist.*;
import javassist.bytecode.CodeAttribute;
import javassist.bytecode.LocalVariableAttribute;
import javassist.bytecode.MethodInfo;

import java.lang.reflect.Method;
import java.lang.reflect.Modifier;

public class ParameterNameUtil {

   
    /**
     * 获取指定类指定方法的参数名
     *
     * @param method 要获取参数名的方法
     * @return 按参数顺序排列的参数名列表，如果没有参数，则返回null
     */
    public static String[] getParameterNamesByJavaAssist(Method method) {
        ClassPool classPool = ClassPool.getDefault();
        classPool.insertClassPath(new ClassClassPath(method.getDeclaringClass()));
        String[] result = new String[method.getParameters().length];
        try {
            CtClass ctClass = classPool.get(method.getDeclaringClass().getName());
            CtMethod ctMethod = ctClass.getDeclaredMethod(method.getName());


            MethodInfo methodInfo = ctMethod.getMethodInfo();
            CodeAttribute codeAttribute = methodInfo.getCodeAttribute();
            LocalVariableAttribute attr = (LocalVariableAttribute) codeAttribute
                    .getAttribute(LocalVariableAttribute.tag);

            if (attr == null) {
                return null;
            }

            // 非静态的成员函数的第一个参数是this
            int pos = Modifier.isStatic(ctMethod.getModifiers()) ? 0 : 1;
            for (int i = 0, len = ctMethod.getParameterTypes().length; i < len; i++) {
                result[i] = attr.variableName(i + pos);
            }
        } catch (NotFoundException e) {
            e.printStackTrace();
        }

        return result;
    }
}
```


## 使用 Asm5

```Java
package org.pismery.mvc.util;

import jdk.internal.org.objectweb.asm.*;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.Arrays;

public class ParameterNameUtil {
    /**
     * 获取指定类指定方法的参数名
     *
     * @param clazz  要获取参数名的方法所属的类
     * @param method 要获取参数名的方法
     * @return 按参数顺序排列的参数名列表，如果没有参数，则返回null
     */
    public static String[] getMethodParameterNamesByAsm5(final Method method) {
        Class<?> clazz = method.getDeclaringClass();
        final Class<?>[] parameterTypes = method.getParameterTypes();
        if (parameterTypes == null || parameterTypes.length == 0) {
            return null;
        }
        // 获取参数类型
        final Type[] types = new Type[parameterTypes.length];
        for (int i = 0; i < parameterTypes.length; i++) {
            types[i] = Type.getType(parameterTypes[i]);
        }

        final String[] parameterNames = new String[parameterTypes.length];

        String className = clazz.getSimpleName() + ".class";
        InputStream is = clazz.getResourceAsStream(className);
        try {
            ClassReader classReader = new ClassReader(is);
            classReader.accept(new ClassVisitor(Opcodes.ASM5) {
                //当访问方法时，调用以下重写方法
                @Override
                public MethodVisitor visitMethod(int access, String name, String desc, String signature, String[] exceptions) {
                    // 只处理指定的方法 method
                    Type[] argumentTypes = Type.getArgumentTypes(desc);
                    if (!method.getName().equals(name) || !Arrays.equals(argumentTypes, types)) {
                        return null;
                    }
                    return new MethodVisitor(Opcodes.ASM5) {
                        AtomicInteger integer = new AtomicInteger();

                        // 当访问方法参数时，调用以下重写方法
                        @Override
                        public void visitParameter(String name, int index) {
                            parameterNames[integer.getAndIncrement()] = name;
                        }
                    };

                }
            }, 0);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return parameterNames;
    }
}
```


