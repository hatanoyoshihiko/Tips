# How to use AWS CLI

## Overview

Operate AWS resource using AWS CLI.

### How to use

1. Install aws cli
2. Issue credential ( file or variables )
3. Run on the EC2 that are attached instance profile
4. Using a cloudshell

## Install aws cli

[Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Credential priority

command argument > environment variable > credential file

## Issue credential

Crendential has Access key ID and Secret Access Key.

- Issue Access Key ID and Secret Access Key

You must log in aws console.

`IAM > User > User Name > authentication > assign mfa device`

## AWS CLI environments

[Environments](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-configure-envvars.html)

---

## How to limit with mfa when use aws cli

**NOTE**
Session tokens can only be got by the IAM user myself.

### Create policy

this policy limits access without mfa authentication.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllDenyWithoutMFA",
            "Effect": "Deny",
            "Action": [
                "*"
            ],
            "Resource": [
                "*"
            ],
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": false
                }
            }
        }
    ]
}
```

### Attach policy to IAM user

log in aws console to create and attache policy.

### Get temporary authentication code

"--duration" specifies time to allow token session.

```bash
aws sts get-session-token --serial-number arn:aws:iam::24810******:mfa/wakataka --duration-seconds 43200 --token-code MFA_NUMBER
{
    "Credentials": {
        "AccessKeyId": "ASIATTRCHY*********",
        "SecretAccessKey": "vymu1Tmxty3bsb+******************",
        "SessionToken": "FwoGZXIvYXdzENT//////////wEaDAn1cQjI1wzJ2Em1dyKGAQWazk/********,
        "Expiration": "2021-05-18T22:09:31Z"
    }
}
```

## Change credential settings

- before

```bash
# vi ~/.aws/credentials
[wakataka]
aws_access_key_id = BEFORE_CHANGED_ID
aws_secret_access_key = BEFORE_CHANGED_KEY
```

- after
rewrite or add authentication information to credential file.

```bash
[mfa]
aws_access_key_id = ASIATTRCHY*********
aws_secret_access_key = ymu1Tmxty3bsb+******************
aws_session_token = woGZXIvYXdzENT//////////wEaDAn1cQjI1wzJ2Em1dyKGAQWazk/********
```

## Run AWS CLI

```bash
# export AWS_PROFILE="mfa"
# aws iam get-user
{
    "User": {
        "Path": "/",
        "UserName": "wakataka",
        "UserId": "AIDATTRC***********",
        "Arn": "arn:aws:iam::2481******5:user/wakataka",
        "CreateDate": "2020-12-03T13:00:46Z",
        "PasswordLastUsed": "2021-03-05T08:57:08Z"
    }
}
```

## AWS CLI using a MFA

### Set Access key and Secret key

```bash
$ export AWS_ACCESS_KEY_ID=AAAAAAAAAA
$ export AWS_SECRET_ACCESS_KEY=BBBBBBBBBB
$ export AWS_DEFAULT_REGION=us-east-1
```

### Get token

Note: --duratin-seconds can configure until 43200.  
Note: Specify USERNAME as your IAM User.

`$ aws sts get-session-token --serial-number arn:aws:iam::ACCOUNT_NO:mfa/USERNAME --duration-seconds 900 --token-code MFA_CODE`

- result
  
```json
{
    "Credentials": {
        "AccessKeyId": "AXXXXXXXXXXXXXXXXXXX",
        "SecretAccessKey": "123456789",
        "SessionToken": "123456789123456789",
        "Expiration": "2002-11-24T08:59:37Z"
    }
}
```

### Change Access key and Secret key

```bash
$ export AWS_ACCESS_KEY_ID=AXXXXXXXXXXXXXXXXXXX
$ export AWS_SECRET_ACCESS_KEY=123456789
$ export AWS_SESSION_TOKEN=123456789123456789
```

### How to extract InstanceID from ec2 describe-instances

- Output shows that filtered instance name and state is running.
- Note: Specify your instance name to INSTANCE_NAME.

`$ aws ec2 describe-instances --filters 'Name=tag-key,Values=Name' 'Name=tag-value,Values=INSTANCE_NAME' --query 'Reservations[*].Instances[*].{Instance:InstanceId,State:State.Name}' --output json`

### How to start ssm

- Note:
  - PROFILE_NAME: your AWS CLI PROFILE NAME
  - INSTANCE_ID: your instance id

`$ aws ssm start-session --target INSTANCE_ID --profile PROFILE_NAME`
