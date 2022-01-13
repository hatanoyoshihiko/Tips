# Linuxコンテナの利用
Linux(Ubuntu)でコンテナを利用します。  
実運用に耐えられる設計を行うための調査結果をまとめました。

## コンテナとは
コンテナ技術とは仮想マシン等に比べて軽量な仮想化の仕組です。  
本調査ではLinuxコンテナーであるLXCとLXDについてまとめます。

コンテナにはFreeBSDのJail、Solarisのzone、dockerなど様々な実装があります。  WindowsではWindowsサーバコンテナ、Hyper-vコンテナがあります。

コンテナでよく利用されるdockerとLXD/LXCの違いとしては、大雑把にdockerはアプリケーション単位、LXC/LXDはサーバ単位でコンテナ化を行います。

## コンテナ技術について
2018年現在、全く新しい技術ではなく、既存の技術を組み合わせて実装された技術です。
単一で「コンテナ」という機能があるわけではありません。  
いわゆるVM(仮想マシン)と比べ、H/Wドライバをエミュレートしないため、
その分のオーバーヘッドが無いため、物理リソースを効率的に活用出来ます。

## コンテナを実装するための技術たち

-   コンテナプロセスの制御  
名前空間

-   コンテナの物理リソース制御  
cgroups

-   コンテナのホスト間の移動（ライブマイグレーション）  
CRIU

-   セキュリティ  
※調査中 chroot等

---

## LXDとは
コンテナを制御するデーモンです。

## LXCとは
LXDのコマンドラインクライアントです。  
ほとんどの操作はlxcコマンドで行います。


## 環境整備
実際にコンテナを使うための環境を整えます。

LXDホストとして下記環境を利用します。  
OS:Ubuntu18.04 (vagrant)  
LXD:3.0.1

### 必要なパッケージのインストール
ubuntu18.04なら初めからインストール済です。

-   安定版のインストール  
2018.9現在、3.0.1がインストールされます。  
`$ sudo apt install lxd`

-   criuのインストール  
`$ sudo apt install criu`

-   lvm用シンプロビジョニングツールのインストール
`$ sudo apt install thin-provisioning-tools`

フューチャー版をインストールする場合  
> 2018.9現在、3.4がインストールされます。  
>
> `$ sudo snap install lxd`
>
> 下記で安定版のインストールも可能  
> `$ sudo snap install --channel=3.0 lxd`

参考 コンテナ操作に必要なパッケージ
-   lxd
-   lxd-client
-   lxd-tools  
-   lxc-utils

マイグレーションに必要なパッケージ
-   criu

### LXDの初期化
LXDの初期設定を行います。
クラスタは組まずにLXDのリモート制御を許可します。  

まずは一般ユーザでlxcコマンドを実行するために一般ユーザをlxdグループに追加します。例ではvagrantユーザです。


```
現在の所属グループの確認
$ id vagrant
uid=1000(vagrant) gid=1000(vagrant) groups=1000(vagrant)

lxdグループへの追加
$ sudo gpasswd -a vagrant lxd
Adding user vagrant to group lxd
$ newgrp lxd

追加後の確認
$ getent group lxd
lxd:x:108:ubuntu,vagrant  

$ id vagrant
uid=1000(vagrant) gid=1000(vagrant) groups=1000(vagrant),108(lxd)
```

LXDの初期化を行います。

`$ lxd init`

```
Would you like to use LXD clustering? (yes/no) [default=no]:
Do you want to configure a new storage pool? (yes/no) [default=yes]:
Name of the new storage pool [default=default]:
Name of the storage backend to use (btrfs, dir, lvm) [default=btrfs]:
Create a new BTRFS pool? (yes/no) [default=yes]:
Would you like to use an existing block device? (yes/no) [default=no]:
Size in GB of the new loop device (1GB minimum) [default=15GB]:
Would you like to connect to a MAAS server? (yes/no) [default=no]:
Would you like to create a new local network bridge? (yes/no) [default=yes]:
What should the new bridge be called? [default=lxdbr0]:
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 172.16.0.1/24
Would you like LXD to NAT IPv4 traffic on your bridge? [default=yes]:
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: none
Would you like LXD to be available over the network? (yes/no) [default=no]: yes
Address to bind LXD to (not including port) [default=all]:
Port to bind LXD to [default=8443]:
Trust password for new clients:
Again:
Would you like stale cached images to be updated automatically? (yes/no) [default=yes]
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]: yes
```


