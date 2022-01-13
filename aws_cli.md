# How to use AWS CLI

## Overview

Operate AWS resource using AWS CLI.

### How to use

1. Install aws cli
2. Issue credential ( file or variables )
3. Run on the EC2 that are attached instance profile
4. Using a cloudshell

## Install aws cli

## Credential priority

command argument > environment variable > credential file

## Issue credential

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
