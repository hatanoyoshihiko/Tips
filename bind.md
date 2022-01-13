# bind9

## environment

- os ubuntu 20.04
- BIND 9.16.1-Ubuntu

## install bind

`# apt install bind9 bind9-utils`

## create tsig key
`# dnssec-keygen -K /etc/bind -a ED25519 -P 20210430000000 -A 20210430000000 -I 20400101000000 20alessiareya.local`

## master server configuration

- /etc/bind/named.conf

```bash
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.log";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.internal-zones";
//include "/etc/bind/named.conf.default-zones";
```

- /etc/bind/named.conf.options

```bash
acl internal-acl {
	192.168.0.0/16;
	172.16.0.0/12;
	10.0.0.0/8;
	localhost;
};

options {
	version "unknown";
	directory "/var/cache/bind";
	dump-file               "/etc/bind/data/cache_dump.db";
	statistics-file         "/etc/bind/data/named_stats.txt";
	memstatistics-file      "/etc/bind/data/named_mem_stats.txt";
	listen-on port 53 { any; };
	listen-on-v6 { none; };

	max-cache-size 200M;
	max-cache-ttl 86400;
	max-ncache-ttl 300;

	auth-nxdomain no;
	notify no;

	recursion yes;
	allow-query { internal-acl; };
	allow-recursion { internal-acl; };
	allow-query-cache { internal-acl; };
	allow-transfer { none; };

	dnssec-validation auto;

	forwarders {
		192.168.11.1;
		1.1.1.1;
		8.8.8.8;
	};
};
```

- /etc/bind/named.conf.internal-zones

```bash
view "internal" {
	match-clients {
		192.168.0.0/16;
		172.16.0.0/12;
		10.0.0.0/8;
		localhost;
	};

	zone "alessiareya.local" IN {
	        type master;
	        file "/etc/bind/zone/alessiareya.local.zone";
		notify explicit;
		also-notify {
			192.168.11.210;
		};
		allow-transfer {
			192.168.11.210;
		};
	        allow-update { none; };
	};

	zone "168.192.in-addr.arpa" IN {
	        type master;
	        file "/etc/bind/zone/192.168.db";
		notify explicit;
		also-notify {
			192.168.11.210;
		};
		allow-transfer {
			192.168.11.210;
		};
	        allow-update { none; };
	};
	zone "16.172.in-addr.arpa" IN {
	        type master;
	        file "/etc/bind/zone/172.16.db";
		notify explicit;
		also-notify {
			192.168.11.210;
		};
		allow-transfer {
			192.168.11.210;
		};
	        allow-update { none; };
	};
	zone "10.in-addr.arpa" IN {
	        type master;
	        file "/etc/bind/zone/10.db";
		notify explicit;
		also-notify {
			192.168.11.210;
		};
		allow-transfer {
			192.168.11.210;
		};
	        allow-update { none; };
	};

	include "/etc/bind/named.conf.default-zones";
};
```

- /etc/bind/named.conf.log

```bash
logging {
	channel query_log {
		file "/var/log/named/query.log" versions 5 100M;
		severity dynamic;
//		severity debug;
		print-category yes;
		print-severity yes;
		print-time yes;
	};
	channel update_debug {
		file "/var/log/named/update_debug.log" versions 5 10M;
		severity debug;
		print-category yes;
		print-severity yes;
		print-time yes;
	};
	channel security_info {
		file "/var/log/named/security_info.log" versions 5 10M;
		severity info;
		print-category yes;
		print-severity yes;
		print-time yes;
	};
	channel bind_log {
		file "/var/log/named/bind.log" versions 5 10M;
		severity info;
		print-category yes;
		print-severity yes;
		print-time yes;
	};

	category queries {
		 query_log;
	};
	category update {
		 update_debug;
	};
	category security {
		 security_info;
	};
	category default {
		 bind_log;
	};
};
```

### log settings

- create log dir

```bash
# mkdir /var/log/named
# chown bind:root /var/log/named
# chmod 775 /var/log/named
```

