# Hyper-V

## Switch Embedded teaming (SET)

NOTE:

- SR-IOV needs bios setting.
- Load Balancing and Failover (LBFO) can't use tag vlan, SR-IOV, RDMA, QoS, TCP Chimney offload, 802.1X authentication.

## Create SET

### Enable Hyper-V

Enable Hyper-V on server manager.

### Create Virtual Switch

Note:

- Use powershell using administrator mode
- Note: NIC1 and NIC2 show name that displays in ncpa.cpl

#### Create New Virtual Switch

- Create New virtual switch  

`> New-VMSwitch -Name "Virtual Switch - "SWITCH_NAME" -NetAdapterName "NIC1","NIC2" -TeamingMode "SwitchIndependent" -LoadBalancingAlgorithm "Dynamic"`

- Check setting  

`Get-VMSwitchTeam "Virtual Switch - "SWITCH_NAME"`

 1. check if "NetAdapterInterfaceDescription" has "{NIC1,NIC2}".
 2. check if "TeamingMode" has "SwitchIndependent".
 3. Check if "LoadBalancingAlgorithm" has "Dynamic"

#### Add nic port

if you need os network port for management, backup, etc, try below.
this port can use vlan (below example is access vlan)

- Add nic port to virtual switch (available apply network settings, etc. IP address)

`> Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "NIC__PORT_NAME" -Access -VlanID 100`

- Check setting

`> Get-VMNetworkAdapterVlan -ManagementOS`

#### Enable RDMA

- Check setting
check if "NetworkDIrect" has "Enabled", if not try below.****

`> Get-NetOffloadGlobalSetting`

- Enable the global TCP/IP offload setting

`> Set-NetOffloadGlobalSetting -NetworkDirect Enabled`

- Check setting
check if "Enabled" column has all "True", if not try below.

`> Get-NetAdapterRdma`

- Enable RDMA

`> Enable-NetAdapterRdma -Name "NIC_NAME"`
