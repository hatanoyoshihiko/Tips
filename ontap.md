# Netapp Ontap buiilding tips

## Environment

- Ontap OS 9.8 or more

- Cluster01
  - node01
  - node02

- Cluster02
  - node01
  - node02

- Shelf
  - shelf01
  - shelf02

- Initial password
admin / password0

---

## Shelf Setup

### Turn on the shelf power

Note: Shelf ID must be different in cluster. Also controller has shelf id.

1. Remove end cap from front panel (Pull toward you)
2. Long press Orange colour button, if 2nd digit flushed, press several times
3. Long press to decide
4. Next, if 1st digit flushed, press several time and long press to decide
5. If both digit flushed, wait 10 second and power off shelf and power on shelf
  ※Attention lamp lights until power on
6. After booting , check the shelf id from front panel
7. Install end cap into front panel

### Check the shelf information after boot

```zsh
::> storage shelf show
::> storage shelf show -shelf-id NUMBER -bay
```

---

## Create Cluster

### Before Create Cluster

1. Unplug LAN cables except e0a,e0b
2. Login from node01 using a serial console

### Cluster Setup

- Cluster Setup

```zsh
::> cluster setup
Type yes to confirm and continue {yes}: yes

Enter the node management interface port [e0M]:
Enter the node management interface IP address: X.X.X.X
Enter the node management interface netmask: Y.Y.Y.Y
Enter the node management interface default gateway: Z.Z.Z.Z
```

- Create Cluster

```zsh
Do you want to create a new cluster or join an existing cluster? {create, join}: create

instead for this node to be used as a single node cluster? {yes, no} [no]:no

Exisiting cluster interface configuration found:
Do you want to use this configuration? {yes, no} [yes]: yes

Enter the cluster administrator's (username "admin") password:
Retype the password:

```

- Step 1 of 5

```zsh
::> Enter the cluster name: Cluster01
```

- Step 2 of 5

```zsh
::> Enter an additinal license ke []:
```

- Step 3 of 5

```zsh
Enter the cluster management interface port: e0M
Enter the cluster management IP address: A.A.A.A
Enter the cluster management interface netmask: B.B.B.B
Enter the cluster management interface default gateway: C.C.C.C
Enter the DNS domain names: ontap.local
```

- Step 4 of 5

```zsh
SFO will be enabled when the partner joins the cluster
```

- Step 5 of 5

```zsh
::> Where is the controller located []: ANYWHERE
```

- Check the cluster health

```zsh
::> cluster show
Health, Eligibility are true
```

### Adding Cluster Node

- cluster setup

1. Login from node02 using a serial console

```zsh
::> cluster setup
Type yes to confirm and continue {yes}: yes

Enter the node management interface port [e0M]:
Enter the node management interface IP address: H.H.H.H
Enter the node management interface netmask: I.I.I.I
Enter the node management interface default gateway: J.J.J.J
```

- Join Cluster

```zsh
Do you want to create a new cluster or join an exisiting cluster {join}: join
Exisiting Cluster interface configuration found:
Do you want to use this configuration {yes, no} [yes]: yes
```

- Step 1 of 3
Note: "169.254.X.X" is node01's IP Address(e0a or e0b)

```zsh
Enter the IP address of an interface on the private cluster network from the cluster  you want to join: 169.254.X.X
cluster you wanto to join: 169.254.X.X
Joining cluster at address 169.254.X.X
Cluster setup is complete/
```

```zsh
::> cluster show
Health, Eligibility are true
```

### Optional setting

- Rename Cluster Name

```zsh
::> cluster identity show
::> cluster identity modify -name NEW_CLUSTER_NAME
```

- Change Node Name

`::> system node rename -node OLD_NODE_NAME -newname NEW_NODE_NAME`

## General Setting

### Check System Health

```zsh
::> system health status show
::> system health alert show
::> system chassis show
::> system chassis fru show
```

