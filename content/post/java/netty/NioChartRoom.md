---
title: "Nio 聊天室"
discriptions: "Nio 聊天室"
date: 2019-11-09T21:29:35+08:00
author: Pismery Liu
archives: "2019"
tags: [Java,NIO,Netty]
categories: [Java]
showtoc: true
---

<!--more-->

# Nio 聊天室

本篇文章运用 NIO 实现一个简易的聊天室功能，目的是为了整合一下最近学习 NIO 中的 Channel, Buffer, Selector 的功能；

实现逻辑大概如下：

服务端：

1. 启动一个 ServerSocketChannel，同时注册 OP_ACCEPT 事件至 Selector 中；
2. 循环监听 selector 中的事件
    1. 处理 channel 连接事件
    2. 处理 channel 可读事件，接收客户端发送的消息

服务端需要注意的一个地方是，如果客户端断开连接，会产生一个可读事件，而此时再调用 channel 的 read 方法会抛出 IOException，此时需要处理异常关闭 channel 和 解除 key 与 selector 的监听绑定


客户端：

1. 启用一个 SocketChannel 连接 Server 端，同时注册 OP_ACCEPT 事件至 Selector 
2. 循环监听 selector 中的事件
    1. 处理 channel 连接事件
        1. 注册 OP_READ 事件至 Selector
        2. 循环监听客户端键盘输入，发送输入消息指服务端
    2. 处理 channel 可读事件，接收服务端发送的消息

## 代码实现

> 服务端实现

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191109211219.png)

```Java
public class NioChatServer {

    private static Map<String, SocketChannel> channelMap = new HashMap<>();
    private static Selector selector;

    public static void main(String[] args) throws Exception {
        startUp();
        while (true) {
            doServer();
        }
    }

    public static void startUp() throws Exception {
        ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
        serverSocketChannel.configureBlocking(false);
        serverSocketChannel.bind(new InetSocketAddress("127.0.0.1", 8989));

        selector = Selector.open();
        serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);
    }

    public static void doServer() throws IOException {
        selector.select();

        Set<SelectionKey> selectionKeys = selector.selectedKeys();
        selectionKeys.forEach(NioChatServer::handleSelectKey);

        selectionKeys.clear();
    }

    private static void handleSelectKey(SelectionKey key) {
        try {
            if (key.isAcceptable()) {
                handleAcceptable(key);
            } else if (key.isReadable() && key.isValid()) {
                handleReadable(key);
            }
        } catch (IOException e) {

        }
    }

    private static void handleAcceptable(SelectionKey key) throws IOException {
        ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
        SocketChannel clientChannel = serverChannel.accept();
        clientChannel.configureBlocking(false);
        clientChannel.register(selector, SelectionKey.OP_READ);

        String keyStr = UUID.randomUUID().toString();
        System.out.println(clientChannel + ": " + keyStr);
        channelMap.put(keyStr, clientChannel);
    }

    private static void handleReadable(SelectionKey key) {
        SocketChannel clientChannel = (SocketChannel) key.channel();
        String keyStr = getChannelKey(clientChannel);
        try {
            clientChannel.configureBlocking(false);

            String msg = readMsg(clientChannel);
            System.out.println(keyStr + ": " + msg);

            sendMsg(keyStr + ": " + msg);
        } catch (IOException e) {
            try {
                clientChannel.close();
                clientChannel.socket().close();
                key.cancel();
                channelMap.remove(keyStr);
                System.out.println(keyStr + ": 断开连接");
            } catch (IOException e1) {
                e1.printStackTrace();
            }
        }
    }

    private static String readMsg(SocketChannel clientChannel) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        int read = clientChannel.read(buffer);
        if (read <= 0) {
            return null;
        }
        buffer.flip();

        Charset charset = Charset.forName("utf-8");
        return String.valueOf(charset.decode(buffer).array());
    }

    private static void sendMsg(String msg) throws IOException {
        for (Map.Entry<String, SocketChannel> m : channelMap.entrySet()) {
            SocketChannel client = m.getValue();

            ByteBuffer writeBuffer = ByteBuffer.allocate(1024);
            writeBuffer.put((msg).getBytes());
            writeBuffer.flip();

            client.write(writeBuffer);
        }
    }

    private static String getChannelKey(SocketChannel clientChannel) {
        String keyStr = "";
        for (Map.Entry<String, SocketChannel> m : channelMap.entrySet()) {
            if (m.getValue().equals(clientChannel)) {
                keyStr = m.getKey();
            }
        }
        return keyStr;
    }

}
```

> 客户端实现

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191109211148.png)

```Java
public class NioChatClient {
    private static Selector selector;

    public static void main(String[] args) throws Exception {
        connectToServer();
        while (true) {
            doConnected();
        }
    }

    public static void connectToServer() throws Exception {
        SocketChannel socketChannel = SocketChannel.open();
        socketChannel.configureBlocking(false);

        selector = Selector.open();
        socketChannel.register(selector, SelectionKey.OP_CONNECT);
        socketChannel.connect(new InetSocketAddress("127.0.0.1", 8989));
    }

    private static void doConnected() throws IOException {
        selector.select();
        Set<SelectionKey> keySet = selector.selectedKeys();
        for (SelectionKey selectionKey : keySet) {
            if (selectionKey.isConnectable()) {
                handleConnectable(selectionKey);
            } else if (selectionKey.isReadable()) {
                handleReadable(selectionKey);
            }
        }
        keySet.clear();
    }

    private static void handleReadable(SelectionKey selectionKey) throws IOException {
        SocketChannel client = (SocketChannel) selectionKey.channel();
        ByteBuffer readBuffer = ByteBuffer.allocate(1024);
        int read = client.read(readBuffer);
        if (read <= 0) {
            return;
        }

        readBuffer.flip();
        Charset charset = Charset.forName("utf-8");
        String msg = String.valueOf(charset.decode(readBuffer).array());
        System.out.println(msg);
    }

    private static void handleConnectable(SelectionKey selectionKey) throws IOException {
        SocketChannel client = (SocketChannel) selectionKey.channel();

        if (client.isConnectionPending()) {
            client.finishConnect();

            ByteBuffer writerBuffer = ByteBuffer.allocate(1024);
            writerBuffer.put((LocalDateTime.now() + ": 连接成功").getBytes());
            writerBuffer.flip();
            client.write(writerBuffer);

            listenKeyboardInput(client);

        }
        client.register(selector, SelectionKey.OP_READ);
    }

    private static void listenKeyboardInput(SocketChannel client) {
        ExecutorService service = Executors.newSingleThreadExecutor();
        service.submit(() -> {
            ByteBuffer writerBuffer = ByteBuffer.allocate(1024);
            while (true) {
                BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
                try {
                    writerBuffer.clear();
                    String line = br.readLine();
                    writerBuffer.put(line.getBytes());
                    writerBuffer.flip();
                    client.write(writerBuffer);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        });
    }
}
```

> 运行结果

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191109214530.png)

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191109214559.png)

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20191109214624.png)