### コンテナイメージの取得と起動
コンテナを作成するために公式サーバからコンテナイメージをダウンロードします。


-   コンテナの作成  
コンテナ名を明示的に指定しない場合、コンテナ名はランダムになります。

```
$ lxc launch ubuntu:18.04 CONTAINER_NAME
Creating CONTAINER_NAME
Starting CONTAINER_NAME
```

※一度コンテナイメージをDLした後はすぐにコンテナを作成出来ます

### コンテナの状態確認

```
$ lxc list
+----------+---------+--------------------+------+------------+-----------+
|   NAME   |  STATE  |        IPV4        | IPV6 |    TYPE    | SNAPSHOTS |
+----------+---------+--------------------+------+------------+-----------+
| ubuntu01 | RUNNING | 172.16.0.29 (eth0) |      | PERSISTENT | 0         |
+----------+---------+--------------------+------+------------+-----------+
```

### コンテナイメージの確認

-   取得済コンテナイメージのリスト表示

```
$ lxc image list
+-------+--------------+--------+---------------------------------------------+--------+----------+-----------------------------+
| ALIAS | FINGERPRINT  | PUBLIC |                 DESCRIPTION                 |  ARCH  |   SIZE   |         UPLOAD DATE         |
+-------+--------------+--------+---------------------------------------------+--------+----------+-----------------------------+
|       | 7e8633da9dfc | no     | ubuntu 18.04 LTS amd64 (release) (20180808) | x86_64 | 173.86MB | Aug 9, 2018 at 1:06pm (UTC) |
+-------+--------------+--------+---------------------------------------------+--------+----------+-----------------------------+
```

-   NAMEがimagesのイメージ取得先内にあるコンテナーイメージ一覧の表示

```
イメージ取得先を確認
$ lxc remote list

コンテナイメージの一覧表示
下記はリモートイメージ取得先「images」内のコンテナイメージを表示します

$ lxc image alias list images:


上記で一覧を確認し、イメージ取得先とコンテナ名を指定してコンテナを取得。
$ lxc launch images:alpine/3.8 CONTAINER_NAME
```

### コンテナでのコマンド実行

-   コンテナ内部でシェルを実行  
通常のLinuxにログインしたようなイメージ。各種コマンドが使えます。

```
$ lxc exec ubuntu01 /bin/bash
root@ubuntu:~#
```  

-   コマンドを実行  
`$ lxc exec ubuntu01 apt update`  

-   コンテナの停止  
`$ lxc stop ubuntu01`  

-   全コンテナの停止  
`$ lxd shutdown`

-   コンテナの開始  
`$ lxc start ubuntu01`

-   コンテナの削除  
コンテナを停止しないと削除できません。  
`$ lxc stop ubuntu01`  
`$ lxc delete ubuntu01`

---

### ストレージ
まずストレージプールを作成し、その中に論理ボリュームを作成します。
コンテナイメージは論理ボリュームの中に格納されます。  
公式推奨はストレージプールは専用のブロックデバイスです。

ストレージプールを削除するにはボリュームがアタッチされてないこと、プロファイルで使用されていないことが条件となります。  
コンテナイメージはアタッチされていませんが、ボリューム上に存在するため、lxc imageコマンで削除します。

#### ストレージプールのリスト

```
$ lxc storege list  
+---------+-------------+--------+---------+---------+
|  NAME   | DESCRIPTION | DRIVER |  STATE  | USED BY |
+---------+-------------+--------+---------+---------+
| default |             | btrfs  | CREATED | 3       |
+---------+-------------+--------+---------+---------+
```

#### ストレージプールの情報確認（使用率やサイズ）