- logrotate

```bash
# vi /etc/logrotate.d/named
cat /etc/logrotate.d/named
/var/log/named/*
{
	rotate 12
	weekly
	missingok
	notifempty
	create 0644 bind bind
	delaycompress
	compress
	postrotate
		kill -HUP `cat /var/run/named/named.pid`
	endscript
}
```

### zone files

- create zone dir

`# mkdir /etc/bind/zone`
`# chown root:bind /etc/bind/zone`
`# chmod 4755 /etc/bind/zone`

- /etc/bind/zone/alessiareya.local.zone

```bash
$TTL    60 ; Default TTL
$ORIGIN alessiareya.local.
@			IN	SOA ns1.alessiareya.local. postmaster.alessiareya.local. (
				2021042506		; Serial
				3600			; Refresh
				900			; Retry
				604800			; Expire
				300			; Negative cache TTL
			IN	NS	ns1
			IN	MX	10 mx
			IN	A 	192.168.11.253
				)
;
ns1			IN	A	192.168.11.200
mx			IN	A	192.168.11.200
www			IN	A	192.168.11.200
zabbix01		IN	A	192.168.11.200
ap01			IN	A	192.168.11.1
@			IN	TXT	"v=spf1 include:*.alessiareya.local ~all"
```


- /etc/bind/zone/192.168.11.db

```bash
$ORIGIN 168.192.in-addr.arpa.
$TTL	300 ; Default TTL
@	IN	SOA	ns1.alessiareya.local. postmaster.alessiareya.local (
	2021042308      ; Serial, YYYYMMDDVV (VV: version)
	3600            ; Refresh
	900             ; Retry
	3600000         ; Expire
	300             ; Negative cache TTL
	)

	IN	NS	ns1.alessiareya.local.
1.11	IN	PTR	ap01.alessiareya.local.
200.11	IN	PTR	alessiareya.local.
```

- /etc/bind/zone/172.16.db

```
$ORIGIN 16.172.in-addr.arpa.
$TTL	300 ;  Default TTL
@	IN	SOA	ns1.alessiareya.local. postmaster.alessiareya.local. (
	2021042304      ; Serial, YYYYMMDDVV (VV: version)
	3600            ; Refresh
	900             ; Retry
	3600000         ; Expire
	300             ; Negative cache TTL
	)

	IN	NS	ns1.alessiareya.local.
1.0	IN	PTR	ap01.alessiareya.local.
200.0	IN	PTR	alessiareya.local.
```

- /etc/bind/zone/10.db

```
$ORIGIN 10.in-addr.arpa.
$TTL	300 ;  Default TTL
@	IN	SOA	ns1.alessiareya.local. postmaster.alessiareya.local. (
	2021042304      ; Serial, YYYYMMDDVV (VV: version)
	3600            ; Refresh
	900             ; Retry
	3600000         ; Expire
	300             ; Negative cache TTL
	)

	IN	NS	ns1.alessiareya.local.
1.0.0	IN	PTR	ap01.alessiareya.local.
200.0.0	IN	PTR	alessiareya.local.
```


## slave server configuration

- /etc/bind/named.conf

```bash
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.internal-zones";
//include "/etc/bind/named.conf.default-zones";
```

- /etc/named/named.conf.options

```bash
acl internal-acl {
	192.168.0.0/16;
	172.16.0.0/12;
	10.0.0.0/8;
	127.0.0.1/32;
};

options {
	version			"unknown";
	directory		"/var/cache/bind";
	dump-file		"/etc/bind/data/cache_dump.db";
	statistics-file		"/etc/bind/data/named_stats.txt";
	memstatistics-file	"/etc/bind/data/named_mem_stats.txt";
	listen-on port 53 { any; };
	listen-on-v6 { none; };

	max-cache-size 100M;
	max-cache-ttl 86400;
	max-ncache-ttl 300;

	auth-nxdomain no;
	notify no;

	recursion yes;
	allow-query { internal-acl; };
	allow-recursion { internal-acl; };
	allow-query-cache { internal-acl; };
	allow-transfer { none; };

	dnssec-validation auto;

	forwarders {
		192.168.11.1;
		1.1.1.1;
		8.8.8.8;
	};
};
```

