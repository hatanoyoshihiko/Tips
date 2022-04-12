# How to use endpoint

## S3 Endpoint (gateway)

- policy

this policy shows approval to update packages from s3 endpoint.

```json
{
	"Version": "2012-10-17",
	"Id": "Policy1646696034227",
	"Statement": [
		{
			"Sid": "Access-to-specific-bucket",
			"Effect": "Allow",
			"Principal": "*",
			"Action": [
				"s3:GetObject",
				"s3:PutObject"
			],
			"Resource": [
				"arn:aws:s3:::BUCKET_A",
				"arn:aws:s3:::BUCKET_A/*",
				"arn:aws:s3:::repo.us-east-1.amazonaws.com",
				"arn:aws:s3:::repo.us-east-1.amazonaws.com/*",
				"arn:aws:s3:::amazonlinux.us-east-1.amazonaws.com/*",
				"arn:aws:s3:::amazonlinux-2-repos-us-east-1/*"
			]
		}
	]
}
```
