#/bin/bash

bucket_name=""
day=`date +%Y_%m_%d`
bk_dir=`mktemp -d`
tar zcf "$bk_dir"/httpd-"$day"_tar.gz -C /etc httpd
tar zcf "$bk_dir"/pki-"$day"_tar.gz -C /etc pki

aws s3 mv --recursive $bk_dir s3://$bucket_name/ec2/web/$day/
