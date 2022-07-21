---
title: "Nio 零拷贝"
discriptions: "NioZeroCopy"
date: 2019-11-23T20:24:44+08:00
author: Pismery Liu
archives: "2019"
tags: [Java,NIO,Netty]
categories: [Java]
showtoc: true
---

<!--more-->

# Nio Zero Copy

谈到 NIO，总会提起 Zero Copy「零拷贝」；本篇文章就大概讲述一下零拷贝的内容。

首先，零拷贝的技术必须依赖操作系统，如果操作系统不支持，则编程语言上是无法解决的。零拷贝并不是指完全没有拷贝，而是消除了用户空间与内核空间之间的拷贝；

下面我们先看看没有零拷贝前，操作系统读写数据的流程；

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191123193526.png)

上图中的逻辑大概如下：

1. 程序调用操作系统 read 方法；操作系统从用户态切换至内核态，并从外部设备中读取数据至内核态中；
2. 将内核态读取数据拷贝至用户态，供用户态处理；
3. 程序将处理好的数据，通过调用操作系统 write 方法，将数据从用户态拷贝至内核态；
4. 最后操作系统将数据输出到外部设备中；

从中可以发现，这个操作过程中出现了数据在用户态与内核态之间互相拷贝的问题，并且出现 4 次的用户态与内核态的切换；而零拷贝技术，就是避免了数据的重复拷贝，并且减少了用户态与核心态切换次数；

下面是零拷贝读写数据的流程：

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191123194810.png)

从上图可以看出来，数据仅从外部设备读取至内核态中，并最后从内核态写回外部设备中；并没有出现数据拷贝至用户态的情况了；但是细心的你可能发现，期间还是出现了一次数据从内核态的 buffer 中拷贝至 socket buffer 中，当然操作系统也在此过程中避免了拷贝，通过维护内核态 buffer 的状态信息如起始内存地址、数据大小，直接从内核态 buffer 中传输数据；


> DMA: 直接内存访问，是操作系统为了避免不同速度硬件设备之间的数据操作，导致大量的 CPU 中断负载；

## 示例程序

下面分别实现一个传统读写文和 Nio 读写文件的程序，来感受一下零拷贝带来的性能提升。

> 服务端

本示例重于感受零拷贝读写数据的性能，因此服务端仅仅接收数据后什么也不做。

```Java
public class ZeroCopyServer {
    public static void main(String[] args) throws Exception {
        ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
        ServerSocket serverSocket = serverSocketChannel.socket();
        serverSocket.setReuseAddress(true);
        serverSocket.bind(new InetSocketAddress(8081));

        ByteBuffer buffer = ByteBuffer.allocate(4096);
        System.out.println("Server startup...");
        while (true) {
            SocketChannel socketChannel = serverSocketChannel.accept();
            socketChannel.configureBlocking(true);

            int readCount = 0;
            try {
                while (-1 != readCount) {
                    readCount = socketChannel.read(buffer);
                    buffer.rewind();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }

        }
    }
}
```

> 非零拷贝客户端

```Java
public class OldClient {
    public static void main(String[] args) throws Exception{
        Socket socket = new Socket("localhost",8081);

        String filePath = "E:\\Video\\Netty\\1111.mp4";
        FileInputStream fileInputStream = new FileInputStream(filePath);
        DataOutputStream dataOutputStream = new DataOutputStream(socket.getOutputStream());

        byte[] buffer = new byte[4096];
        int readTotal = 0;
        int readCount = 0;

        long startTime = System.currentTimeMillis();
        while (-1 != (readCount = fileInputStream.read(buffer, 0, buffer.length))) {
            readTotal += readCount;
            dataOutputStream.write(buffer);
        }

        System.out.println("Old ---> Read Total: " + readTotal + "; Coast Time: " + (System.currentTimeMillis() - startTime));

        dataOutputStream.close();
        fileInputStream.close();
        socket.close();
    }
}
```

> 零拷贝客户端

```Java
public class NewClient {
    public static void main(String[] args) throws Exception {
        SocketChannel socketChannel = SocketChannel.open();
        socketChannel.connect(new InetSocketAddress(8081));
        socketChannel.configureBlocking(true);
        String filePath = "E:\\Video\\Netty\\1111.mp4";

        FileChannel fileChannel = new FileInputStream(filePath).getChannel();
        
        /*
            由于 windows 操作系统会限制一次零拷贝最大长度；因此这里需要
            循环传输数据；如果是 linux 中则只要内存足够，可以直接一次传输
            完毕
        */
        long startTime = System.currentTimeMillis();
        long fileSize = fileChannel.size();
        long remainSize = fileChannel.size();
        int readTotal = 0;
        while (readTotal < fileSize) {
            long transferSize = fileChannel.transferTo(readTotal, remainSize, socketChannel);
            readTotal += transferSize;
            remainSize -= transferSize;
        }

        System.out.println("New ---> Read Total: " + readTotal + "; Coast Time: " + (System.currentTimeMillis() - startTime));
        fileChannel.close();
    }
}
```

> 运行结果

示例中的被读写文件大小为 400MB 左右；

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191123201932.png)

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191123201504.png)

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191123201609.png)

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191123201712.png)

多次运行后，结果大概与上图差不多，非零拷贝大概需要 2100 ms 左右，而零拷贝在 300 ms 左右；


## 参考链接

- [Java NIO系列教程（五）通道之间的数据传输](http://ifeve.com/java-nio-channel-to-channel/)
- [DMA （直接存储器访问）](https://baike.baidu.com/item/DMA/2385376)