### Change admin user password

`::> security login password -vserver CLUSTER_SVM -username admin`

### License

`::> system license add -license-code AAA,BBB`
`::> system license status show`

### Timezone

`::> timezone -timezone Asia/Tokyo`

### NTP
Note: If you want to set 2 or more NTP servers, run below.

`::> cluster time-service ntp server create -server X.X.X.X`
`::> cluster time-service ntp server create -server Y.Y.Y.Y`

### Time Synchronization

```zsh
::> set advanced
::*> cluster time-service ntp status show
::*> set admin
```

### SNMP

```zsh
::> options -option-name snmp.enable -option-value on
::> system snmp community add -community-name COMMUNITY_NAME -type ro -vserver SVM
::> system snmp init -init 1
::> system snmp traphost add -peer-address X.X.X.X
::> system snmp show
```

### Autosupport

Note: All nodes in cluster are set
Note: All address are limited within 5 address

`::> system node autosupport modify -to MAIL_ADDRESS -partner-address MAIL_ADDRESS1,MAIL_ADDRESS2 -mail-host X.X.X.X -from FROM_ADDRESS -support disable -node NODE_NAME`

- "support disable" stop to notify to Netapp Corp
- "to"  is important notification
- "partner-address" is all notification

### User

`::> security login create -vserver CLUSTER_SVM -user-or-group-name USER_NAME -application http -authentication-method password -role admin (readonly)`

- "application" can aloso specify below
  - http, ssh, console, service-processor

### RAID Option

`::> storage raid-options modify -node NODE_NAME -name raid.timeout 72`
`::> storage raild-options show -node * raid.timeout`

### Auto Giveback Off

Note: If you run "::> cluster ha modify -configure true" after "::> cluster ha modify -configure true",
you need to set this parameter again.

`::> system node run -node *options cf.giveback.auto.enable off`
`::> system node run -node* options cf.giveback.auto.enable`

### Auto Giveback Off on panic

`::> system node run -node *options cf.giveback.auto.after.panic.takeover off`
`::> system node run -node* options cf.giveback.auto.after.panic.takeover`

### Switch less Cluster

```zsh
::> set advanced
::*> network options switchless-cluster modify false|true
::*> network options switchless-cluster show
::*> network options detect-switchless modify false|true
::*> network options detect-switchless show
```

### Aggregate

- General case

```zsh
::> storage disk show
::> storage aaggregate create AGGR_NAME -node NODE_NAME -raidtype raid_dp -disklist DISK_NO,DISK_NO -simulate true
::> storage aaggregate create AGGR_NAME -node NODE_NAME -raidtype raid_dp -disklist DISK_NO,DISK_NO
::> storage aggregate show
```

- Case of less than 4 disks

```zsh
::> set adavanced
::*> storage aggregate create -aggregate AGGR_NAME -node NODE_NAME -raidtype raid_dp -disklist DISK_NO,DISK_NO -force-small-aggregate -simulate true
::*> storage aggregate create -aggregate AGGR_NAME -node NODE_NAME -raidtype raid_dp -disklist DISK_NO,DISK_NO -force-small-aggregate -simulate
```

- Rename Aggregate Name

```zsh
::> storage aggregate rename -aggregate OLD_AGGR_NAME -newname NEW_AGGR_NAME
::> storage aggregate show
::> storage aggregate show -aggregate AGGR_NAME
```

- Check Disk Owner

`::> storage disk show -partition-ownership`

- Check Spare Disks

`::> storage aggregate show-spare-disks -original-owner NODE_NAME`

- Change Disk Owner

```zsh
::> storage disk option modify -node * -autoassign off
::> storage disk show
::> set adavanced
::*> storage disk removeowner -disk DISK_NO
::*> storage assign -disklist DISK_NO,DISK_NO -owner NODE_NAME
::*> storage assign -force -data true -disk DISK_NO,DISK_NO -owner NODE_NAME
::> storage disk option modify -node * -autoassign on
::*> set admin
```