```
$ lxc storage info default
info:
  description: ""
  driver: btrfs
  name: default
  space used: 690.43MB
  total space: 15.00GB
used by:
  images:
  - c395a7105278712478ec1dbfaab1865593fc11292f99afe01d5b94f1c34a9a3a
  - e0d18f40adbfd9bf09b6022cf566c45e9349194f0138b9af9c63fec508959543
  profiles:
  - default
```

#### ストレージプールの状態や参加しているクラスタの表示  

$ lxc storage edit STORAGE_POOL_NAME で編集可能。

```
$ lxc storage show default
config: {}
description: ""
name: default
driver: btrfs
used_by:
- /1.0/images/c395a7105278712478ec1dbfaab1865593fc11292f99afe01d5b94f1c34a9a3a
- /1.0/images/e0d18f40adbfd9bf09b6022cf566c45e9349194f0138b9af9c63fec508959543
- /1.0/profiles/default
status: Created
locations:
- node01
```

#### ストレージ内のボリュームを表示　　

```
$ lxc storage volume list default
+-------+------------------------------------------------------------------+-------------+---------+----------+
| TYPE  |                               NAME                               | DESCRIPTION | USED BY | LOCATION |
+-------+------------------------------------------------------------------+-------------+---------+----------+
| image | c395a7105278712478ec1dbfaab1865593fc11292f99afe01d5b94f1c34a9a3a |             | 1       | node01   |
+-------+------------------------------------------------------------------+-------------+---------+----------+
| image | e0d18f40adbfd9bf09b6022cf566c45e9349194f0138b9af9c63fec508959543 |             | 1       | node01   |
+-------+------------------------------------------------------------------+-------------+---------+----------+
```

#### イメージの確認　

```
$ lxc image list
$ lxc image info FINGERPRINT
$ lxc image show FINGERPRINT
```

#### イメージの削除
$ lxc image delete FINGERPRINT

#### ボリュームの削除

-   ボリュームの名前確認  
```
$ lxc storage volume list default
+--------+--------+-------------+---------+----------+
|  TYPE  |  NAME  | DESCRIPTION | USED BY | LOCATION |
+--------+--------+-------------+---------+----------+
| custom | alessi |             | 0       | node01   |
+--------+--------+-------------+---------+----------+
```

-   ボリュームの削除   
```
$ lxc storage volume delete default alessi
Storage volume alessi deleted
```

#### ストレージプールの作成  
・事前にLXDホストにブロックデバイスをアタッチしておきます。  
・ストレージに使えるファイルフォーマットはbtrfs,ceph,dir,lvm,zfsです。  
・LVMで作成する場合、ボリュームグループは作成しておき、論理ボリュームは未作成の状態で行います。（論理ボリュームがあるとエラーが発生します）  


-   ストレージプールの作成(LVM)
パーテーションは/dev/sdc1を作成し、LVMフラグ付与済であること。


```
$ lxc storage create lxd_vol01 lvm source=/dev/sdc1 lvm.thinpool_name=lxd_thin_vol01
Storage pool lxd_vol01 created
```

すでにボリュームグループが存在する場合
```
$ lxc storage create lxd_vol01 lvm source=LVM_VOL_GROUP_NAME lvm.thinpool_name=lxd_thin_vol01
Storage pool lxd_vol01 created
```

-   ストレージの確認
```
$ lxc storage list
+-----------+-------------+--------+-----------+---------+
|   NAME    | DESCRIPTION | DRIVER |  SOURCE   | USED BY |
+-----------+-------------+--------+-----------+---------+
| lxd_vol01 |             | lvm    | lxd_vol01 | 0       |
+-----------+-------------+--------+-----------+---------+
```

-   ストレージの設定、情報確認
used by:に何もないのでどのプロファイルにも所属していません。
```
$ lxc storage show lxd_vol01
config:
  lvm.thinpool_name: LXDThinPool
  lvm.vg_name: volgroup01
description: ""
name: lxd_vol01
driver: lvm
used_by: []
status: Created
locations:
- node01

$ lxc storage info lxd_vol01
info:
  description: ""
  driver: lvm
  name: lxd_vol01
  space used: 0B
  total space: 10.00GB
used by: {}

```

