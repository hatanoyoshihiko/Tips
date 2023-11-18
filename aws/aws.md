# AWS CLI tips

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
