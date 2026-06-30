<!-- 目标路径: notes/azure/service-bus-topic-subscription.md -->

# Azure Service Bus - Topic & Subscription Quick Start

## 1. 和Queue的区别

| | Queue | Topic + Subscription |
|---|---|---|
| 模式 | 点对点(一条消息只能被一个消费者处理) | 发布订阅(一条消息可以被多个订阅者各自收到一份) |
| 适用场景 | 一个任务只需要一个人/系统处理 | 同一个事件,多个系统都要知道(比如订单创建后,库存系统、邮件系统都要收到通知) |

⚠️ **重要前提**:Topic功能只有 **Standard层及以上** 才支持,Basic层(最便宜那档)不支持Topic。你之前建的 `ken-learning-sb1` 如果是Basic层,需要升级到Standard才能创建Topic。

## 2. 核心概念

- **Topic**:消息的"投递目标",生产者只管往Topic发消息,不关心谁来收
- **Subscription**:挂在Topic下面的"订阅者通道",每个Subscription都会收到Topic里的**每一条**消息的副本
- 一个Topic可以挂多个Subscription,每个Subscription相当于一个独立的小Queue

举例:Topic叫 `order-events`,下面挂两个Subscription:`email-subscription`、`inventory-subscription`。生产者往Topic发一条"订单创建"消息,这两个Subscription都会各自收到一份,互不影响。

## 3. 创建资源(Azure Portal操作步骤)

1. 进入你的 Service Bus Namespace(确认是 Standard 层,Basic层需要先升级)
2. 左侧菜单 "Topics" → "+ Topic",起名字,比如 `order-events`
3. 进入这个Topic → 左侧 "Subscriptions" → "+ Subscription",起名字,比如 `email-subscription`
4. 重复步骤3,再建一个 `inventory-subscription`(用来体验"一条消息多人收到")

## 4. C# 代码示例:发送消息到Topic

需要 NuGet 包:`Azure.Messaging.ServiceBus`

```csharp
// Target path: src/azure/ServiceBusTopicSenderDemo.cs
using Azure.Messaging.ServiceBus;
using System;
using System.Threading.Tasks;

class ServiceBusTopicSenderDemo
{
    static async Task Main()
    {
        // Get connection string from: Azure Portal -> Service Bus Namespace -> Shared access policies
        // Do NOT commit the real connection string to GitHub
        string connectionString = "<your-connection-string-here>";
        string topicName = "order-events";

        var clientOptions = new ServiceBusClientOptions
        {
            TransportType = ServiceBusTransportType.AmqpWebSockets
        };

        ServiceBusClient client = new ServiceBusClient(connectionString, clientOptions);
        ServiceBusSender sender = client.CreateSender(topicName);

        string messageBody = "Order #1001 created";
        ServiceBusMessage message = new ServiceBusMessage(messageBody);

        await sender.SendMessageAsync(message);
        Console.WriteLine($"Message sent to topic: {messageBody}");

        await sender.DisposeAsync();
        await client.DisposeAsync();
    }
}
```

## 5. C# 代码示例:从Subscription接收消息

每个Subscription都要单独写一个Receiver去接收,下面是其中一个(`email-subscription`)的示例,另一个`inventory-subscription`同理,把名字换一下即可。

```csharp
// Target path: src/azure/ServiceBusTopicReceiverDemo.cs
using Azure.Messaging.ServiceBus;
using System;
using System.Threading.Tasks;

class ServiceBusTopicReceiverDemo
{
    static async Task Main()
    {
        // Get connection string from: Azure Portal -> Service Bus Namespace -> Shared access policies
        // Do NOT commit the real connection string to GitHub
        string connectionString = "<your-connection-string-here>";
        string topicName = "order-events";
        string subscriptionName = "email-subscription";

        var clientOptions = new ServiceBusClientOptions
        {
            TransportType = ServiceBusTransportType.AmqpWebSockets
        };

        ServiceBusClient client = new ServiceBusClient(connectionString, clientOptions);
        ServiceBusReceiver receiver = client.CreateReceiver(topicName, subscriptionName);

        ServiceBusReceivedMessage receivedMessage = await receiver.ReceiveMessageAsync();

        if (receivedMessage != null)
        {
            string body = receivedMessage.Body.ToString();
            Console.WriteLine($"[{subscriptionName}] Message received: {body}");

            // After processing is completed, you must manually complete it; otherwise, the message will reappear in the queue.
            await receiver.CompleteMessageAsync(receivedMessage);
        }
        else
        {
            Console.WriteLine($"[{subscriptionName}] The subscription is empty; there are no messages.");
        }

        await receiver.DisposeAsync();
        await client.DisposeAsync();
    }
}
```

## 6. 验证"一条消息多人收到"的效果

1. 跑一次 `ServiceBusTopicSenderDemo`,往Topic发一条消息
2. 跑 `ServiceBusTopicReceiverDemo`(subscriptionName = `email-subscription`),应该能收到
3. 把 `subscriptionName` 改成 `inventory-subscription`,再跑一次,应该**也能收到同一条消息**(因为它是独立副本)

这就是和Queue最大的区别:Queue里的消息被一个人收走就没了,Topic的消息每个Subscription都各收一份。

## 7. 经验提醒(来自之前Queue的踩坑)

- 公司网络限制端口的话,记得跟Queue一样用 `AmqpWebSockets` 传输方式(已经写在上面代码里了)
- Topic名字、Subscription名字一定要跟Portal上完全一致,大小写不敏感但拼写不能错
- 连接字符串不要写真实值到代码里,用占位符,实际跑的时候从Portal复制粘贴到本地(不提交到GitHub)

## 8. 下一步学习方向

- [x] Topic + Subscription
- [ ] Subscription Filter(只接收符合特定条件的消息)
- [ ] Managed Identity 连接 Service Bus
- [ ] Dead Letter Queue
- [ ] Dynamics 365 插件如何往Service Bus发消息

---
*笔记创建: 2026-06-30*