-   プロファイルにストレージプールを追加
```
$ lxc profile device add default root disk path=/ pool=lxd_vol01
Device root added to default
```

-   ストレージがプロファイルに所属していることの確認
profiles:とname

```
$ lxc storage info lxd_vol01
info:
  description: ""
  driver: lvm
  name: lxd_vol01
  space used: 0B
  total space: 10.00GB
used by:
  profiles:
  - default

$ lxc profile show default
config: {}
description: Default LXD profile
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: lxdfan0
    type: nic
  root:
    path: /
    pool: lxd_vol01
    type: disk
name: default
used_by: []
```




#### ストレージプールの削除  
-   プロファイル名の確認　
```
$ lxc profile list
+---------+---------+
|  NAME   | USED BY |
+---------+---------+
| default | 0       |
+---------+---------+
```

-   プロファイル内のデバイスを確認
```
$ lxc profile device list default
eth0
root
```

-   プロファイル内の設定を確認  
root以下がストレージの情報
```
$ lxc profile device show default
eth0:
  name: eth0
  nictype: bridged
  parent: lxdbr0
  type: nic
root:
  path: /
  pool: default
  type: disk
```

-   プロファイルからストレージプールを削除  
ストレージ
```
$ lxc profile device remove default root
Device root removed from default

$ lxc profile device list default
eth0
```

-   ストーレジプールの削除  
```
$ lxc storage list
+---------+-------------+--------+--------------------------------+---------+
|  NAME   | DESCRIPTION | DRIVER |             SOURCE             | USED BY |
+---------+-------------+--------+--------------------------------+---------+
| default |             | btrfs  | /var/lib/lxd/disks/default.img | 0       |
+---------+-------------+--------+--------------------------------+---------+

$ lxc storage delete default
Storage pool default deleted

$ lxc storage list
+------+-------------+--------+-------+---------+
| NAME | DESCRIPTION | DRIVER | STATE | USED BY |
+------+-------------+--------+-------+---------+
```

---

### ネットワーク

#### LXDホスト側のネットワーク

-   ブリッジインターフェースの表示
```
lxc network list
+--------+----------+---------+-------------+---------+
|  NAME  |   TYPE   | MANAGED | DESCRIPTION | USED BY |
+--------+----------+---------+-------------+---------+
| enp0s3 | physical | NO      |             | 0       |
+--------+----------+---------+-------------+---------+
| enp0s8 | physical | NO      |             | 0       |
+--------+----------+---------+-------------+---------+
| lxdbr0 | bridge   | YES     |             | 1       |
+--------+----------+---------+-------------+---------+
```


-   ブリッジインターフェースのDHCPスコープを変える
ハイフン区切りでNWアドレスを指定し、カンマ区切りで別セグメントを指定します。
```
$ lxc config set lxdbr0 ipv4.dhcp.ranges \
  10.154.195.10-10.154.195.10.20,10.154.195.110-10.154.195.10.120
```


#### コンテナのネットワーク
-   外部からの通信を許可  
通常はコンテナ→外部への通信は許可されていますが、その逆は許可されていません。


```
$ lxc config device add CONTAINER_NAME port8443 proxy listen=tcp:0.0.0.0:8443 connect=tcp:loc
alhost:8443
Device port8443 added to CONTAINER_NAME
```

```
$ lxc move ubuntu02 lxd01:
Error: Failed container creation:
 - https://10.0.2.15:8443: Error transferring container data: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "root@ubuntu-bionic")
 - https://192.168.10.180:8443: Error transferring container data: migration dump failed
(00.079663) Error (criu/sk-netlink.c:73): The socket has data to read
(00.079680) Error (criu/cr-dump.c:1352): Dump files (pid: 1947) failed with -1
(00.108968) Error (criu/cr-dump.c:1709): Dumping FAILED.
 - https://172.16.0.2:8443: Error transferring container data: Unable to connect to: 172.16.0.2:8443
```


---

### リモート制御

#### リモートLXDサーバからの接続を受け入れる設定
*   LXD01  
`$ lxc config set core.https_address "[::]"`  
`$ lxc config set core.trust_password password`

