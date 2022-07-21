---
title: "HashMap"
discriptions: "HashMap"
date: 2019-10-08T22:08:29+08:00
author: Pismery Liu
archives: "2019"
tags: [数据结构]
categories: [Java]
showtoc: true
---

<!--more-->

# HashMap 详解

本篇文章将围绕下面几个问题展开：

1. HashMap 的内部数据结构;
2. HashMap 中 put 方法的过程;
3. HashMap 中 hash 方法实现方式;
4. HashMap 中扩容的过程;

## HashMap 的内部数据结构是怎么样的？

在 Java 8 中 HashMap 采用的是数组 + 链表的形式来存储数据的；由于当链表过长时，会导致查询时间复杂度退化到 O(N)，Java 8 实现了当链表长度大于等于 TREEIFY_THRESHOLD = 8 时，会将链表转化成红黑树；从而实现查找时间复杂度为 O(logN);下面是一张模拟 HashMap 数据结构的示意图；

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191007202642.png)

数组 + 链表的数据结构代码化，大概如下

```Java
Class Structure {
    Node[] nodeList;
    
}

Class Node {
    private Object key;
    private Object value;
    private Node next;
}
```

HashMap 中具体实现如下：

```Java
public class HashMap<K,V> extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable {
    
    transient Node<K,V>[] table;
    ...
    static class Node<K,V> implements Map.Entry<K,V> {
        final int hash;
        final K key;
        V value;
        Node<K,V> next;
    
        ...
    }
}
```

## HashMap 中 put 方法的过程

1. 计算 Key 的 Hash 值，根据 Hash 值计算下标；
2. 如果没有发生哈希碰撞，则直接放入数组中；
3. 如果发生了碰撞，则链接到碰撞节点下的链表或树中；
4. 如果链接到链表后，超过了树化阈值 (TREEIFY_THRESHOLD = 8) 则将链表转化成红黑树；
5. 如果节点已经存在即 Key 已存在，则替换原来的 value;
6. 如果加入节点后，数据容量超过了阈值（容量 * 加载因子）, 则进行扩容操作；

源码解读：

```Java
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    
    if ((tab = table) == null || (n = tab.length) == 0) //初始化 HashMap
        n = (tab = resize()).length;
    if ((p = tab[i = (n - 1) & hash]) == null) //如果没有发生哈希碰撞   
        tab[i] = newNode(hash, key, value, null);
    else {
        Node<K,V> e; K k;
        
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k)))) //如果 key 在数组节点中已存在； 
            e = p;
        else if (p instanceof TreeNode) //如果已经是红黑树
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else { //如果是链表结构
            for (int binCount = 0; ; ++binCount) {
                if ((e = p.next) == null) { //加入到链表末尾
                    p.next = newNode(hash, key, value, null);
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash); //如果链表超过阈值，转化为红黑树；
                    break;
                }
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    break; //如果 key 在链表节点中存在
                p = e;
            }
        }
        
        // e != null 表示 key 值已存在 Map 中的原节点的值；
        // e == null 表示 key 不存在于 Map 中；
        if (e != null) { 
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                // 如果 key 值已存在，则替换 value
                e.value = value;
            afterNodeAccess(e);
            return oldValue;
        }
    }
    ++modCount;
     //如果加入节点后超过阈值，则进行扩容；
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```

## HashMap 中 hash 方法实现方式

HashMap 中的 hash 方式源码如下：

```Java
// a >>> b 表示将值 a 不带符号的右移 b 位
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

代码大家基本都能看懂，返回 key 的 hashcode 值 h 与 (h >>> 16) 进行异或操作；但是这样做的目的是什么呢?

先说结论，目的是为了是的 hash 后计算数组下标会分布的更加均匀；

首先需要先了解 HashMap 是如何通过 hash 值计算出数组下标的；计算数组下标算法要达到三个要求：

1. 下标值不能数组越界
2. 计算出得下标值要覆盖数组中得所有位置；
3. 足够高效

要达到第一，第二点，最简单得实现方式是取余操作：hash % n（数组大小），但是这并不满足高效得要求；下面看看 HashMap 的实现方式：

```Java
if ((p = tab[i = (n - 1) & hash]) == null) //如果没有发生哈希碰撞    
    tab[i] = newNode(hash, key, value, null);
```

从上面源码中可以看出 HashMap 采用 (n - 1) & hash 的操作计算数组下标的；而使用这种方式且满足第一点和第二点要求，数组大小 n 必须是 2 的指数幂次； 这样(n - 1) 的二进制值除了最高位是 0 低位全是
1；算法计算逻辑如下：

```
16：  1 1111 ==> 15:   0 1111
32:  11 1111 ==> 31:  01 1111
64: 111 1111 ==> 63: 011 1111

    1101 0101 1001 1111 (hash)
^   0000 0000 0000 1111 (n - 1 = 15) 
------------------------
    0000 0000 0000 1111 (i = 15)