---

## SVM

```zsh
::> vserver create -vserver SVM_NAME -aggregate AGGR_NAME -rootvolume-security-style mix -language C.UTF-8 -ipspace default
::> vserver add-aggregates -vserver SVMNAME -aggregates AGGR,AGGR
::> vserver show
::> vserver show -instance
```

---

## Volume

Note: Case of Snapmirror disk, "-type dp"

`::> volume create -vserver SVM -volume VOL_NAME -aggregate AGGR -size xTB -junction-path /xxx -type RW -language C.UTF-8`
`::> volume modify -vserver SVM -volume VOL_NAME -autosize-mode off`

---

## Qtree

---

## Quota

---

## flash pool

### Create Storage pool for flash pool

Note: "-disklist" does not include Spare Disk.

```zsh
::> storage aggregate show-spae-disks -disk-type SSD
::> storage pool create -storage-pool POOL_NAME -disklist DISK_NO,DISK_NO -simulate true
::> storage pool create -storage-pool POOL_NAME -disklist DISK_NO,DISK_NO -simulate
::> storage pool show POOL_NAME
::> storage pool show-available-capacity
```

### Enable flash pool on aggregate

```zsh
::> storage aggregate add-disks -aggregate AGGR_NAME -storage-pool POOL_NAME -allocation-units 1 -raidtpe raid4
::> storage aggregate show AGGR_NAME
```

### Cash hit rate check

`::> flash-pool show`

---

## Dedupe and Compression

Note: "-data-compaction" gathers to compress efficiently less than 4KB file.
4KB is Ontap block size.

```zsh
::> job schedule cron create -name SCHED_NAME -hour 22 -minute 0
::> volume efficency policy create -vserver SVM -policy POLICY_NAME -schedule SCHED_NAME
::> volume efficiency on -vserver SVM -volume VOL_NAME
::> volume efficiency modify -vserver SVM -volume VOL_NAME -policy POLICY_NAME -compression true
```

- If Data exists in Volume before Dedupe and Comression setting, You need to run below.

`::> volume efficiency start -vserver SVM -volume VOL_NAME -scan-old-data true`

## Snapshot

- Change Space for snapshot in volume
Note: This case reserves 20% capacity in volume. This capacity is used to also snapmirror's snapshot.

`::> volume modify -vserver SVM -volume VOL_NAME -percent-snapshot-space 20`

- Create Job Schedule and Insert Schedule to Snapshot policy include number of generations.
Note: The total number of generations in each schedule is limited within 1023.

```zsh
::> job schedule cron create -name SCHED_NAME -hour 0 -minute 0
::> volume snapshot policy create -policy POLICY_NAME -enabled true -schedule1 SCHED_NAME -count GEN_NO
```

- Change number of generations
`::> volume snapshot policy modify-schedule -policy POLICY_NAME -schedule SCHED_NAME -newcount GEN_NO`

- Enable Snapshot Auto Delete
Note: If Snapshot capacity(snap_reerve) is full, snapshot is deleted until value specified "-target-free-space"

```zsh
::> volume modify -volume VOL_NAME -snapshot-policy POLICY_NAME -vserver SVM
::> volume snapshot autodelete modify -volume VOL_NAME -enabled true -trigger snap_reserve -vserver SVM -target-free-space 20
::> volume snapshot autodelete show
```

- Delete Snapshots

```zsh
::> snapshot delete -vserver SVM -volume VOL_NAME -snapshot SNAPSHOT_NAME
::> snapshot delete -vserver SVM -volume VOL_NAME -snapshot *
::> snapshot show
```

---

## NW

- Create Link Aggregation
Note: "a0a" is first aggregated port.