*   LXD02  
`$ lxc config set core.https_address "[::]"`  
`$ lxc config set core.trust_password password`

設定値確認

```
$ lxc config show
config:
  core.https_address: '[::]'
  core.trust_password: true
```

#### リモートサーバの登録
-   LXD01    
```
$ lxc remote add lxd02 192.168.10.180
Generating a client certificate. This may take a minute...
Certificate fingerprint: e3e02e2866d3d125e96112a74f4055dd0b300fcafec061774db29ef15868dfef
ok (y/n)? y
Admin password for lxd02:
Client certificate stored at server:  lxd02
```

-   LXD02  
```
$ lxc remote add lxd01 192.168.10.170
Generating a client certificate. This may take a minute...
Certificate fingerprint: a77c93d52df47e419169446c4dec4e977a31ce39bc1068cf77aa67e65c00b385
ok (y/n)? y
Admin password for lxd01:
Client certificate stored at server:  lxd01
```

#### リモートサーバリストの確認
「default」がlxcコマンドで実行されるホストになります。
下記例ではローカルのLXDホスト。
先程登録したlxd02をデフォルトにするとlxcコマンドはlxd02で実行されます。
またlxc launchコマンドでイメージを取得する際のサーバも同じです。

```
$ lxc remote list
+-----------------+------------------------------------------+---------------+--------+--------+
|      NAME       |                   URL                    |   PROTOCOL    | PUBLIC | STATIC |
+-----------------+------------------------------------------+---------------+--------+--------+
| images          | https://images.linuxcontainers.org       | simplestreams | YES    | NO     |
+-----------------+------------------------------------------+---------------+--------+--------+
| local (default) | unix://                                  | lxd           | NO     | YES    |
+-----------------+------------------------------------------+---------------+--------+--------+
| lxd02           | https://192.168.10.180:8443              | lxd           | NO     | NO     |
+-----------------+------------------------------------------+---------------+--------+--------+
| ubuntu          | https://cloud-images.ubuntu.com/releases | simplestreams | YES    | YES    |
+-----------------+------------------------------------------+---------------+--------+--------+
| ubuntu-daily    | https://cloud-images.ubuntu.com/daily    | simplestreams | YES    | YES    |
+-----------------+------------------------------------------+---------------+--------+--------+
```

-   リモートサーバのコンテナを操作します。  
lxd01からlxd02のubuntu02コンテナでapt updateを実行する例。  
`$ lxc exec lxd02:ubuntu02 apt update`

#### リモート操作対象サーバ設定
デフォルトで操作を行うLXDサーバとイメージ取得先を指定出来ます。


```
イメージ取得先URLと名前の追加
$ lxc remote set-url https://www.container.com/ NAME

デフォルトサーバの設定
$ lxc remote set-default NAME
$ lxc remote list
```

##### コンテナ、コンテナイメージの確認  

-   稼働中のコンテナの状態を表示します。  

```
$ lxc list  
+----------+---------+------+------+------------+-----------+
|   NAME   |  STATE  | IPV4 | IPV6 |    TYPE    | SNAPSHOTS |
+----------+---------+------+------+------------+-----------+
| ubuntu01 | STOPPED |      |      | PERSISTENT | 0         |
+----------+---------+------+------+------------+-----------+
```  

-   コンテナの詳細を表示します。  
```
$ lxc info ubuntu01
Name: ubuntu01
Location: node01
Remote: unix://
Architecture: x86_64
Created: 2018/09/27 12:22 UTC
Status: Running
Type: persistent
Profiles: default
Pid: 9114
Ips:
  lo:   inet    127.0.0.1
  lo:   inet6   ::1
  eth0: inet    172.16.0.235    veth0OLNUR
  eth0: inet6   fe80::216:3eff:fe00:6ab1        veth0OLNUR
Resources:
  Processes: 34
  CPU usage:
    CPU usage (in seconds): 7
  Memory usage:
    Memory (current): 142.45MB
    Memory (peak): 178.27MB
  Network usage:
    eth0:
      Bytes received: 342.26kB
      Bytes sent: 11.85kB
      Packets received: 263
      Packets sent: 164
    lo:
      Bytes received: 1.04kB
      Bytes sent: 1.04kB
      Packets received: 15
      Packets sent: 15
```

