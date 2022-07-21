---
title: "「LeetCode - 3」无重复字符的最长子串"
discriptions: "「LeetCode - 3」无重复字符的最长子串"
date: 2021-02-28T15:31:23+08:00
author: Pismery Liu
archives: "2021"
tags: [算法]
categories: []
showtoc: true
math: true
---

<!--more-->

# 算法 - 无重复字符的最长子串

题目要求： 

```txt
给定一个字符串 s，请你找出其中不含有重复字符的最长子串的长度。 

示例 1: 

入: s = "abcabcbb"
出: 3 
释: 因为无重复字符的最长子串是 "abc"，所以其长度为 3。

示例 2: 

入: s = "bbbbb"
出: 1
释: 因为无重复字符的最长子串是 "b"，所以其长度为 1。

示例 3: 

入: s = "pwwkew"
出: 3
释: 因为无重复字符的最长子串是 "wke"，所以其长度为 3。
    请注意，你的答案必须是子串的长度，"pwke" 是一个子序列，不是子串。

示例 4: 
入: s = ""
出: 0

提示： 
0 <= s.length <= 5 * 104 
s 由英文字母、数字、符号和空格组成 
```

## 子串与子序列

在开始解题前，我们先了解一下子串与子序列；

示例原字符串： abc

子串：

- a, b, c;
- ab, bc;
- abc;

子序列：

- a, b, c;
- ab, **ac**, bc;
- abc

子串和子序列的区别在于字符是否必须连续，子序列是从原字符串按顺序挑选出来的字符串；
子串则是从原字符串切割出来的连续的字符串；

解题时，我们往往最先想到暴力破解，暴力破解的关键在于遍历所有情况；下面我们分析子串和子序列遍历的复杂度，
同时建议直接记住结论，有助于我们分析时间复杂度；

子串是由原字符串切割出来的连续字符串，我们可以按子串的字符数目进行穷举：

- 只有一个字符的子串；（一共有 n 个）
- 只有两个字符的子串；（一共有 n - 1 个）
- ...
- 只有 n 个字符的子串；（一共有 1 个）

所以 n 个字符的字符串，计算子串总数公式如下

$$
   S = n + (n-1) + ... + 1
     = \cfrac{n * (n +1)}2
$$

子序列是从原字符串按顺序挑选出来的字符串，同理按子序列的字符数目进行穷举：

- 只有一个字符的子串；（一共有 $C_n^1$ 个）
- 只有两个字符的子串；（一共有 $C_n^2$ 个）
- ...
- 只有 n 个字符的子串；（一共有 $C_n^n$ 个）

所以 n 个字符的字符串，计算子序列总数公式如下

$$
   S = C_n^1 + C_n^2 + ... + C_n^n
     = 2^n - 1
$$


## 解法一：暴力穷举

思路：

- 穷举遍历所有子串；
- 判断子串是否有重复的字符，如果没有则更新返回结果，否则跳过进行下一个子串遍历；

时间复杂度：需要遍历 $\cfrac{n * (n +1)}2$ 次，每次需要判断是否有字符重复复杂度为 $O(n)$ ，总体复杂度 $O(n^3)$ 

代码实现如下：

```java
public int lengthOfLongestSubstring(String s) {
    int result = 0;
    if(s == null || s.length() == 0) {
        return result;
    }

    for(int strSize = 1; strSize <= s.length(); strSize++) {
        for(int beginIndex = 0; beginIndex <= s.length() - strSize; beginIndex++) {
            String subStr = s.substring(beginIndex, beginIndex + strSize);
            if(isUnique(subStr)) {
                result = Math.max(result, strSize);
                //如果当前字符数找到符合条件则可以跳过后续子串检验，进行下一个字符数遍历;
                break;
            }
        }
    }

    return result;
}

public boolean isUnique(String str) {
    boolean result = true;
    //....
    return result;
}
```

## 解法二：滑动窗口

遇到求子串问题，可以优先考虑滑动窗口解法；滑动窗口我们需要考虑两个问题；

- 窗口什么条件下需要扩大；
- 窗口什么条件下需要收缩；

滑动窗口需要两个指针分别指定窗口的首尾边界，窗口滑动的过程就是查找以首指针为起点的最长不重复子串；
当下一个字符已经在窗口内出现过，则表示窗口内字符串就是以当前首指针为首的最长不重复子串；此时收缩窗口，
即首指针向前移动，寻找下一个首指针的最长不重复子串；反之，窗口内未有下一个字符，则扩大窗口；

下面，我们需要分析使用什么数据结构存储窗口内的数据；对于窗口内的数据，需要操作有删除首节点，添加尾节点，判断
是否存在；看到首尾节点的操作总会第一时间想到 LinkedList；但注意的是还需要判断是否存在，LinkedList 需要 $O(n)$ 的复杂度完成此操作；
最后使用 HashSet 则可以 $O(1)$ 时间内执行上述三个操作；

时间复杂度：使用滑动窗口遍历次数最多是尾指针遍历一遍和首指针遍历一遍；采用 HashSet 能
够 $O(1)$ 复杂度完成窗户的数据维护，最后整体复杂度为 $O(n)$;

代码实现如下：

```java
public int lengthOfLongestSubstring(String s) {
    int result = 0;
    if(s == null || s.length() == 0) {
        return result;
    }
    
    HashSet<Character> set = new HashSet<>();
    for(int left=0, right = 0; right < s.length(); right++) {
        Character curChar = s.charAt(right);
        while(set.contains(curChar)) {
            set.remove(s.charAt(left));
            left++;    
        } 

        set.add(curChar);
        result = Math.max(result, set.size());
    }

    return result;
}
```

上述实现还有优化空间，我们看看下面这种情况；

当输入字符串为 "abcdde"；窗口扩展至 "abcd" 时，下一个字符 "d" 存在于窗口内了，此时需要收缩窗口；而我们
需要一次次收缩为 "bcd", "cd", "d", ""；那么如何收缩窗口一次到位呢？我们需要 HashMap 记录窗口每个字符的位置；
Key 为窗口字符，Value 为字符所处位置；

注意事项：为了收缩一步到位，我们使用了 HashMap 存储数据；对于 HashMap 的维护，我们不再移除 HashMap 的数据。
否则还需要移除跳过的字符，复杂度会更高；而是计算首指针时通过 Max 取得下一个首指针位置；示例，当输入字符串
"abcdbe", 窗口 "cd", 下一个字符 b 在 HashMap 中存在但是位置处于首指针的左侧，不需要回滚回去；

代码实现如下：

```java
public int lengthOfLongestSubstring(String s) {
    int result = 0;
    if(s == null || s.length() == 0) {
        return result;
    }
    
    HashMap<Character, Integer> map = new HashMap<>();
    for(int left=0, right = 0; right < s.length(); right++) {
        Character curChar = s.charAt(right);
        if (map.containsKey(curChar)) {
            left = Math.max(left, map.get(curChar) + 1);
        } 

        map.put(curChar,right);
        result = Math.max(result, right - left + 1);
    }

    return result;
}
```

## 总结

- 遍历字符串子串的时间复杂度为 $O(\cfrac{n * (n +1)}2)$
- 遍历字符串子序列的时间复杂度为 $O(2^n)$
- 子串问题可以优先考虑滑动窗口方式
- HashSet 能够以 $O(1)$ 复杂度实现添加，删除，判断重复操作；