```zsh
::> network port ifgrp create -node NODE_NAME -ifgrp a0a -distr-func ip -mode multimode_lacp
::> network port ifgrp add-port -node NODE_NAME -ifgrp a0a -port e0c
::> network port ifgrp add-port -node NODE_NAME -ifgrp a0a -port e0d
::> netwrok port ifgrp show
```

- Create VLAN Interface

```zsh
::> network port vlan create -node NODE_NAME -vlan-id xxx -port a0a
::> network port vlan create -node NODE_NAME -vlan-id xxx -port e0e
::> network port vlan show
```

- Create Broadcast domain

```zsh
::> network port broadcast-domain -create BCD_NAME-mtu 1500 -ports NODE_NAME:PORT, NODE_NAME:PORT
::> network port broadcast-domain remove-ports -broadcast-domain BCD_NAME remove-ports NODE_NAME:PORT
```

- Create Failover Groups

```zsh
::> network interface failover-groups create -vserver SVM -failover-group FG_NAME -targets NODE_NAME:PORT,NODE_NAME:PORT
::> failover-gropus show
```

- Create LIF for Data

```zsh
::> network interface create -vserver SVM -lif LIF_NAME -service-policy default-data-files -address X.X.X.X -netmask Y.Y.Y.Y -home-node NODE_NAME -home-port PORT -status-admin up -failover-policy system-defined -firewall-policy data -auto-revert false -failover-group FGN -is-dns-update-enabled true
::> network interface show LIF_NAME
```

- Create LIF for Snapmirror

```zsh
::> network interface create -vserver SVM -lif LIF_NAME -service-policy default-intercluster -address X.X.X.X -netmask Y.Y.Y.Y -home-node NODE_NAME -home-port PORT -status-admin up -failover-policy disable -is-dns-update-enabled false
::> network interface show LIF_NAME
```

- Create Static Routing

```zsh
::> network route create -vserver SVM -destination 0.0.0.0/0 -gateway X.X.X.X -metric 20
::> network route show
::> network route show-lifs
```

### Register DNS record using dynamic update

- Enable DDNS in LIF
`::> network interface modify -vserver SVM -lif LIF -is-dns-update-enabled true`

- Configure FQDN for LIF
`::> vserver services name-service dns dynamic-update modify -vserver SVM -is-enabled true -use-secure true  -domain-name XXX.local -vserver-fqdn filesv01.XXX.local`

- Check if the DNS server can be reached
`::> vserver services name-service dns check -vserver SVM`

- Manualdd Record to DNS server
`::> vserver services name-service dns dynamic-update record add -vserver SVM -lif LIF`
`::> vserver services name-service dns dynamic-update show`

### SP Port

`::> system service-processor network modify -node NODE_NAME -address-family IPv4 -enable true -ip-address X.X.X.X -netmask Y.Y.Y.Y -gateway Z.Z.Z.Z`
`::> system service-processor network show -instance`

---

## CIFS
Note: "A record" is not registered in default setting when CIFS server joined AD Domain.

- Enable DDNS
Note: "-vserver-fqdn"  specifies FQDN(xxx.local) you need.

```zsh
::> vserver services dynamic-update show
::> verver services name-service dns dynamic-update modify -vserver SVM -is-enabled true -use-secure true -vserver-fqdn XXX.local
```

- In case of an AD and DNS server exist in same server.

```zsh
::> vserver cifs create -cifs-server CSN -domain AD_DOMAIN_NAME -vserver SVM
::> vserver cifs show -vserver SVM
::> vserver cifs users-and-groups local-user set-password -user-name administrator -vserver SVM
::> vserver cifs users-and-groups local-user modify -vserver SVM -user-name administrator -isaccount-disabled true
```

- Enable CIFS Audit Log

```zsh
::> volume mount -vserver  -volume VOL_NAME -junction-path /VOL_MOUNT_PATH
::> vserver audit create -destination /VOL_MOUNT_NAME -events file-ops,cifs-logon-logoff -format evtx -rotate-limit number of generations -vserver SVM -rotate-schedule-hour 1 -rotate-schedule-minute 0
```