-   コンテナイメージのリストを表示します。

```
$ lxc image list  
+-------+--------------+--------+---------------------------------------------+--------+----------+-------------------------------+
| ALIAS | FINGERPRINT  | PUBLIC |                 DESCRIPTION                 |  ARCH  |   SIZE   |          UPLOAD DATE          |
+-------+--------------+--------+---------------------------------------------+--------+----------+-------------------------------+
|       | c395a7105278 | no     | ubuntu 18.04 LTS amd64 (release) (20180911) | x86_64 | 173.98MB | Sep 20, 2018 at 12:09pm (UTC) |
+-------+--------------+--------+---------------------------------------------+--------+----------+-------------------------------+
```

-   コンテナイメージの詳細を表示します。

```
$ lxc image show FINGERPRINT
auto_update: true
properties:
  architecture: amd64
  description: ubuntu 18.04 LTS amd64 (release) (20180911)
  label: release
  os: ubuntu
  release: bionic
  serial: "20180911"
  version: "18.04"
public: false
```

### コンテナ内ファイルの操作




### マイグレーション
LXDホスト間でコンテナの移動を行います。  
※2018.9現在、1度マイグレーションを行ったコンテナは元のLXDホストに戻すときに、
エラーが発生します。

#### 条件


#### マイグレーションを行うLXDサーバのリモートリストを登録する。

リモートLXDサーバからの接続を受け入れる設定  
*   LXD01  
`$ lxc config set core.https_address "[::]"`  
`$ lxc config set core.trust_password password`

*   LXD02  
`$ lxc config set core.https_address "[::]"`  
`$ lxc config set core.trust_password password`


-   リモートLXDホストの追加(lxd01)  
`$ lxc remote add NAME 192.168.10.180`  
※IPアドレスはLXDホスト

-   リモートLXDホストの追加(lxd02)  
`$ lxc remote add NAME 192.168.10.170`  
※IPアドレスは対抗LXDホスト

#### コールドマイグレーション
1.  移動対象のコンテナを止める  
lxd01のubuntu01コンテナを停止して、lxd02で動かす例。  
お互いにリモート操作出来る設定が済んでいることが条件です。

```
lxd01での操作
$ lxc list #コンテナのSTATEを確認。RUNNINGであること。
$ lxc stop ubuntu01
$ lxc list #コンテナのSTATEを確認。STOPPEDであること。
```

2.  マイグレーションの実行  

マイグレーション
```
lxd01での操作
$ lxc move ubuntu01 lxd02:
```

マイグレーション後の確認
```
lxd02での操作
$ lxc list #NAME ubuntu01が存在すること。
```

#### ライブマイグレーション
LXDホスト間でコンテナを移動します。
LXC/LXDのバージョンは合わせておきます。  
※一般ユーザが実行する場合、lxdグループに入っていないとsudoで実行しても失敗します

-   ライブマイグレーションの実行  
実行するのはLXD01ホスト。LXD01ホストのコンテナ名ubuntuをlxd02ホストへ移動。

`$ lxc move ubuntu lxd02:`

### クラスタリング  
公式推奨の構成は少なくとも3台のホストです。  
構成するには稼働中のコンテナとコンテナイメージがないことが条件です。  
LXD2.0.11はクラスタ非対応です。

#### 条件
-   クラスタ内のlxdホストは全て同じストレージプール、ネットワークが同じ構成であること。


#### コンフィグの作成
-   ブートストラップノード

```node01.yml
config:
  core.https_address: 192.168.10.170:8443
  core.trust_password: cluster
cluster:
  server_name: node01
  enabled: true
  cluster_address: ""
  cluster_certificate: ""
  cluster_password: ""
networks:
- config:
    bridge.mode: fan
  description: ""
  managed: false
  name: lxdfan0
  type: ""
storage_pools:
- name: default #各lxdホストの値
  driver: btrfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdfan0
      type: nic
  name: default
```

