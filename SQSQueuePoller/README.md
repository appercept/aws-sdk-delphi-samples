# SQS Queue Poller

A pair of console applications demonstrating Amazon SQS message passing. Also the
only non-GUI sample in the collection, if you want to see the SDK outside of a
desktop app.

The **Poller** uses `TSQSQueuePoller` to efficiently receive messages from a queue.
The **Sender** uses `TSQSClient.SendMessage` to push messages onto it.

## What's demonstrated

- `TSQSQueuePoller` for long-polling (no manual receive loops needed)
- `TSQSClient.SendMessage` for pushing messages
- `TSQSQueuePollerStatistics` for request count and received message count
- Configurable batch size, up to 10 messages per receive

```pascal
// Poller — three lines to start consuming messages
QueuePoller := TSQSQueuePoller.Create(QueueURL);
QueuePoller.Poll(
  procedure(const AMessages: TSQSMessages)
  begin
    for var LMessage in AMessages do
      WriteLn('Received: ', LMessage.Body);
  end
);
```

```pascal
// Sender — one line per message
SQS := TSQSClient.Create;
SQS.SendMessage(QueueURL, 'Order #1234 ready for processing');
```

## Running the sample

1. Create a queue in the [Simple Queue Service Console](https://console.aws.amazon.com/sqs)
   and take note of the Queue URL.
2. Open the "SQS Queue Poller.groupproj" project group in Delphi or RAD Studio.
3. Build all applications using the "Project \> Build All Projects" menu item.
4. Launch two instances of `cmd.exe` and place them side-by-side so you can see the results.
5. Change directory into the project output folder (e.g. `Win32\Debug`) in both command shells.
6. In the first command shell, run the poller (replace the URL with your Queue URL from step 1):
   `Poller.exe https://sqs.eu-west-1.amazonaws.com/123456789012/MyQueue`
7. In the second command shell, run the sender:
   `Sender.exe Sender1 https://sqs.eu-west-1.amazonaws.com/123456789012/MyQueue`

## Receiving batches of messages

In a real-world scenario, you'll likely want to receive batches of messages for
processing. By default, `TSQSQueuePoller` fetches one message per batch, but you
can specify the upper limit of the batch size (up to 10). To demonstrate this,
uncomment the line `QueuePoller.MaxNumberOfMessages := 3;` in `Poller.dpr` and
recompile.

Once you have restarted the Poller as per the previous instructions, you can run
multiple instances of `Sender.exe` to push more messages into the queue
simultaneously. The second argument to `Sender.exe` is a name to identify the
instance of the sender, so set each instance to a unique name (e.g. "Sender1",
"Sender2"). Once the queue has enough messages being delivered, you will start to
see the Poller output batched:

```
[20220513T152808] Messages received to date 10
[20220513T152808] Received message: Message 104 from Sender1
[20220513T152808] Received message: Message 105 from Sender2
[20220513T152808] Received message: Message 113 from Sender1
[20220513T152808] Polling iteration 5
[20220513T152808] Messages received to date 13
[20220513T152808] Received message: Message 102 from Sender1
[20220513T152808] Received message: Message 112 from Sender1
```

## Required IAM permissions

**Poller:**

- `sqs:ReceiveMessage`
- `sqs:DeleteMessage`
- `sqs:GetQueueAttributes`

**Sender:**

- `sqs:SendMessage`
