# SQS Tips

## Description

How to get sqs message from cross acount Lambda


## Environment

- AWS Account A
  - S3 Bucket
  - SQS
- AWS Account B
  - Lambda
- All regions are ap-northeast-1

## Process Description

1. Put object evetns happen on S3 Bucket
2. S3 Event Notification runs SQS
3. SQS gets message from S3 Bucket
4. Lambda Trigger(SQS) runs Lambda

## Caution

- SQS must exists on same AWS Account S3 Bucket.

## SQS Access policy

### For Cross Account

```json
{
  "Version": "2012-10-17",
  "Id": "__sqs_policy_ID",
  "Statement": [
    {
      "Sid": "s3_notification_sqs",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.ap-northeast-1.amazonaws.com"
      },
      "Action": "sqs:sendMessage",
      "Resource": "arn:aws:sqs:ap-northeast-1:YOUR_ACCOUNT_A:YOUR_SQS_NAME"
    },
    {
      "Sid": "to_process_sqs_from crossaccount_lambda",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR_ACCOUNT_B:root"
      },
      "Action": [
        "sqs:GetQueueAttributes",
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage"
      ],
      "Resource": "arn:aws:sqs:ap-northeast-1:YOUR_ACCOUNT_A:YOUR_SQS_NAME"
    }
  ]
}
```