`$ cat node01.yml | lxd init --preseed`  

-   ターゲットブートストラップノード

```node02.yml
config:
  core.trust_password: password #各lxdホストの値
  core.https_address: 192.168.10.180:8443 #各lxdホストの値
  images.auto_update_interval: 15
storage_pools:
- name: default #各lxdホストの値
  driver: btrfs
networks:
- name: lxdbr0
  type: bridge
  config:
    ipv4.address: 172.16.0.2/24 #各lxdホストの値
    ipv6.address: none
profiles:
- name: default
  devices:
    root:
      path: /
      pool: default
      type: disk
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
cluster:
  enabled: true
  server_name: node02
  server_address: 192.168.10.180:8443
  cluster_address: 10.0.0.1:8443
  cluster_certificate: "
-----BEGIN CERTIFICATE-----
MIIFXDCCA0SgAwIBAgIRAKC48qXgtDD6nQ/cB2sVpfQwDQYJKoZIhvcNAQELBQAw
OzEcMBoGA1UEChMTbGludXhjb250YWluZXJzLm9yZzEbMBkGA1UEAwwScm9vdEB1
YnVudHUtYmlvbmljMB4XDTE4MDkyNjEyMzAzMVoXDTI4MDkyMzEyMzAzMVowOzEc
MBoGA1UEChMTbGludXhjb250YWluZXJzLm9yZzEbMBkGA1UEAwwScm9vdEB1YnVu
dHUtYmlvbmljMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAx8Cx7Tyf
h20sExLElhGyCUY6q0++wclCTG1GijVpKz+9xyeLiluKHozomtQaDjxgbXmKaOmX
EFUK21yEGslb4yD6NotMcfdjQ70wbEQCJp8vb7LG+GiD7r0HE1A0e/iKc2ULALGT
VmWKAdgpBhGFFQUN5ceGAUytbG29QhK3o74RRAB6yu0B3hvjFQO1OPjTOYeAkawI
KooB6/B+zCA9ZbhEdtAjUa0c6KE3hhEjnBVTG/K/+SxQiYdOsRQ3hz7g7okc/mpJ
/aEaQ2izK3rNOWUQZlYsPi66l1Tfl3jr6QFeD7MooxVylb5FtV1cs1xszKEPbJeg
LppgytB5fD5QZMqt0yRNLd2OnDpu/gTAi+j9ySBupTvs16efZbkCJoou5XFN2/Eh
TaotTsRIBGrB+bswy9PcM1grsvfEqyb11RJxydirhdhZjhJELVFvh3YsAuxNVBP7
i4l/EL20RYmBKDqXj1H8aNPU57XJVLyZinKBXsPtpyHfh6VX9benuz3e8jHEbgL1
HQMupGtHJNxblE+KdS8ZtWUxed5TWQ1eShcn8CKRDVqUZwMC4KCatnGZOpTijQvY
d+23JGPA2ksz/leqnD/7GAANhLp3BPR/R0lVzsb0ZuPS1n5bZaazkNMK2Ira452e
Im+jMGmkz+RctW5SjLT1GdkxIKD6sJWnauMCAwEAAaNbMFkwDgYDVR0PAQH/BAQD
AgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMBMAwGA1UdEwEB/wQCMAAwJAYDVR0RBB0w
G4INdWJ1bnR1LWJpb25pY4cECgACD4cEwKgKtDANBgkqhkiG9w0BAQsFAAOCAgEA
GWnjwz98GcfwR0Byk9rASBaM2vSMNqcRGoHjgM9DTfLCGNfoQyM1amk0fGDcD8Ju
VpK5VVdbbtF9lCzrGucDfQjYxwibnLGW+EZLEtAtWc9asT6rpTzWD1BYbNr1M4/J
21mLQ1r8sSiwcuX2gE8VgS8A51ZSLstw0Roc5EdmQRHdkung3PFPQD1zipV+3sxh
uaNZruqi3Cy30cFa0+Ji86md42J0H/c3mL7Mkj3/e+O9Z8lSYFc5ONr/+YxuSDKC
L8SN6cd5s/T4tUARtxhiA4a2PPQEY/2W7AhVcaPhpSVDEFyoko0S0mA9M1cN8TlR
rRFWhENr6vgsK4nyUDkBe1AHHNxqFPP4XP9HyzEhczpS2l32C2JjB6mHtJUpfDN3
ZQIv70zKWBiygfyQwyRfNDkRgZNuCfOGN5inCNmo7fgtM97JtTEavhTTC+iSWRL0
Qb2OVuhsKFukU1STi5Nxc3KeaN+U9bbEU4/cI+CRHtisgFT85lxLk3L3lnqA3d/r
+vPQiu0Mr+hIDgdBG7Awf/FzOnKHcKUTZrBSgTQLZCIoZRNIoc/pZHydvRaujmMm
r7bk8H4Zn2LloJudUc1AbaVKeDMwAFlD7OgZLayymEpJrKbyHhD/Nhq6FSSBC8NL
FWsK/8QhMYf6RQjhPFkHREMO6ERSQ1BMlWA1QGAxmmI=
-----ENDCERTIFICATE-----
"
  cluster_password: cluster
  member_config:
  - entity: storage-pool
    name: default
    key: source
    value: ""
```

