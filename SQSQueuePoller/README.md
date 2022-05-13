# SQSQueuePoller
The SQS Queue Poller sample demonstrates passing messages through a queue from a “Sender” to a “Poller”.

The Poller project demonstrates the use of `TSQSQueuePoller`. While you can use `TSQSClient` and directly call `ReceiveMessage`, `TSQSQueuePoller` provides convenience for one of the most common SQS usage patterns - efficiently receiving messages.

The Sender project demonstrates `TSQSClient` for sending messages with `SendMessage`.

## Running the sample
1. Create a queue in the [Simple Queue Service Console](https://console.aws.amazon.com/sqs) and take note of the Queue URL.
2. Open the “SQS Queue Poller.groupproj” project group in Delphi or RAD Studio.
3. Build all applications using the “Project \> Build All Projects” menu item.
4. Launch two instances of `cmd.exe`  and place them side-by-side so you can see the results.
5. Change the directory into the project output folder (e.g. `Win32\Debug`) in both command shells.
6. In the first command shell, run the poller with the following command (replace the URL with the Queue URL from step 1):  
	`Poller.exe https://sqs.eu-west-1.amazonaws.com/123456789012/MyQueue`
7. In the second command shell, run the sender with the following command (replace the URL with the Queue URL from step 1):  
	`Sender.exe Sender1 https://sqs.eu-west-1.amazonaws.com/123456789012/MyQueue`

## Receiving batches of messages
In a real-world scenario, you’ll likely want to receive batches of messages for processing. By default, the `TSQSQueuePoller` fetches one message per batch, but you can specify the upper limit of the batch size (up to 10 max). To demonstrate this, uncomment the line `QueuePoller.MaxNumberOfMessages := 3;` in `Poller.dpr` and recompile.
Once you have restarted the Poller.exe as per the previous instructions, you can run multiple instances of `Sender.exe` to push more messages into the queue simultaneously. The second argument to `Sender.exe` is a name to identify the instance of the sender so set each instance to a unique name (e.g. “Sender1”, “Sender2”, etc.). Once the queue has enough messages being delivered, you will start to see the `Poller.exe` output batched:
```
[20220513T152808] Messages received to date 10
[20220513T152808] Received message: Message 104 from Sender1
[20220513T152808] Received message: Message 105 from Sender2
[20220513T152808] Received message: Message 113 from Sender1
[20220513T152808] Polling iteration 5
[20220513T152808] Messages received to date 13
[20220513T152808] Received message: Message 102 from Sender1
[20220513T152808] Received message: Message 112 from Sender1
[20220513T152808] Polling iteration 6
[20220513T152808] Messages received to date 15
[20220513T152808] Received message: Message 2 from Sender2
[20220513T152808] Received message: Message 115 from Sender1
```