- Disable Audit Guarantee
Note: If you don't disable this parameter, In case of can not record audit log you are denied cifs access.

```zsh
::> set diagnostic
::*> vserver audit modify -vserver SVM -audit-guarantee false
::*> vserver audit show -fields audit-guarantees
```

-  Audit Staging Volume Extend
Note: If you enable CIFS Audit, Staging Volume(MDV_aud_xxx) is created

```zsh
::> set diag
::*> volume size -vserver SVM -volume MDV_aud_xxx -new-size 10g
::*> volume show -volume MDV_aud_xxx
```

- Create Cifs Server
Note: You must set ACL using windows explorer in stead of CLI

`::> vserver cifs share create -vserver SVM -share-name SHARE_NAME -path /JUNCTION_PATH`
`::> set advaned`
`::*> vserver cifs options show -vserver SVM`
`::> set admin`

---

## Snapmirror

### Create Cluster Peer

- SRC
Note: "X.X.X.X,Y.Y.Y.Y" is Destination snapmirror lif address

`::> cluster peer cleate -peer-addrs X.X.X.X,Y.Y.Y.Y`

- DEST
Note: "A.A.A.A,B.B.B.B" is Source snapmirror lif address

`::> cluster peer cleate -peer-addrs A.A.A.A,B.B.B.B`


- SRC,DEST

```zsh
::> cluster peer show -instance
::> cluster peer health show
```

### Create SVM Peer

- SRC

`::> vserver peer create -vserver SVM  -peer-vserver DEST_SVM -applications snapmirror -peer-cluster DEST_CLUSTER_NAME`

- DEST

`::> vserver peer accept -vserver SVM -peer-vserver SRC_SVM -applications snapmirror -peer-cluster SRC_CLUSTER_NAME`

- SRC

```zsh
::> vserver peer show-all
peer state:peered
```

- DEST
Note: You must set same volume name between SRC and DEST
Note: You must create DEST volume specifying "-type DP"

```zsh
::> job schele cron create -name SCHED_NAME -hour 1 -minute 0
::> snapmirror create -source-path SRC_SVM:VOL -destination-path DEST_SVM:VOL -vserver DEST_SVM throttle unlimited -identity-preserve false -type XDP -schedule SCHED_NAME
::> snampmirror initilize -destination-path DEST_SVM:VOL
::> snapmirror show
```

Note:
First status is "Mirror State:Snapmirrored"、Final Staus is "Relationship Status:Idle"

- SRC/DEST
Check the snapshot for snapmirror

`::> snapshot show`

- DEST

```zsh
::> snapmirror show
::> snapmirror show-history
result:success
```

### Abort active transfer

- DEST

`::> snapmirror abort`

### Manual Transfer

`::> snapmirror update`

### Pause and Resume

- Pause

`::>  snapmirror quiesce -destination-path DEST_SVM:DEST_VOL`

- Resume

`::>  snapmirror resume -destination-path DEST_SVM:DEST_VOL`

### Snapshot Restore

- File Restore

```zsh
::> volume snapshot show
::> volume snapshot restore-file -vserver SVM -snapshot SNAPSHOT_NAME -path /RESTORE_SOURCE_FILE_NAME -volume VOL -restore-path /FILE_NAME
```

- Volume Restore

`::> volume snapshot restore -vserver SVM -volume VOL_NAME -snapshot SNAPSHOT_NAME`

### Snapmirror restore

Note: You must run this way from DEST(DR) Ontap

- Check the snapshot name

`::> volume snapshot show`

- File Restore

`::> snapmirror restore -destination-path SRC_SVM:VOL -source-path DEST_SVM:VOL -source-snapshot SNAPSHOT_NAME -file-list /FILE_NAME`

- Volume Restore

`::> snapmirror restore -destination-path SRC_SVM:VOL -source-path DEST_SVM:VOL -source-snapshot SNAPSHOT_NAME`