```

(n-1) & hash 的计算效率足够高；此时还需要解决哈希碰撞的问题，哈希碰撞无法完全避免，但可以通过算法减少哈希碰撞；这就是 HashMap 中 hash 方法要达到的目的；

使用 HashMap 时大部分时候数据量不会超过 65535 个；如果直接将 key 的 hashCode 作为 hash 值则其高位的值无法得到充分的利用，HashMap 通过位移操作使得 hashCode 高位与低位进行了一次异或运算，使得高位的数值也参与数组下标计算当中，从而实现 hash 值更加均衡；

为什么是异或运算，不是与运算，或运算？ 因为与允运算结果偏向于 0，或运算结果偏向于 1；这使得结果不够均衡；

```
## 异或运算      ## 与运算         ## 或运算     
1 ^ 1 = 1       1 & 1 = 1        1 | 1 = 1     
0 ^ 1 = 0       0 & 1 = 0        0 | 1 = 1     
1 ^ 0 = 0       1 & 0 = 0        1 | 0 = 1     
0 ^ 0 = 1       0 & 0 = 0        0 | 0 = 0     
```

## HashMap 中扩容的过程

首先，需要了解 HashMap 中几个重要成员变量


变量 | 含义
---|---
Node<K,V>[] table | 存储 HashMap 数据
int threshold | 下次进行扩容的阈值，默认值：table.length * loadFactor
float loadFactor | 加载因子
float DEFAULT_LOAD_FACTOR | 加载因子默认值：0.75f
TREEIFY_THRESHOLD | 红黑树化阈值: 8
int size | 当前 HashMap 中键值对的数目


当 size > threshold 时会触发扩容操作；扩容操作有以下几个特点：

1. 每次扩容至原来大小的两倍
2. 扩容最大容量为 MAXIMUM_CAPACITY = 1 << 30；
3. 扩容后，所有数据节点会重新计算数组下标，对于存在链表节点，数节点的数组下标只可能为原下标或者原下标+原数组大小；

下面是 HashMap 的源码分析

```Java
final Node<K,V>[] resize() {
    Node<K,V>[] oldTab = table;
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    int oldThr = threshold;
    int newCap, newThr = 0;
    if (oldCap > 0) {
        //如果数组大小超过最大容量，则直接返回
        if (oldCap >= MAXIMUM_CAPACITY) {
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        //否则将数组扩容两倍
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                 oldCap >= DEFAULT_INITIAL_CAPACITY)
            newThr = oldThr << 1;
    }
    else if (oldThr > 0) // initial capacity was placed in threshold
        newCap = oldThr;
    else { // 初始化默认值
        newCap = DEFAULT_INITIAL_CAPACITY;
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }
    if (newThr == 0) {
        float ft = (float)newCap * loadFactor;
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                  (int)ft : Integer.MAX_VALUE);
    }
    threshold = newThr;
    @SuppressWarnings({"rawtypes","unchecked"})
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    table = newTab;
    //开始迁移数据节点，重新计算数组下标
    if (oldTab != null) {
        for (int j = 0; j < oldCap; ++j) {
            Node<K,V> e;
            if ((e = oldTab[j]) != null) {
                oldTab[j] = null;
                //如果只有数组节点，没有链表节点或数节点；
                if (e.next == null)
                    newTab[e.hash & (newCap - 1)] = e;
                else if (e instanceof TreeNode) //如果是树节点
                    ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                else { //如果是链表节点
                    //保持原数组下标的头节点和尾节点
                    Node<K,V> loHead = null, loTail = null;
                    //迁移至新下标的头节点和尾节点
                    Node<K,V> hiHead = null, hiTail = null;
                    Node<K,V> next;
                    do { 拆分链表中的节点
                        next = e.next;
                        if ((e.hash & oldCap) == 0) {
                            if (loTail == null)
                                loHead = e;
                            else
                                loTail.next = e;
                            loTail = e;
                        }
                        else {
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    } while ((e = next) != null);
                    //保留至原来的数据下标 j
                    if (loTail != null) {
                        loTail.next = null;
                        newTab[j] = loHead;
                    }
                    //迁移至新的数组下标 j + oldCap
                    if (hiTail != null) {
                        hiTail.next = null;
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    return newTab;
}
```

如果要迁移数据节点，如何做到尽可能的均分迁移和留在原地的节点，HashMap 采用的算法是 e.hash & oldCap; oldCap 是旧数组容量，又因为数组容量只能是 2 的幂次方，所以 oldCap 只有一个数字为 1，hash & oldCap 只可能为两个值 0 或 oldCap；示例如下：

```
   1011 1111 1010 1110 (hash)
&  0000 0000 0010 0000 (oldCap)
--------------------------------
   0000 0000 0010 0000 


   1011 1111 1000 1110 (hash)
&  0000 0000 0010 0000 (oldCap)
--------------------------------
   0000 0000 0000 0000 
```



> 参考链接

- [HashMap中hash(Object key)原理，为什么(hashcode >>> 16)。](https://blog.csdn.net/qq_42034205/article/details/90384772)