- /etc/bind/named.conf.internal-zones

```bash
view "internal" {
	match-clients {
		192.168.0.0/16;
		172.16.0.0/12;
		10.0.0.0/8;
		localhost;
	};

	zone "alessiareya.local" IN {
	        type slave;
	        file "/var/lib/bind/zone/alessiareya.local.zone";
		notify no;
		masters { 192.168.11.200; };
	};

	zone "168.192.in-addr.arpa" IN {
	        type slave;
	        file "/var/lib/bind/zone/192.168.db";
		notify no;
		masters { 192.168.11.200; };
	};
	zone "16.172.in-addr.arpa" IN {
	        type slave;
	        file "/var/lib/bind/zone/172.16.db";
		notify no;
		masters { 192.168.11.200; };
	};
	zone "10.in-addr.arpa" IN {
	        type slave;
	        file "/var/lib/bind/zone/10.db";
		notify no;
		masters { 192.168.11.200; };
	};

	include "/etc/bind/named.conf.default-zones";
};
```

- /etc/bind/named.conf.log

```bash
logging {
	channel query_log {
		file "/var/log/named/query.log" versions 5 100M;
		severity dynamic;
//		severity debug;
		print-category yes;
		print-severity yes;
		print-time yes;
	};
	channel update_debug {
		file "/var/log/named/update_debug.log" versions 5 10M;
		severity debug;
		print-category yes;
		print-severity yes;
		print-time yes;
	};
	channel security_info {
		file "/var/log/named/security_info.log" versions 5 10M;
		severity info;
		print-category yes;
		print-severity yes;
		print-time yes;
	};
	channel bind_log {
		file "/var/log/named/bind.log" versions 5 10M;
		severity info;
		print-category yes;
		print-severity yes;
		print-time yes;
	};

	category queries {
		 query_log;
	};
	category update {
		 update_debug;
	};
	category security {
		 security_info;
	};
	category default {
		 bind_log;
	};
};
```

- transfered zone files dir

`# mkdir /var/lib/bind/named`
`# chown -R /var/lib/bind`
`# chmod 4755 /var/lib/bind/named`

## bind tips

- config syntax check
`# named-checkconf`
`# named-checkconf /etc/bind/named.conf`

- zone file syntax check

```bash
# named-checkzone -d alessiareya.local /etc/bind/zone/alessiareya.local.zone
loading "alessiareya.local" from "/etc/bind/zone/alessiareya.local.zone" class "IN"
zone alessiareya.local/IN: loaded serial 2021042506
OK
```

- zone transfer from  slave server
`# rndc retransfer alessiareya.local`

- zone transfer from master server
`# rndc notify alessiareya.local`

-  zone file update

```
# rndc reload
server reload successful

# rndc reload alessiareya.local

# rndc reload alessiareya.local in internal
zone reload up-to-date
```

- check bind status

```
# rndc status
version: BIND 9.16.1-Ubuntu (Stable Release) <id:d497c32> (unknown)
running on zabbix01: Linux aarch64 5.4.0-1034-raspi #37-Ubuntu SMP PREEMPT Mon Apr 12 23:14:49 UTC 2021
boot time: Sat, 01 May 2021 14:16:04 GMT
last configured: Sat, 01 May 2021 14:16:04 GMT
configuration file: /etc/bind/named.conf
CPUs found: 4
worker threads: 4
UDP listeners per interface: 4
number of zones: 103 (94 automatic)
debug level: 0
xfers running: 0
xfers deferred: 0
soa queries in progress: 0
query logging is ON
recursive clients: 0/900/1000
tcp clients: 0/150
TCP high-water: 0
server is up and running
```
