# Appercept AWS SDK for Delphi — Samples

A collection of sample projects built with the [Appercept AWS SDK for Delphi](https://www.appercept.com/products/aws-sdk-delphi). Each project demonstrates a different use of Amazon Web Services from Delphi, from single-service basics to multi-service integrations.

## Samples

| Sample                                          | AWS Services               | Description                                                                                |
| ----------------------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------ |
| [CognitoDemo](CognitoDemo/)                     | Cognito, S3                | Hosted UI authentication with authenticated and unauthenticated credential flows           |
| [PollySpeak](PollySpeak/)                       | Polly                      | Text-to-speech with voice selection, standard/neural engines, and SSML                     |
| [ReadWhatYouSee](ReadWhatYouSee/)               | Textract, Translate, Polly | Detect text in an image, translate it, and read it aloud — three services working together |
| [Rekognition](Rekognition/)                     | Rekognition                | Three demos: label detection, custom label detection, and content moderation               |
| [S3Explorer](S3Explorer/)                       | S3                         | Browse buckets, navigate prefixes, upload (with multi-part), download, and inspect objects |
| [SecretsManagerConsole](SecretsManagerConsole/) | Secrets Manager, KMS       | Create, list, and retrieve secrets with KMS key management                                 |
| [SESSendEmail](SESSendEmail/)                   | SES v2                     | Send email using verified identities                                                       |
| [SQSQueuePoller](SQSQueuePoller/)               | SQS                        | Console app pair: a poller using `TSQSQueuePoller` and a sender using `TSQSClient`         |
| [Textract](Textract/)                           | Textract                   | Detect and highlight text within document images                                           |
| [Translate](Translate/)                         | Translate                  | Translate text between languages                                                           |

## Getting Started

1. Install the [Appercept AWS SDK for Delphi](https://www.appercept.com/products/aws-sdk-delphi). Check the product page for supported Delphi versions and platforms.
2. Clone this repository.
3. Open any sample `.dproj` in RAD Studio / Delphi and run it. Each sample has its own README with specific instructions.

## Prerequisites

### AWS Account

You'll need an AWS account. If you don't have one yet, sign up at the [AWS Management Console](https://console.aws.amazon.com/).

### AWS Credentials

The samples authenticate using standard AWS credential configuration. You'll need an IAM user or role with an access key and the appropriate permissions for the services each sample uses.

For details on setting up credentials, see the [AWS IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html).

## Costs

These samples interact with your AWS account and may incur costs. Many of the services used offer a [Free Tier](https://aws.amazon.com/free) that may cover casual experimentation. Be sure to understand the pricing for any service you use, and clean up resources when you're done.

## License

The sample code in this repository is released under the [MIT License](LICENSE). The Appercept AWS SDK for Delphi is a separate commercial product — see the [product page](https://www.appercept.com/products/aws-sdk-delphi) for licensing details.