---

## Node Shutdown
Note: This way launch until LOADER.
Note: You can turn off PSU after you checked display "LOADER-X"

- Normal shutdonw

`::> system node halt -node *-inhibit-takeover true -skip-lif-migration-before-shutdown true -ignore-quorum-warning true`

- Ontap does not boot on next power on

`::> system node halt -node* -inhibit-takeover true -skip-lif-migration-before-shutdown true -ignore-quorum-warning true -power-off true`

### Serrial Port

- Connect SP Port(Serial) from ssh
Note: You need to connect ssh SP_PORT_ADDRESS

`> system console`
`LOADER-A> boot_ontap`

---

## Storage Failover

### Controler failover

- Takeover(Failover)
Note: "NODE_NAME" shows node name you want to run

```zsh
::> storage failover takeover -ofnode NODE_NAME
::> storage failover show-takeover
```

- Giveback(Failback)

```zsh
::> storage failover giveback -ofnode NODE_NAME
::> storage failover show-giveback
```

### LIF Failover

- Migrate LIF to other node

`::> network interface migrate -vserver -lif LIF_NAME -dest-node NODE_NAME -dest-port e0c`

- Revert LIF to home port

`::> network interface revert -vserver SVM -lif LIF_NAME`
`::> revert *`

---

## Optional Setting

### Surrogate pair character setting

1. You run ontap shutdown(until LOADER)

2. set parameter
LOADER-X> setenv wafl-accept-surrogate-pair? true

3. Check the parameter

```zsh
LOADER-X> printenv wafl-accept-surrogate-pair?

Variable Name Value
----------------------------------------------------------------------
wafl-accept-surrogate-pair? true
```

4. boot ontap

`LOADER-X> boot_ontap`

### Suppression Management and Poerformance LOG from Autosupport

Note: MANAGEMENT_LOG、PERFORMANCE DATA are sent from Autosupport arround AM 0 o'clock
Note: MANAGEMENT_LOG、PERFORMANCE DATA can not change time to send
Note: MANAGEMENT_LOG can not suppress, if you want to supress you should remove address from "-partner-address"

- Disable PERFORMANCE DATA

`::> system node autosupport modify -node * -perf false`
`::> system autosupport show -fields perf`

### Disable NW Port

Note: If LAN cable is not plugged in port, Warning shows on GUI, so you should set this parameter.

`::> storage port disable -node NODE -port e0c`

---

### Create Event Notifications

Note: this sumple shows volume empty notification.
Note: Data Ontap 8.3 and above can not send snapmirror fail notification using snmp trap and mail.

- Create Mail Sender setting

```zsh
::> event config modify -mail-from ontap@ontap.local -mail-server 10.10.10.200
::> event config show
```

- Create Mail Recipient

```zsh
::> event notification destination create -name mail_destination -email info@ontap.local
::> event notification destination show
```

- Create Event Filter and adding rurle

```zsh
::> event filter create -filter-name mail_filter
::> event filter show
::> event filter rule add -filter-name mail_filter -type include -message-name monitor.volume.full
::> event filter rule add -filter-name mail_filter -type include -message-name monitor.volume.nearlyfull
::> event filter rule add -filter-name mail_filter -type include -message-name wafl.snap.create.skip.reason
::> event filter rule add -filter-name mail_filter -type include -message-name wafl.snap.create.fail.mem
::> event filter rule add -filter-name mail_filter -type include -message-name wafl.snap.create.skip.time
```

- Create Event Notification Setting

```zsh
::> event notification create -filter-name mail_filter -destinations mail_destination
::> event notification show
::> event notification history show
```

### Extend numbers of inode

- check number of inode
`df -i`
`::> volume show -vserver SVM -volume VOL -fields files`

- extend number of inode

`::> volume modify -vserver SVM -volume VOL -fields INODE_NUMBER`
