---
title: "ExchangeUtils"
discriptions: "ExchangeUtils"
date: 2018-12-12T21:58:47+08:00
author: Pismery Liu
archives: "2018"
tags: [工具类,Java]
categories: [Java]
showtoc: true
---

三种方式实现交换数组中两个数。

<!--more-->

> 代码

```Java
public class ExchangeUtils {

    /**
     * Exchange by ^=
     *
     * @param sources
     * @param indexX
     * @param indexY
     */
    public static void exchange(int[] sources, int indexX, int indexY) {
        AssertArgs(sources.length, indexX, indexY);

        if (indexX == indexY) //because self ^ self == 0
            return;

        sources[indexX] ^= sources[indexY];
        sources[indexY] ^= sources[indexX];
        sources[indexX] ^= sources[indexY];
    }

    /**
     * nomal exchange medthod
     *
     * @param sources
     * @param indexX
     * @param indexY
     */
    private static void exchange1(int[] sources, int indexX, int indexY) {
        AssertArgs(sources.length, indexX, indexY);

        int temp = sources[indexX];
        sources[indexX] = sources[indexY];
        sources[indexY] = temp;
    }

    /**
     * exchange without middle variable
     *
     * @param sources
     * @param indexX
     * @param indexY
     */
    private static void exchange2(int[] sources, int indexX, int indexY) {
        AssertArgs(sources.length, indexX, indexY);

        if (indexX == indexY)
            return;

        sources[indexX] = sources[indexX] + sources[indexY];
        sources[indexY] = sources[indexX] - sources[indexY];
        sources[indexX] = sources[indexX] - sources[indexY];
    }

    private static void AssertArgs(int size, int indexX, int indexY) {
        if (indexX < 0 || indexY < 0 || indexX >= size || indexY >= size)
            throw new IllegalArgumentException("indexX:" + indexX + ";indexY:" + indexY);
    }
}
```