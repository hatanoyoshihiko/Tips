# How to use VPN on AWS

## Site to Site VPN

### Configure site to site vpn

Now writing.

### Tips

#### Prohibit routing propagation "0.0.0.0/0" from local network.  

- Fortigate setting

```
# config router bgp
    config neighbor
      edit 169.254.a.b
      set capability-default-originate disable
    end
  end
```

#### Control asymmetric routing

Note: The lower "Local Preference value" has higher the priority on routing.
Create route map on fortigate.

- create route map 01

```
# config router route-map
    edit "ROUTE-MAP01"
		  config rule
			  edit 1
				  set set-local-preference 100
				next
			end
		next
	end
```

- create route map 02

```
# config router route-map
    edit "ROUTE-MAP02"
		  config rule
			  edit 1
				  set set-local-preference 90
				next
			end
		next
	end
```

- Add route map on fortigate

```
# config router bgp
    set as 65000
		set router-od CUSTOMER_GATEWAY_IP_ADDRESS
		config neighbor
		edit "169.254.a.b"
		  set capability-default-originate enable
		  set remote-as 64512 
		  set route-map-in "ROUTE-MAP01"
		next
		edit "169.254.x.y"
		  set capability-default-originate enable
		  set remote-as 64512 
		  set route-map-in "ROUTE-MAP01"
		next
	end		
```

- Current routing information clear on fortigate  
  `# execute router clear bgp all`

- Check routing information  
  `# get route info bgp network`  
NOTE: "LocPrf 100" is most high priority routing below.

```
BGP table version is 7, local router ID is CUSTOMER_GATEWAY_IP_ADDRESS
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              S Stale
Origin codes: i - IGP, e - EGP, ? - incomplete

   Network            Next Hop            Metric LocPrf Weight RouteTag Path
*  172.20.1.0/24      169.254.173.62         200     90      0        0 64512 i
*>                    169.254.123.177        100    100      0        0 64512 i
*                     169.254.21.93          200     80      0        0 64512 i
*                     169.254.61.172         100     70      0        0 64512 i

Total number of prefixes 1
```