### サービス
メインのサービス  
`$ sudo systemctl status lxd-containers.service`

間接サービス  
`$ sudo systemctl status lxd`  
こちらはindirect。

#### NW設定を誤った場合  
*   プロファイル名の確認

```
$ lxc profile list
+---------+---------+
|  NAME   | USED BY |
+---------+---------+
| default | 0       |
+---------+---------+
```
*   プロファイルの編集  
Ctrl + oで設定値保存。  
Ctrl + xでexit。  

```
$ lxc profile edit default
config: {}
description: Default LXD profile
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: lxdbr1
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: default
used_by:
```

*   ブリッジインターフェースの設定変更  

ネットワークリストの確認  
`$ lxc network list`

ブリッジインターフェースのIPアドレス変更  
`$ lxc network edit lxdbr0`

設定値の反映  
`$ sudo netplan apply`

### バックアップ
コンテナのバックアップ

### ホストの冗長化
コンテナはあくまでホスト上で稼働するため、ホストに障害が起こった際に、フェイルオーバーをさせるなどしてコンテナを止めることなく稼働させ続けるよう設計する必要があります。　　

### コンテナのプロセス
LXDホストとコンテナ内のプロセスは違います。  
通常はお互いにプロセスを見ることは出来ません。
コンテナのプロセスに負荷があった場合の監視設計として、ホストではなくコンテナ自体のプロセスをチェックする必要があります。

### ログの管理
プロセスと同じく、コンテナ内のログを監視・収集する必要がある点に注意。

### NW
各コンテナはホストのNICをブリッジして共有します。  
物理NIC自体をコンテナに割り当てることも出来ます。

### 物理リソース

## コンフィグの確認
`$ lxc config show`  

---

## 設計ポイント


## LXDで出来ないこと
*   LXDコンテナはカーネルモジュールをロードできない  
  →LXDホストがロードする必要がある


## LXDコンテナでdockerを動かすときの注意点
LXDコンテナはカーネルモジュールをロードできないので、Dockerの設定に応じて、必要な追加のカーネルモジュールをホストがロードする必要があります。
そのためにコンテナのsecurity.nestingプロパティをtrueに設定する必要があります。

docker使うならLXD/LXCではなくkubernetesを使えば・・・  
[How can I run docker inside a LXD container?](https://lxd.readthedocs.io/en/latest/#how-can-i-run-docker-inside-a-lxd-container)


## 構築資料
### ansible
※未作成  
LXDでコンテナを実装するためのansibleプレイブックです。  
`$ ansible-playbook -i inventory.ini --ask-become-pass --ask-pass container.yml`

### 基本操作
[はじめに - コマンドライン](https://linuxcontainers.org/ja/lxd/getting-started-cli/)

### ドキュメント
[LXD](https://lxd.readthedocs.io/en/latest/)
