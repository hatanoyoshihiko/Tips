import boto3
from botocore.exceptions import ClientError

# 設定値
days_after_creation = 30  # オブジェクト作成後に移行する日数
storage_class = 'INTELLIGENT_TIERING'  # 移行先のストレージクラス
lifecycle_rule_id = 'MoveToIntelligentTieringAfterDays'  # ライフサイクルルールのID

def apply_lifecycle_rule_to_all_buckets():
    # AWSクライアントの作成
    s3 = boto3.client('s3')

    try:
        # 全てのバケットをリスト取得
        buckets = s3.list_buckets()['Buckets']
        bucket_names = [bucket['Name'] for bucket in buckets]

        # バケットリストの表示
        print("The following buckets will have lifecycle rules applied:")
        for bucket_name in bucket_names:
            print(f" - {bucket_name}")

        # 確認入力
        user_input = input("Do you want to apply the lifecycle rule to these buckets? (y/n): ").strip().lower()

        if user_input != 'y':
            print("Operation cancelled.")
            return

        # ライフサイクルルールを適用
        for bucket_name in bucket_names:
            print(f"Applying lifecycle rule to bucket: {bucket_name}")

            # ライフサイクルルールの定義
            lifecycle_rule = {
                'Rules': [
                    {
                        'ID': lifecycle_rule_id,
                        'Filter': {'Prefix': ''},  # バケット内の全てのオブジェクトに適用
                        'Status': 'Enabled',
                        'Transitions': [
                            {
                                'Days': days_after_creation,
                                'StorageClass': storage_class
                            }
                        ]
                    }
                ]
            }

            # ライフサイクルルールの適用
            try:
                s3.put_bucket_lifecycle_configuration(
                    Bucket=bucket_name,
                    LifecycleConfiguration=lifecycle_rule
                )
                print(f"Success: Lifecycle rule applied to {bucket_name}")
            except ClientError as e:
                print(f"Error applying lifecycle rule to {bucket_name}: {e}")

    except ClientError as e:
        print(f"Error listing buckets: {e}")

if __name__ == "__main__":
    apply_lifecycle_rule_to_all_buckets()
