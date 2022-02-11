# AWS CLI tips

## AWS CLI using a mfa

### Set Access key and Secret key

```bash
$ export AWS_ACCESS_KEY_ID=AAAAAAAAAA
$ export AWS_SECRET_ACCESS_KEY=BBBBBBBBBB
$ export AWS_DEFAULT_REGION=us-east-1
```

### Get token

Note: --duratin-seconds can configure until 43200.

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

### Run AWS CLI
