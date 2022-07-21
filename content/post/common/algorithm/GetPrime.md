---
title: "GetPrime"
discriptions: "GetPrime"
date: 2019-10-01T20:26:55+08:00
author: Pismery Liu
archives: "2019"
tags: [算法]
categories: []
showtoc: true
---

<!--more-->

# 算法 - 素数

> 题目

求小于等于 maxNum 中的所有素数；「ps: 素数又称质数，质数是指在大于1的自然数中，除了1和它本身以外不再有其他因数的自然数。」

> 题解

思路：遍历 2 至 maxNum 依次判断是否是素数；

第一步，写出判断一个数是否是素数的方法；按定义可以很快写出如下判断素数的代码；

```Java
public static boolean isPrime(int num) {
    if(num < 2) {
        return false;
    }
    for (int j = 2; j <= num; j++) {
        if (num % j == 0 && num != j) { //如果存在除了本身还有其他因素
            return false;
        }
    }
    return true;
}
```

下面优化一下判断素数的函数，其实判断是否是素数，只需要确认区间 [2,√num] 没有其他因数即可；原因是如果 a 是 num 的因数，则 √a 也是 num 的因数，而 num 最大的因数就是其本身，所以如果还有其他因数，那么一定能够在区间 [2,√num] 找到；

```Java
public static boolean isPrime(int num) {
    if (num < 2)
        return false;
    //注意 j<= Math.sqrt(num) 必须有=号  num = 4 9 16
    double sqrt = Math.sqrt(num);
    for (int j = 2; j <= sqrt; j++) {
        if (num % j == 0 && num != j) {
            return false;
        }
    }
    return true;
}
```

下面再优化一下，能否再减少遍历的次数呢？我们知道如果 a 是素数，那么 n（n > 1） 倍的 a 都肯定不是素数；例如 2 是素数，则 4, 6, 8, 10 等都不会是素数；因此我们可先判断 num 是否被 2 整除；这样后面的遍历则可以以 2 为单位进行遍历；

```Java
public static boolean isPrime(int num) {
    if (num < 2)
        return false;
    if (num == 2)
        return true;
    if (num % 2 == 0)
        return false;

    for (int i = 3; i * i <= num; i += 2) {
        if (num % i == 0)
            return false;
    }
    return true;
}
```

判断数 num 是否为素数优化的差不多了，接下来就直接遍历获取指定区间内的所有素数了；

```Java
public static List<Integer> getPrime(int maxNum) {
    List<Integer> result = new ArrayList<>();
    for (int i = 2; i <= maxNum; i++) {
        if (isPrime(i)) {
            result.add(i);
        }
    }
    return result;
}
```

下面也优化一下遍历函数，很自然想到跟上面优化一样，可以将 2 做单独处理，然后就能以 2 为单位遍历；

```Java
public static List<Integer> getPrime(int maxNum) {
    List<Integer> result = new ArrayList<>();
    if (maxNum < 2) {
        return result;
    }

    result.add(2);

    for (int i = 3; i <= maxNum; i += 2) {
        if (isPrime(i))
            result.add(i);
    }
    return result;
}
```

最后，通过搜索资料发现还有一种筛选方式，可减少更多的遍历次数；思路如下：

1. 所有的自然数都可以这么表示：6N, 6N + 1, 6N + 2, 6N + 3, 6N + 4, 6N + 5;
2. 而显然除了 2 和 3 以外，6N, 6N + 2, 6N + 3, 6N + 4 都不可能是素数，都有因数 2；
3. 6N + 5 也可以表示为 6N - 1；所以只有 6N + 1 和 6N - 1 才有可能是素数；

经过上面的分析，我们就可以以 6 为单位进行遍历了；

```Java
public static List<Integer> getPrimeBy6N_1(int maxNum) {
    ArrayList<Integer> result = new ArrayList<>();
    if (maxNum >= 2)
        result.add(2);
    if (maxNum >= 3)
        result.add(3);

    int i = 0;
    while (6 * i - 1 <= maxNum || 6 * i + 1 <= maxNum) {
        if (6 * i - 1 <= maxNum && isPrime2(6 * i - 1))
            result.add(6 * i - 1);
        if (6 * i + 1 <= maxNum && isPrime2(6 * i + 1))
            result.add(6 * i + 1);
        i++;
    }

    return result;
}
```