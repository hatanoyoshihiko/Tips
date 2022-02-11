#!/bin/bash

# Env
AWS_PROFILE="default"
PREFIX_LIST_ID=""
NEW_CIDR=`curl -s https://www.cloudflare.com/ips-v4`
CUR_CIDR=`aws ec2 get-managed-prefix-list-entries \
	--prefix-list-id $PREFIX_LIST_ID \
	--query 'Entries[].Cidr' \
	--output text --profile $AWS_PROFILE | ¥
	sed -e 's/\t/\n/g' | sort -n`
NEW_PREFIX_LIST=`diff --old-line-format='%L' ¥
	--unchanged-line-format='' ¥
	--new-line-format='' <(echo $NEW_CIDR | ¥
	sed -e 's/ /\n/g') <(echo $CUR_CIDR | ¥
	sed -e 's/ /\n/g')`
CUR_PREFIX_LIST=`diff ¥
	--old-line-format='%L' ¥
	--unchanged-line-format='' ¥
	--new-line-format='' <(echo $CUR_CIDR | ¥
	 sed -e 's/ /\n/g') <(echo $NEW_CIDR | ¥
	 sed -e 's/ /\n/g')`
VERSION=`aws ec2 describe-managed-prefix-lists ¥
	--prefix-list-id $PREFIX_LIST_ID ¥
	--query 'PrefixLists[].Version' ¥
	--output text --profile $AWS_PROFILE`

# Functions
remove_cidr()
{
	for i in `echo -n $CUR_PREFIX_LIST`
	do
		NEW_VERSION=$((VERSION++))
		aws ec2 modify-managed-prefix-list \
			--prefix-list-id "$PREFIX_LIST_ID" \
			--remove-entries Cidr=$i \
			--current-version "$NEW_VERSION" \
			--profile $AWS_PROFILE
	done
}

update_cidr()
{
	for i in `echo -n $NEW_PREFIX_LIST`
	do
		NEW_VERSION=$((VERSION++))
		aws ec2 modify-managed-prefix-list \
			--prefix-list-id $PREFIX_LIST_ID \
			--add-entries Cidr=$i \
			--current-version $NEW_VERSION \
			--profile $AWS_PROFILE
	done
}

diff_cidr()
{
	diff -q <(echo -n $NEW_CIDR) <(echo -n $CUR_CIDR)
	DIFF=$?
	if [ $DIFF == 0 ]; then
		:
	else
		remove_cidr
		update_cidr
	fi
}

# Main
diff_cidr
exit 0
