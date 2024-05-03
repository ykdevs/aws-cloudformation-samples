# VPC間をSoftware VPNでつなぐ

## Network構成

### VPC1

| Type       | LogicalId                    | CIDR              | Remarks |
|------------|------------------------------|-------------------|---------|
| VPC        | Vpc1                         | 172.16.0.0/24     |         |
| Subnet     | Vpc1PrivateSubnet            | 172.16.0.0/28     |         |
| Subnet     | Vpc1PublicSubnet             | 172.16.0.16/28    |         |
| NatGateway | Vpc1PublicSubnetNatGateway   | 172.16.0.20/32    |         |
| EIP        | Vpc1PublicSubnetEIP          | 54.250.192.221/32 |         |
| EC2        | Vpc1PublicSubnetEC2Instance  |                   |         |
| EC2        | Vpc1PrivateSubnetEC2Instance |                   |         |

### VPC2

| Type       | LogicalId                    | CIDR            | Remarks |
|------------|------------------------------|-----------------|---------|
| VPC        | Vpc2                         | 172.16.1.0/24   |         |
| Subnet     | Vpc2PrivateSubnet            | 172.16.1.0/28   |         |
| Subnet     | Vpc2PublicSubnet             | 172.16.1.16/28  |         |
| NatGateway | Vpc2PublicSubnetNatGateway   | 172.16.1.20/32  |         |
| EIP        | Vpc2PublicSubnetEIP          | 54.95.174.76/32 |         |
| EC2        | Vpc2PublicSubnetEC2Instance  |                 |         |
| EC2        | Vpc2PrivateSubnetEC2Instance |                 |         |

### カーネルの設定

rootユーザになる

```bash
sudo su -
```

再起動しても大丈夫なように設定ファイルの値を変更する

```text:/etc/sysctl.d/99-sysctl.conf
cat << EOF >> /etc/sysctl.d/99-sysctl.conf
net.ipv4.ip_forward=1

net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.default.arp_ignore=1
net.ipv4.conf.enX0.arp_ignore=1

net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.enX0.send_redirects=0
net.ipv4.conf.lo.send_redirects=0

net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.enX0.accept_redirects=0
net.ipv4.conf.lo.accept_redirects=0

net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.enX0.rp_filter=0
net.ipv4.conf.lo.rp_filter=0
EOF
```

再起動して以下のコマンドで設定を確認

```bash
sysctl net.ipv4.ip_forward
```

### Libreswanのインストール

```bash
root@ip-172-16-0-30 ~]# sudo dnf install libreswan
Last metadata expiration check: 2:01:37 ago on Sun Apr 14 13:15:43 2024.
Dependencies resolved.
=============================================================================================================================================================================================================================================================================================================================
 Package                                                                       Architecture                                                          Version                                                                                Repository                                                                  Size
=============================================================================================================================================================================================================================================================================================================================
Installing:
 libreswan                                                                     x86_64                                                                4.12-3.amzn2023                                                                        amazonlinux                                                                1.3 M
Installing dependencies:
 ldns                                                                          x86_64                                                                1.8.3-2.amzn2023.0.1                                                                   amazonlinux                                                                177 k
 nss-tools                                                                     x86_64                                                                3.90.0-6.amzn2023.0.1                                                                  amazonlinux                                                                433 k
 unbound-libs                                                                  x86_64                                                                1.17.1-1.amzn2023.0.2                                                                  amazonlinux                                                                529 k
Installing weak dependencies:
 unbound-anchor                                                                x86_64                                                                1.17.1-1.amzn2023.0.2                                                                  amazonlinux                                                                 38 k

Transaction Summary
=============================================================================================================================================================================================================================================================================================================================
Install  5 Packages

Total download size: 2.4 M
Installed size: 8.2 M
Is this ok [y/N]: y
Downloading Packages:
(1/5): nss-tools-3.90.0-6.amzn2023.0.1.x86_64.rpm                                                                                                                                                                                                                                            2.4 MB/s | 433 kB     00:00
(2/5): ldns-1.8.3-2.amzn2023.0.1.x86_64.rpm                                                                                                                                                                                                                                                  855 kB/s | 177 kB     00:00
(3/5): libreswan-4.12-3.amzn2023.x86_64.rpm                                                                                                                                                                                                                                                  5.7 MB/s | 1.3 MB     00:00
(4/5): unbound-anchor-1.17.1-1.amzn2023.0.2.x86_64.rpm                                                                                                                                                                                                                                       708 kB/s |  38 kB     00:00
(5/5): unbound-libs-1.17.1-1.amzn2023.0.2.x86_64.rpm                                                                                                                                                                                                                                         3.8 MB/s | 529 kB     00:00
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                                                                                                        5.9 MB/s | 2.4 MB     00:00
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                                                                                                                                                     1/1
  Running scriptlet: unbound-libs-1.17.1-1.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                           1/5
[sss_cache] [sysdb_domain_cache_connect] (0x0010): DB version too old [0.22], expected [0.23] for domain implicit_files!
Higher version of database is expected!
In order to upgrade the database, you must run SSSD.
Removing cache files in /var/lib/sss/db should fix the issue, but note that removing cache files will also remove all of your cached credentials.
Could not open available domains
[sss_cache] [sysdb_domain_cache_connect] (0x0010): DB version too old [0.22], expected [0.23] for domain implicit_files!
Higher version of database is expected!
In order to upgrade the database, you must run SSSD.
Removing cache files in /var/lib/sss/db should fix the issue, but note that removing cache files will also remove all of your cached credentials.
Could not open available domains
[sss_cache] [sysdb_domain_cache_connect] (0x0010): DB version too old [0.22], expected [0.23] for domain implicit_files!
Higher version of database is expected!
In order to upgrade the database, you must run SSSD.
Removing cache files in /var/lib/sss/db should fix the issue, but note that removing cache files will also remove all of your cached credentials.
Could not open available domains
[sss_cache] [sysdb_domain_cache_connect] (0x0010): DB version too old [0.22], expected [0.23] for domain implicit_files!
Higher version of database is expected!
In order to upgrade the database, you must run SSSD.
Removing cache files in /var/lib/sss/db should fix the issue, but note that removing cache files will also remove all of your cached credentials.
Could not open available domains

  Installing       : unbound-libs-1.17.1-1.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                           1/5
  Installing       : unbound-anchor-1.17.1-1.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                         2/5
  Running scriptlet: unbound-anchor-1.17.1-1.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                         2/5
Created symlink /etc/systemd/system/timers.target.wants/unbound-anchor.timer → /usr/lib/systemd/system/unbound-anchor.timer.

  Installing       : nss-tools-3.90.0-6.amzn2023.0.1.x86_64                                                                                                                                                                                                                                                              3/5
  Installing       : ldns-1.8.3-2.amzn2023.0.1.x86_64                                                                                                                                                                                                                                                                    4/5
  Installing       : libreswan-4.12-3.amzn2023.x86_64                                                                                                                                                                                                                                                                    5/5
  Running scriptlet: libreswan-4.12-3.amzn2023.x86_64                                                                                                                                                                                                                                                                    5/5
  Verifying        : ldns-1.8.3-2.amzn2023.0.1.x86_64                                                                                                                                                                                                                                                                    1/5
  Verifying        : libreswan-4.12-3.amzn2023.x86_64                                                                                                                                                                                                                                                                    2/5
  Verifying        : nss-tools-3.90.0-6.amzn2023.0.1.x86_64                                                                                                                                                                                                                                                              3/5
  Verifying        : unbound-anchor-1.17.1-1.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                         4/5
  Verifying        : unbound-libs-1.17.1-1.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                           5/5

Installed:
  ldns-1.8.3-2.amzn2023.0.1.x86_64                          libreswan-4.12-3.amzn2023.x86_64                          nss-tools-3.90.0-6.amzn2023.0.1.x86_64                          unbound-anchor-1.17.1-1.amzn2023.0.2.x86_64                          unbound-libs-1.17.1-1.amzn2023.0.2.x86_64

Complete!
[root@ip-172-16-0-30 ~]#
```

インストールされたバージョンを確認

```bash
root@ip-172-16-0-30 ~]# ipsec --version
Libreswan 4.12
[root@ip-172-16-0-30 ~]#
```

### Libreswanの設定

| Key         | Value                   | Description                  |
|-------------|-------------------------|------------------------------|
| left        | %defaultroute           | このホストのルーティング先                |
| leftid      | xxx.xxx.xxx.xxx         | このホストのPublic IP              |
| leftsubnet  | xxx.xxx.xxx.xxx/xx      | このホストのサブネット                  |
| right       | %any or xxx.xxx.xxx.xxx | 相手のPublic IP。%anyは相手が動的IPの場合 |
| rightid     | %any or xxx.xxx.xxx.xxx | 相手のPublic IP。%anyは相手が動的IPの場合 |
| rightsubnet | xxx.xxx.xxx.xxx/xx      | 相手のサブネット                     |
| type        | tunnel                  | 接続タイプ                        |
| auto        | start                   | 自動起動                         |
| authby      | secret                  | 認証方式                         |
| dpddelay    | 10                      | DPDの遅延時間                     |
| dpdtimeout  | 30                      | DPDのタイムアウト時間                 |
| dpdaction   | restart                 | DPDのアクション                    |
| ikelifetime | 24h                     | IKEの有効期限                     |
| salifetime  | 24h                     | SAの有効期限                      |
| ike         | aes128-sha1-modp2048    | IKEの暗号アルゴリズム                 |
| phase2alg   | aes128-sha1             | Phase2の暗号アルゴリズム              |

### VPC1 EC2

```text:
cat << EOF > /etc/ipsec.d/net1.conf
conn net1
    left=%defaultroute
    leftid=54.250.192.221
    leftsubnet=172.16.0.0/24
    right=54.95.174.76
    rightid=54.95.174.76
    rightsubnet=172.16.1.0/24
    type=tunnel
    auto=start
    authby=secret
    dpddelay=10
    dpdtimeout=30
    dpdaction=restart
    ikelifetime=24h
    salifetime=24h
    ike=aes128-sha1-modp2048
    phase2alg=aes128-sha1
EOF
```

#### VPC2 EC2

```text:
cat << EOF > /etc/ipsec.d/net1.conf
conn net1
    left=%defaultroute
    leftid=54.95.174.76
    leftsubnet=172.16.1.0/24
    right=%any
    rightid=%any
    rightsubnet=172.16.0.0/24
    type=tunnel
    auto=start
    authby=secret
    dpddelay=10
    dpdtimeout=30
    dpdaction=restart
    ikelifetime=24h
    salifetime=24h
    ike=aes128-sha1-modp2048
    phase2alg=aes128-sha1
EOF
```

### PSK(Pre-Shared Key)の設定

32byteの乱数を設定する

```text:
cat << EOF > /etc/ipsec.d/net1.secrets
%any : PSK "sRkkJ7sfczXi2BH1WzUnxRiJiLtNFPxO"
EOF
```

### 起動

```bash
systemctl stop ipsec
systemctl start ipsec
systemctl enable ipsec
systemctl status ipsec
ps -C pluto -o comm,args,pid,ppid
```

```bash
[root@ip-172-16-0-27 ~]# systemctl start ipsec
Job for ipsec.service failed because the control process exited with error code.
See "systemctl status ipsec.service" and "journalctl -xeu ipsec.service" for details.
[root@ip-172-16-0-27 ~]# systemctl stop ipsec
[root@ip-172-16-0-27 ~]# vi /etc/ipsec.d/net1.conf
[root@ip-172-16-0-27 ~]# systemctl stop ipsec
[root@ip-172-16-0-27 ~]# systemctl start ipsec
[root@ip-172-16-0-27 ~]# systemctl stop ipsec
[root@ip-172-16-0-27 ~]# vi /etc/ipsec.d/net1.conf
[root@ip-172-16-0-27 ~]# systemctl stop ipsec
[root@ip-172-16-0-27 ~]# systemctl start ipsec
[root@ip-172-16-0-27 ~]# systemctl enable ipsec
Created symlink /etc/systemd/system/multi-user.target.wants/ipsec.service → /usr/lib/systemd/system/ipsec.service.
[root@ip-172-16-0-27 ~]# systemctl status ipsec
● ipsec.service - Internet Key Exchange (IKE) Protocol Daemon for IPsec
     Loaded: loaded (/usr/lib/systemd/system/ipsec.service; enabled; preset: disabled)
     Active: active (running) since Sun 2024-04-14 16:29:51 UTC; 11s ago
       Docs: man:ipsec(8)
             man:pluto(8)
             man:ipsec.conf(5)
   Main PID: 28146 (pluto)
     Status: "Startup completed."
      Tasks: 2 (limit: 1114)
     Memory: 3.3M
        CPU: 330ms
     CGroup: /system.slice/ipsec.service
             └─28146 /usr/libexec/ipsec/pluto --leak-detective --config /etc/ipsec.conf --nofork

Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: adding UDP interface enX0 172.16.0.27:500
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: adding UDP interface enX0 172.16.0.27:4500
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: adding UDP interface lo 127.0.0.1:500
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: adding UDP interface lo 127.0.0.1:4500
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: adding UDP interface lo [::1]:500
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: adding UDP interface lo [::1]:4500
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: loading secrets from "/etc/ipsec.secrets"
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: loading secrets from "/etc/ipsec.d/net1.secrets"
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: initiating all conns with alias='net1'
Apr 14 16:29:51 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[28146]: no connection named "net1"
[root@ip-172-16-0-27 ~]# ps -C pluto -o comm,args,pid,ppid
COMMAND         COMMAND                         PID    PPID
pluto           /usr/libexec/ipsec/pluto --   28146       1
```

```bash
[root@ip-172-16-1-27 ~]# systemctl start ipsec
[root@ip-172-16-1-27 ~]# systemctl enable ipsec
Created symlink /etc/systemd/system/multi-user.target.wants/ipsec.service → /usr/lib/systemd/system/ipsec.service.
[root@ip-172-16-1-27 ~]# systemctl status ipsec
● ipsec.service - Internet Key Exchange (IKE) Protocol Daemon for IPsec
     Loaded: loaded (/usr/lib/systemd/system/ipsec.service; enabled; preset: disabled)
     Active: active (running) since Sun 2024-04-14 16:33:15 UTC; 13s ago
       Docs: man:ipsec(8)
             man:pluto(8)
             man:ipsec.conf(5)
   Main PID: 26573 (pluto)
     Status: "Startup completed."
      Tasks: 2 (limit: 1114)
     Memory: 10.5M
        CPU: 518ms
     CGroup: /system.slice/ipsec.service
             └─26573 /usr/libexec/ipsec/pluto --leak-detective --config /etc/ipsec.conf --nofork

Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: adding UDP interface enX0 172.16.1.27:500
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: adding UDP interface enX0 172.16.1.27:4500
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: adding UDP interface lo 127.0.0.1:500
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: adding UDP interface lo 127.0.0.1:4500
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: adding UDP interface lo [::1]:500
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: adding UDP interface lo [::1]:4500
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: loading secrets from "/etc/ipsec.secrets"
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: loading secrets from "/etc/ipsec.d/net1.secrets"
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: initiating all conns with alias='net1'
Apr 14 16:33:15 ip-172-16-1-27.ap-northeast-1.compute.internal pluto[26573]: no connection named "net1"
[root@ip-172-16-1-27 ~]# ps -C pluto -o comm,args,pid,ppid
COMMAND         COMMAND                         PID    PPID
pluto           /usr/libexec/ipsec/pluto --   26573       1
```

### トラブルシューティング

起動しない

```
ipsec barf
Apr 14 16:56:54 ip-172-16-0-27.ap-northeast-1.compute.internal libipsecconf[29640]: conn: "net1" warning IKEv2 liveness uses retransmit-timeout=, dpdtimeout= ignored
Apr 14 16:56:54 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[29638]: "net1": failed to add connection: IKE encryption algorithm 'aes128_cbc' is notrecognized
```

暗号モードのし指定が間違っていた

```
    ike=aes256-sha2_256
    phase2alg=aes256-sha2_256
```

```
    ike=aes128_cbc-hmac_sha1
    phase2alg=aes128_cbc-hmac_sha1
```

```bash
[root@ip-172-16-0-27 ~]# systemctl status ipsec
● ipsec.service - Internet Key Exchange (IKE) Protocol Daemon for IPsec
     Loaded: loaded (/usr/lib/systemd/system/ipsec.service; enabled; preset: disabled)
     Active: active (running) since Sun 2024-04-14 17:06:40 UTC; 4s ago
       Docs: man:ipsec(8)
             man:pluto(8)
             man:ipsec.conf(5)
    Process: 30273 ExecStartPre=/usr/libexec/ipsec/addconn --config /etc/ipsec.conf --checkconfig (code=exited, status=0/SUCCESS)
    Process: 30274 ExecStartPre=/usr/libexec/ipsec/_stackmanager start (code=exited, status=0/SUCCESS)
    Process: 30485 ExecStartPre=/usr/sbin/ipsec --checknss (code=exited, status=0/SUCCESS)
    Process: 30486 ExecStartPre=/usr/sbin/ipsec --checknflog (code=exited, status=0/SUCCESS)
   Main PID: 30497 (pluto)
     Status: "Startup completed."
      Tasks: 2 (limit: 1114)
     Memory: 3.3M
        CPU: 336ms
     CGroup: /system.slice/ipsec.service
             └─30497 /usr/libexec/ipsec/pluto --leak-detective --config /etc/ipsec.conf --nofork

Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: adding UDP interface enX0 172.16.0.27:500
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: adding UDP interface enX0 172.16.0.27:4500
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: adding UDP interface lo 127.0.0.1:500
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: adding UDP interface lo 127.0.0.1:4500
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: adding UDP interface lo [::1]:500
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: adding UDP interface lo [::1]:4500
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: loading secrets from "/etc/ipsec.secrets"
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: loading secrets from "/etc/ipsec.d/net1.secrets"
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: "net1": we cannot identify ourselves with either end of this connection.  172.>
Apr 14 17:06:40 ip-172-16-0-27.ap-northeast-1.compute.internal pluto[30497]: "net1": failed to initiate connection
```

## iptablesの設定

```bash
[root@ip-172-16-0-20 ~]# sudo dnf install iptables
Last metadata expiration check: 1:01:18 ago on Sun Apr 14 21:35:43 2024.
Dependencies resolved.
=============================================================================================================================================================================================================================================================================================================================
 Package                                                                             Architecture                                                        Version                                                                              Repository                                                                Size
=============================================================================================================================================================================================================================================================================================================================
Installing:
 iptables-nft                                                                        x86_64                                                              1.8.8-3.amzn2023.0.2                                                                 amazonlinux                                                              183 k
Installing dependencies:
 iptables-libs                                                                       x86_64                                                              1.8.8-3.amzn2023.0.2                                                                 amazonlinux                                                              401 k
 libnetfilter_conntrack                                                              x86_64                                                              1.0.8-2.amzn2023.0.2                                                                 amazonlinux                                                               58 k
 libnfnetlink                                                                        x86_64                                                              1.0.1-19.amzn2023.0.2                                                                amazonlinux                                                               30 k
 libnftnl                                                                            x86_64                                                              1.2.2-2.amzn2023.0.2                                                                 amazonlinux                                                               84 k

Transaction Summary
=============================================================================================================================================================================================================================================================================================================================
Install  5 Packages

Total download size: 755 k
Installed size: 2.8 M
Is this ok [y/N]: y
Downloading Packages:
(1/5): libnfnetlink-1.0.1-19.amzn2023.0.2.x86_64.rpm                                                                                                                                                                                                                                         377 kB/s |  30 kB     00:00
(2/5): iptables-libs-1.8.8-3.amzn2023.0.2.x86_64.rpm                                                                                                                                                                                                                                         4.3 MB/s | 401 kB     00:00
(3/5): iptables-nft-1.8.8-3.amzn2023.0.2.x86_64.rpm                                                                                                                                                                                                                                          1.6 MB/s | 183 kB     00:00
(4/5): libnetfilter_conntrack-1.0.8-2.amzn2023.0.2.x86_64.rpm                                                                                                                                                                                                                                2.8 MB/s |  58 kB     00:00
(5/5): libnftnl-1.2.2-2.amzn2023.0.2.x86_64.rpm                                                                                                                                                                                                                                              2.3 MB/s |  84 kB     00:00
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                                                                                                        3.6 MB/s | 755 kB     00:00
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                                                                                                                                                     1/1
  Installing       : libnftnl-1.2.2-2.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                                1/5
  Installing       : libnfnetlink-1.0.1-19.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                           2/5
  Installing       : libnetfilter_conntrack-1.0.8-2.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                  3/5
  Installing       : iptables-libs-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                           4/5
  Installing       : iptables-nft-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                            5/5
  Running scriptlet: iptables-nft-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                            5/5
  Verifying        : libnfnetlink-1.0.1-19.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                           1/5
  Verifying        : iptables-libs-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                           2/5
  Verifying        : iptables-nft-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                            3/5
  Verifying        : libnftnl-1.2.2-2.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                                4/5
  Verifying        : libnetfilter_conntrack-1.0.8-2.amzn2023.0.2.x86_64                                                                                                                                                                                                                                                  5/5
=============================================================================================================================================================================================================================================================================================================================
WARNING:
  A newer release of "Amazon Linux" is available.

  Available Versions:

  Version 2023.3.20240131:
    Run the following command to upgrade to 2023.3.20240131:

      dnf upgrade --releasever=2023.3.20240131

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.3.20240131.html

  Version 2023.3.20240205:
    Run the following command to upgrade to 2023.3.20240205:

      dnf upgrade --releasever=2023.3.20240205

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.3.20240205.html

  Version 2023.3.20240219:
    Run the following command to upgrade to 2023.3.20240219:

      dnf upgrade --releasever=2023.3.20240219

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.3.20240219.html

  Version 2023.3.20240304:
    Run the following command to upgrade to 2023.3.20240304:

      dnf upgrade --releasever=2023.3.20240304

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.3.20240304.html

  Version 2023.3.20240312:
    Run the following command to upgrade to 2023.3.20240312:

      dnf upgrade --releasever=2023.3.20240312

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.3.20240312.html

  Version 2023.4.20240319:
    Run the following command to upgrade to 2023.4.20240319:

      dnf upgrade --releasever=2023.4.20240319

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.4.20240319.html

  Version 2023.4.20240401:
    Run the following command to upgrade to 2023.4.20240401:

      dnf upgrade --releasever=2023.4.20240401

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.4.20240401.html

=============================================================================================================================================================================================================================================================================================================================

Installed:
  iptables-libs-1.8.8-3.amzn2023.0.2.x86_64                     iptables-nft-1.8.8-3.amzn2023.0.2.x86_64                     libnetfilter_conntrack-1.0.8-2.amzn2023.0.2.x86_64                     libnfnetlink-1.0.1-19.amzn2023.0.2.x86_64                     libnftnl-1.2.2-2.amzn2023.0.2.x86_64

Complete!
```

```bash
ptables -t nat -A POSTROUTING -s 172.168.0.0/24 -o etX0 -j MASQUERADE
```

## 接続確認

| From         | Host                                           | VPC1-Private | VPC1-Public | VPC2-Public | VPC2-Private |
|--------------|------------------------------------------------|--------------|-------------|-------------|--------------|
| VPC1-Private | ip-172-16-0-43.ap-northeast-1.compute.internal | ◯            | ◯           | ◯(NAT)      | ◯(NAT)       |
| VPC1-Public  | ip-172-16-0-14.ap-northeast-1.compute.internal | ◯            | ◯           | ◯           | ◯            |
| VPC2-Public  | ip-172-16-1-12.ap-northeast-1.compute.internal | ◯            | ◯           | ◯           | ◯            |
| VPC2-Private | ip-172-16-1-45.ap-northeast-1.compute.internal | -            | -           | ◯           | ◯            |

VPC1にだけNAT Gatewayを挟んだのでVPC1-PrivateのVPC2へのアクセスがNAT(172.16.0.20)される。

## 参考

- [動的パブリックIPが割当てられたルータとAmazon VPCのVPN接続](https://qiita.com/aquaviter/items/dd55fa6429755e07ac20)
- [【Linux】OSSでVPNを構築する](https://qiita.com/dan-go/items/3ee70e9ea195bbb9e3c5)

- [Libreswan ipsec.conf.5](https://libreswan.org/man/ipsec.conf.5.html)
- [Internet Key Exchange (IKEv2) Protocol](https://www.ietf.org/rfc/rfc4306.txt)
- [Microsoft Azure configuration](https://libreswan.org/wiki/Microsoft_Azure_configuration)
- [IPsec IKE and ESP elements](https://docs.oracle.com/cd/E57516_01/docs.70/DSRAdminGuide/references/r_dsr_admin_ipsec_variables.html)
- [IPsec 相互接続の手引き](https://www.rtpro.yamaha.co.jp/RT/docs/ipsec/interop.html)
- [Libreswan](https://docs.oracle.com/ja-jp/iaas/Content/Network/Reference/libreswanCPE.htm)
- [IPSec のアルゴリズムとプロトコルについて](https://www.watchguard.com/help/docs/fireware/12/ja-JP/Content/ja-JP/mvpn/general/ipsec_algorithms_protocols_c.html)

- [Libreswan Github](https://github.com/libreswan/libreswan)
- [Libreswan Download](https://download.libreswan.org/old/)
- [Libreswan Binary](https://nl.libreswan.org/binaries/rhel/7/x86_64/)

[Oracle Cloud：Oracle Cloud と AWS を IPSec VPN(Libreswan)でマルチクラウド接続してみてみた](https://qiita.com/shirok/items/a0848df3d3d67fccd4f9)

## Libreswan3.18に落としてインストール

### Network構成

#### VPC1

| Type       | LogicalId                    | CIDR            | Remarks |
|------------|------------------------------|-----------------|---------|
| VPC        | Vpc1                         | 172.16.0.0/24   |         |
| Subnet     | Vpc1PrivateSubnet            | 172.16.0.0/28   |         |
| Subnet     | Vpc1PublicSubnet             | 172.16.0.16/28  |         |
| NatGateway | Vpc1PublicSubnetNatGateway   | 172.16.0.20/32  |         |
| EIP        | Vpc1PublicSubnetEIP          | 13.115.82.28/32 |         |
| EC2        | Vpc1PublicSubnetEC2Instance  |                 |         |
| EC2        | Vpc1PrivateSubnetEC2Instance |                 |         |

#### VPC2

| Type       | LogicalId                    | CIDR             | Remarks |
|------------|------------------------------|------------------|---------|
| VPC        | Vpc2                         | 172.16.1.0/24    |         |
| Subnet     | Vpc2PrivateSubnet            | 172.16.1.0/28    |         |
| Subnet     | Vpc2PublicSubnet             | 172.16.1.16/28   |         |
| NatGateway | Vpc2PublicSubnetNatGateway   | 172.16.1.20/32   |         |
| EIP        | Vpc2PublicSubnetEIP          | 54.249.119.97/32 |         |
| EC2        | Vpc2PublicSubnetEC2Instance  |                  |         |
| EC2        | Vpc2PrivateSubnetEC2Instance |                  |         |

### AMI

```bash
yuzuru[Andy]% aws ec2 describe-images --image-ids ami-05a03e6058638183d
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2024-01-20T00:07:15.000Z",
            "ImageId": "ami-05a03e6058638183d",
            "ImageLocation": "amazon/al2023-ami-2023.3.20240122.0-kernel-6.1-x86_64",
            "ImageType": "machine",
            "Public": true,
            "OwnerId": "137112412989",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances",
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/xvda",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "Iops": 3000,
                        "SnapshotId": "snap-0f56866b682ab1e50",
                        "VolumeSize": 8,
                        "VolumeType": "gp3",
                        "Throughput": 125,
                        "Encrypted": false
                    }
                }
            ],
            "Description": "Amazon Linux 2023 AMI 2023.3.20240122.0 x86_64 HVM kernel-6.1",
            "EnaSupport": true,
            "Hypervisor": "xen",
            "ImageOwnerAlias": "amazon",
            "Name": "al2023-ami-2023.3.20240122.0-kernel-6.1-x86_64",
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "VirtualizationType": "hvm",
            "BootMode": "uefi-preferred",
            "DeprecationTime": "2024-04-19T00:07:00.000Z",
            "ImdsSupport": "v2.0"
        }
    ]
}
```

```bash
yuzuru[Andy]% aws ec2 describe-images --image-ids ami-005edfa7e37fa41a4
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2024-04-19T17:51:53.000Z",
            "ImageId": "ami-005edfa7e37fa41a4",
            "ImageLocation": "230467396533/centos7-libreswan-3.18-1",
            "ImageType": "machine",
            "Public": false,
            "OwnerId": "230467396533",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances",
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/sda1",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "Iops": 3000,
                        "SnapshotId": "snap-0a830c467b13fa90d",
                        "VolumeSize": 60,
                        "VolumeType": "gp3",
                        "Throughput": 125,
                        "Encrypted": false
                    }
                }
            ],
            "EnaSupport": true,
            "Hypervisor": "xen",
            "Name": "centos7-libreswan-3.18-1",
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "ebs",
            "VirtualizationType": "hvm",
            "SourceInstanceId": "i-06c9953be9f1332c2"
        }
    ]
}
```

```bash
yuzuru[Andy]% aws ec2 describe-images --image-ids ami-0fd48c6031f8700df
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2022-08-26T03:04:41.000Z",
            "ImageId": "ami-0fd48c6031f8700df",
            "ImageLocation": "aws-marketplace/CentOS-7-2111-20220825_1.x86_64-d9a3032a-921c-4c6d-b150-bde168105e42",
            "ImageType": "machine",
            "Public": true,
            "OwnerId": "679593333241",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances",
            "ProductCodes": [
                {
                    "ProductCodeId": "cvugziknvmxgqna9noibqnnsy",
                    "ProductCodeType": "marketplace"
                }
            ],
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/sda1",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "SnapshotId": "snap-079ba7632cbb4bde6",
                        "VolumeSize": 10,
                        "VolumeType": "gp2",
                        "Encrypted": false
                    }
                }
            ],
            "Description": "CentOS-7-2111-20220825_1.x86_64",
            "EnaSupport": true,
            "Hypervisor": "xen",
            "ImageOwnerAlias": "aws-marketplace",
            "Name": "CentOS-7-2111-20220825_1.x86_64-d9a3032a-921c-4c6d-b150-bde168105e42",
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "VirtualizationType": "hvm",
            "DeprecationTime": "2024-08-26T03:04:41.000Z"
        }
    ]
}
```

```text:/etc/sysctl.d/99-sysctl.conf
cat << EOF >> /etc/sysctl.d/99-sysctl.conf
net.ipv4.ip_forward=1

net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.default.arp_ignore=1
net.ipv4.conf.eth0.arp_ignore=1

net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.eth0.send_redirects=0
net.ipv4.conf.lo.send_redirects=0

net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.eth0.accept_redirects=0
net.ipv4.conf.lo.accept_redirects=0

net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.eth0.rp_filter=0
net.ipv4.conf.lo.rp_filter=0
EOF
```

### VPC1の設定

```bash
cat << EOF > /etc/ipsec.d/net1.conf
config setup
    interfaces="eth0"
    klipsdebug=none
    plutodebug=all
    plutostderrlog=/var/log/ipseclog
    nat_traversal=yes

conn net1
    type=tunnel
    ikelifetime=28800s
    salifetime=3600s
    authby=secret
    auth=esp
    ike=aes128-sha1;modp1024
    phase2alg=aes-128-sha1;modp1024
    keyexchange=ike
    aggrmode=yes
    pfs=no
    forceencaps=yes
    auto=start
    left=%defaultroute
    leftid=13.115.82.28
    leftsubnet=172.16.0.0/28
    right=54.249.119.97
    rightid=54.249.119.97
    rightsubnet=172.16.1.0/28
    dpdaction=restart_by_peer
    dpdtimeout=10
    dpddelay=10
EOF
```

### VPC2の設定

```bash
cat << EOF > /etc/ipsec.d/net1.conf
config setup
    interfaces="eth0"
    klipsdebug=none
    plutodebug=all
    plutostderrlog=/var/log/ipseclog
    nat_traversal=yes

conn net1
    type=tunnel
    ikelifetime=28800s
    salifetime=3600s
    authby=secret
    auth=esp
    ike=aes128-sha1;modp1024
    phase2alg=aes-128-sha1;modp1024
    keyexchange=ike
    aggrmode=yes
    pfs=no
    forceencaps=yes
    auto=start
    left=%defaultroute
    leftid=54.249.119.97
    leftsubnet=172.16.1.0/28
    right=%any
    rightid=%any
    rightsubnet=172.16.0.0/28
    dpdaction=restart_by_peer
    dpdtimeout=10
    dpddelay=10
EOF
```

### VPC2の起動

```bash
[root@ip-172-16-1-8 ipsec.d]# systemctl stop ipsec
[root@ip-172-16-1-8 ipsec.d]# systemctl start ipsec
[root@ip-172-16-1-8 ipsec.d]# systemctl status ipsec
● ipsec.service - Internet Key Exchange (IKE) Protocol Daemon for IPsec
   Loaded: loaded (/usr/lib/systemd/system/ipsec.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-05-03 14:34:51 UTC; 2s ago
  Process: 2843 ExecStopPost=/usr/sbin/ipsec --stopnflog (code=exited, status=0/SUCCESS)
  Process: 2841 ExecStopPost=/sbin/ip xfrm state flush (code=exited, status=0/SUCCESS)
  Process: 2839 ExecStopPost=/sbin/ip xfrm policy flush (code=exited, status=0/SUCCESS)
  Process: 2828 ExecStop=/usr/libexec/ipsec/whack --shutdown (code=exited, status=0/SUCCESS)
  Process: 3114 ExecStartPre=/usr/sbin/ipsec --checknflog (code=exited, status=0/SUCCESS)
  Process: 3112 ExecStartPre=/usr/sbin/ipsec --checknss (code=exited, status=0/SUCCESS)
  Process: 2862 ExecStartPre=/usr/libexec/ipsec/_stackmanager start (code=exited, status=0/SUCCESS)
  Process: 2861 ExecStartPre=/usr/libexec/ipsec/addconn --config /etc/ipsec.conf --checkconfig (code=exited, status=0/SUCCESS)
 Main PID: 3125 (pluto)
   Status: "Startup completed."
    Tasks: 2
   Memory: 2.0M
   CGroup: /system.slice/ipsec.service
           └─3125 /usr/libexec/ipsec/pluto --leak-detective --config /etc/ipsec.conf --nofork

May 03 14:34:52 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: adding interface lo/lo ::1:500
May 03 14:34:52 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: | setup callback for interface lo:500 fd 21
May 03 14:34:52 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: | setup callback for interface lo:4500 fd 20
May 03 14:34:52 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: | setup callback for interface lo:500 fd 19
May 03 14:34:52 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: | setup callback for interface eth0:4500 fd 18
May 03 14:34:52 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: | setup callback for interface eth0:500 fd 17
May 03 14:34:52 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: loading secrets from "/etc/ipsec.secrets"
May 03 14:34:52 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: loading secrets from "/etc/ipsec.d/net1.secrets"
May 03 14:34:53 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: "net1": cannot initiate connection without knowing peer IP address (kind=CK_TEMPLATE)
May 03 14:34:53 ip-172-16-1-8.ap-northeast-1.compute.internal pluto[3125]: reapchild failed with errno=10 No child processes
[root@ip-172-16-1-8 ipsec.d]#
```

```bash
[root@ip-172-16-1-8 ipsec.d]# ipsec status
000 using kernel interface: netkey
000 interface lo/lo ::1@500
000 interface lo/lo 127.0.0.1@4500
000 interface lo/lo 127.0.0.1@500
000 interface eth0/eth0 172.16.1.8@4500
000 interface eth0/eth0 172.16.1.8@500
000
000
000 fips mode=disabled;
000 SElinux=enabled
000
000 config setup options:
000
000 configdir=/etc, configfile=/etc/ipsec.conf, secrets=/etc/ipsec.secrets, ipsecdir=/etc/ipsec.d, dumpdir=/var/run/pluto/, statsbin=unset
000 sbindir=/usr/sbin, libexecdir=/usr/libexec/ipsec
000 pluto_version=3.18, pluto_vendorid=OE-Libreswan-3.18
000 nhelpers=-1, uniqueids=yes, perpeerlog=no, shuntlifetime=900s, xfrmlifetime=300s
000 ddos-cookies-threshold=50000, ddos-max-halfopen=25000, ddos-mode=auto
000 ikeport=500, strictcrlpolicy=no, crlcheckinterval=0, listen=<any>, nflog-all=0
000 secctx-attr-type=32001
000 myid = (none)
000 debug none
000
000 nat-traversal=yes, keep-alive=20, nat-ikeport=4500
000 virtual-private (%priv):
000 - allowed subnets: 10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12, 25.0.0.0/8, 100.64.0.0/10, fd00::/8, fe80::/10
000
000 ESP algorithms supported:
000
000 algorithm ESP encrypt: id=3, name=ESP_3DES, ivlen=8, keysizemin=192, keysizemax=192
000 algorithm ESP encrypt: id=6, name=ESP_CAST, ivlen=8, keysizemin=128, keysizemax=128
000 algorithm ESP encrypt: id=11, name=ESP_NULL, ivlen=0, keysizemin=0, keysizemax=0
000 algorithm ESP encrypt: id=12, name=ESP_AES, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=13, name=ESP_AES_CTR, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=14, name=ESP_AES_CCM_A, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=15, name=ESP_AES_CCM_B, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=16, name=ESP_AES_CCM_C, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=18, name=ESP_AES_GCM_A, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=19, name=ESP_AES_GCM_B, ivlen=12, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=20, name=ESP_AES_GCM_C, ivlen=16, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=22, name=ESP_CAMELLIA, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=252, name=ESP_SERPENT, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=253, name=ESP_TWOFISH, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm AH/ESP auth: id=1, name=AUTH_ALGORITHM_HMAC_MD5, keysizemin=128, keysizemax=128
000 algorithm AH/ESP auth: id=2, name=AUTH_ALGORITHM_HMAC_SHA1, keysizemin=160, keysizemax=160
000 algorithm AH/ESP auth: id=5, name=AUTH_ALGORITHM_HMAC_SHA2_256, keysizemin=256, keysizemax=256
000 algorithm AH/ESP auth: id=6, name=AUTH_ALGORITHM_HMAC_SHA2_384, keysizemin=384, keysizemax=384
000 algorithm AH/ESP auth: id=7, name=AUTH_ALGORITHM_HMAC_SHA2_512, keysizemin=512, keysizemax=512
000 algorithm AH/ESP auth: id=8, name=AUTH_ALGORITHM_HMAC_RIPEMD, keysizemin=160, keysizemax=160
000 algorithm AH/ESP auth: id=9, name=AUTH_ALGORITHM_AES_XCBC, keysizemin=128, keysizemax=128
000 algorithm AH/ESP auth: id=251, name=AUTH_ALGORITHM_NULL_KAME, keysizemin=0, keysizemax=0
000
000 IKE algorithms supported:
000
000 algorithm IKE encrypt: v1id=0, v1name=0??, v2id=16, v2name=AES_CCM_C, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=0, v1name=0??, v2id=15, v2name=AES_CCM_B, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=0, v1name=0??, v2id=14, v2name=AES_CCM_A, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=5, v1name=OAKLEY_3DES_CBC, v2id=3, v2name=3DES, blocksize=8, keydeflen=192
000 algorithm IKE encrypt: v1id=24, v1name=OAKLEY_CAMELLIA_CTR, v2id=24, v2name=CAMELLIA_CTR, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=8, v1name=OAKLEY_CAMELLIA_CBC, v2id=23, v2name=CAMELLIA_CBC, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=20, v1name=OAKLEY_AES_GCM_C, v2id=20, v2name=AES_GCM_C, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=19, v1name=OAKLEY_AES_GCM_B, v2id=19, v2name=AES_GCM_B, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=18, v1name=OAKLEY_AES_GCM_A, v2id=18, v2name=AES_GCM_A, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=13, v1name=OAKLEY_AES_CTR, v2id=13, v2name=AES_CTR, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=7, v1name=OAKLEY_AES_CBC, v2id=12, v2name=AES_CBC, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=65004, v1name=OAKLEY_SERPENT_CBC, v2id=65004, v2name=SERPENT_CBC, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=65005, v1name=OAKLEY_TWOFISH_CBC, v2id=65005, v2name=TWOFISH_CBC, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=65289, v1name=OAKLEY_TWOFISH_CBC_SSH, v2id=65289, v2name=TWOFISH_CBC_SSH, blocksize=16, keydeflen=128
000 algorithm IKE hash: id=1, name=OAKLEY_MD5, hashlen=16
000 algorithm IKE hash: id=2, name=OAKLEY_SHA1, hashlen=20
000 algorithm IKE hash: id=4, name=OAKLEY_SHA2_256, hashlen=32
000 algorithm IKE hash: id=5, name=OAKLEY_SHA2_384, hashlen=48
000 algorithm IKE hash: id=6, name=OAKLEY_SHA2_512, hashlen=64
000 algorithm IKE hash: id=9, name=DISABLED-OAKLEY_AES_XCBC, hashlen=16
000 algorithm IKE dh group: id=2, name=OAKLEY_GROUP_MODP1024, bits=1024
000 algorithm IKE dh group: id=5, name=OAKLEY_GROUP_MODP1536, bits=1536
000 algorithm IKE dh group: id=14, name=OAKLEY_GROUP_MODP2048, bits=2048
000 algorithm IKE dh group: id=15, name=OAKLEY_GROUP_MODP3072, bits=3072
000 algorithm IKE dh group: id=16, name=OAKLEY_GROUP_MODP4096, bits=4096
000 algorithm IKE dh group: id=17, name=OAKLEY_GROUP_MODP6144, bits=6144
000 algorithm IKE dh group: id=18, name=OAKLEY_GROUP_MODP8192, bits=8192
000 algorithm IKE dh group: id=22, name=OAKLEY_GROUP_DH22, bits=1024
000 algorithm IKE dh group: id=23, name=OAKLEY_GROUP_DH23, bits=2048
000 algorithm IKE dh group: id=24, name=OAKLEY_GROUP_DH24, bits=2048
000
000 stats db_ops: {curr_cnt, total_cnt, maxsz} :context={0,0,0} trans={0,0,0} attrs={0,0,0}
000
000 Connection list:
000
000 "net1": 172.16.1.0/28===172.16.1.8[54.249.119.97]---172.16.1.1...%any===172.16.0.0/28; prospective erouted; eroute owner: #0
000 "net1":     oriented; my_ip=unset; their_ip=unset
000 "net1":   xauth us:none, xauth them:none,  my_username=[any]; their_username=[any]
000 "net1":   modecfg info: us:none, them:none, modecfg policy:push, dns1:unset, dns2:unset, domain:unset, banner:unset, cat:unset;
000 "net1":   labeled_ipsec:no;
000 "net1":   policy_label:unset;
000 "net1":   ike_life: 28800s; ipsec_life: 3600s; replay_window: 32; rekey_margin: 540s; rekey_fuzz: 100%; keyingtries: 0;
000 "net1":   retransmit-interval: 500ms; retransmit-timeout: 60s;
000 "net1":   sha2-truncbug:no; initial-contact:no; cisco-unity:no; fake-strongswan:no; send-vendorid:no; send-no-esp-tfc:no;
000 "net1":   policy: PSK+ENCRYPT+TUNNEL+AGGRESSIVE+IKEV1_ALLOW+IKEV2_ALLOW+SAREF_TRACK+IKE_FRAG_ALLOW+ESN_NO;
000 "net1":   conn_prio: 28,28; interface: eth0; metric: 0; mtu: unset; sa_prio:auto; sa_tfc:none;
000 "net1":   nflog-group: unset; mark: unset; vti-iface:unset; vti-routing:no; vti-shared:no;
000 "net1":   dpd: action:restart; delay:10; timeout:10; nat-t: force_encaps:yes; nat_keepalive:yes; ikev1_natt:both
000 "net1":   newest ISAKMP SA: #0; newest IPsec SA: #0;
000 "net1":   IKE algorithms wanted: AES_CBC(7)_128-SHA1(2)-MODP1024(2)
000 "net1":   IKE algorithms found:  AES_CBC(7)_128-SHA1(2)-MODP1024(2)
000 "net1":   ESP algorithms wanted: AES(12)_128-SHA1(2); pfsgroup=MODP1024(2)
000 "net1":   ESP algorithms loaded: AES(12)_128-SHA1(2)
000 "v6neighbor-hole-in": ::/0===::1<::1>:58/34560...%any:58/34816===::/0; prospective erouted; eroute owner: #0
000 "v6neighbor-hole-in":     oriented; my_ip=unset; their_ip=unset
000 "v6neighbor-hole-in":   xauth us:none, xauth them:none,  my_username=[any]; their_username=[any]
000 "v6neighbor-hole-in":   modecfg info: us:none, them:none, modecfg policy:push, dns1:unset, dns2:unset, domain:unset, banner:unset, cat:unset;
000 "v6neighbor-hole-in":   labeled_ipsec:no;
000 "v6neighbor-hole-in":   policy_label:unset;
000 "v6neighbor-hole-in":   ike_life: 0s; ipsec_life: 0s; replay_window: 0; rekey_margin: 0s; rekey_fuzz: 0%; keyingtries: 0;
000 "v6neighbor-hole-in":   retransmit-interval: 0ms; retransmit-timeout: 0s;
000 "v6neighbor-hole-in":   sha2-truncbug:no; initial-contact:no; cisco-unity:no; fake-strongswan:no; send-vendorid:no; send-no-esp-tfc:no;
000 "v6neighbor-hole-in":   policy: PFS+IKEV1_ALLOW+IKEV2_ALLOW+SAREF_TRACK+IKE_FRAG_ALLOW+ESN_NO+PASS+NEVER_NEGOTIATE;
000 "v6neighbor-hole-in":   conn_prio: 0,0; interface: lo; metric: 0; mtu: unset; sa_prio:1; sa_tfc:none;
000 "v6neighbor-hole-in":   nflog-group: unset; mark: unset; vti-iface:unset; vti-routing:no; vti-shared:no;
000 "v6neighbor-hole-in":   newest ISAKMP SA: #0; newest IPsec SA: #0;
000 "v6neighbor-hole-out": ::/0===::1<::1>:58/34816...%any:58/34560===::/0; prospective erouted; eroute owner: #0
000 "v6neighbor-hole-out":     oriented; my_ip=unset; their_ip=unset
000 "v6neighbor-hole-out":   xauth us:none, xauth them:none,  my_username=[any]; their_username=[any]
000 "v6neighbor-hole-out":   modecfg info: us:none, them:none, modecfg policy:push, dns1:unset, dns2:unset, domain:unset, banner:unset, cat:unset;
000 "v6neighbor-hole-out":   labeled_ipsec:no;
000 "v6neighbor-hole-out":   policy_label:unset;
000 "v6neighbor-hole-out":   ike_life: 0s; ipsec_life: 0s; replay_window: 0; rekey_margin: 0s; rekey_fuzz: 0%; keyingtries: 0;
000 "v6neighbor-hole-out":   retransmit-interval: 0ms; retransmit-timeout: 0s;
000 "v6neighbor-hole-out":   sha2-truncbug:no; initial-contact:no; cisco-unity:no; fake-strongswan:no; send-vendorid:no; send-no-esp-tfc:no;
000 "v6neighbor-hole-out":   policy: PFS+IKEV1_ALLOW+IKEV2_ALLOW+SAREF_TRACK+IKE_FRAG_ALLOW+ESN_NO+PASS+NEVER_NEGOTIATE;
000 "v6neighbor-hole-out":   conn_prio: 0,0; interface: lo; metric: 0; mtu: unset; sa_prio:1; sa_tfc:none;
000 "v6neighbor-hole-out":   nflog-group: unset; mark: unset; vti-iface:unset; vti-routing:no; vti-shared:no;
000 "v6neighbor-hole-out":   newest ISAKMP SA: #0; newest IPsec SA: #0;
000
000 Total IPsec connections: loaded 3, active 0
000
000 State Information: DDoS cookies not required, Accepting new IKE connections
000 IKE SAs: total(0), half-open(0), open(0), authenticated(0), anonymous(0)
000 IPsec SAs: total(0), authenticated(0), anonymous(0)
000
000 Bare Shunt list:
000
[root@ip-172-16-1-8 ipsec.d]#
```

### VPC1の起動

```bash
[root@ip-172-16-0-9 ipsec.d]# systemctl stop ipsec
[root@ip-172-16-0-9 ipsec.d]# systemctl start ipsec
[root@ip-172-16-0-9 ipsec.d]# systemctl status ipsec
● ipsec.service - Internet Key Exchange (IKE) Protocol Daemon for IPsec
   Loaded: loaded (/usr/lib/systemd/system/ipsec.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-05-03 14:35:34 UTC; 2s ago
  Process: 2832 ExecStopPost=/usr/sbin/ipsec --stopnflog (code=exited, status=0/SUCCESS)
  Process: 2830 ExecStopPost=/sbin/ip xfrm state flush (code=exited, status=0/SUCCESS)
  Process: 2828 ExecStopPost=/sbin/ip xfrm policy flush (code=exited, status=0/SUCCESS)
  Process: 2818 ExecStop=/usr/libexec/ipsec/whack --shutdown (code=exited, status=0/SUCCESS)
  Process: 3104 ExecStartPre=/usr/sbin/ipsec --checknflog (code=exited, status=0/SUCCESS)
  Process: 3102 ExecStartPre=/usr/sbin/ipsec --checknss (code=exited, status=0/SUCCESS)
  Process: 2852 ExecStartPre=/usr/libexec/ipsec/_stackmanager start (code=exited, status=0/SUCCESS)
  Process: 2851 ExecStartPre=/usr/libexec/ipsec/addconn --config /etc/ipsec.conf --checkconfig (code=exited, status=0/SUCCESS)
 Main PID: 3115 (pluto)
   Status: "Startup completed."
    Tasks: 2
   Memory: 2.2M
   CGroup: /system.slice/ipsec.service
           └─3115 /usr/libexec/ipsec/pluto --leak-detective --config /etc/ipsec.conf --nofork

May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: loading secrets from "/etc/ipsec.d/net1.secrets"
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: "net1": IKEv1 Aggressive Mode with PSK is vulnerable to dictionary attacks and is cracked on large scale by TLA's
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: "net1" #1: initiating Aggressive Mode
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: reapchild failed with errno=10 No child processes
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: "net1" #1: Aggressive mode peer ID is ID_IPV4_ADDR: '54.249.119.97'
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: "net1" #1: transition from state STATE_AGGR_I1 to state STATE_AGGR_I2
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: "net1" #1: STATE_AGGR_I2: sent AI2, ISAKMP SA established {auth=PRESHARED_KEY cipher=aes_128 integ=sha group=MODP1024}
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: "net1" #2: initiating Quick Mode PSK+ENCRYPT+TUNNEL+UP+AGGRESSIVE+IKEV1_ALLOW+IKEV2_ALLOW+SAREF_TRACK+IKE_FRAG_ALLOW+ESN_NO {using isakmp#1 msgid:57f15ab5 proposal=AES(12)_128-SHA1(2) pfsgroup=no-pfs}
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: "net1" #2: transition from state STATE_QUICK_I1 to state STATE_QUICK_I2
May 03 14:35:35 ip-172-16-0-9.ap-northeast-1.compute.internal pluto[3115]: "net1" #2: STATE_QUICK_I2: sent QI2, IPsec SA established tunnel mode {ESP/NAT=>0x132609f1 <0xc3c2929e xfrm=AES_128-HMAC_SHA1 NATOA=none NATD=54.249.119.97:4500 DPD=active}
Hint: Some lines were ellipsized, use -l to show in full.
[root@ip-172-16-0-9 ipsec.d]#
```

```bash
[root@ip-172-16-0-9 ipsec.d]# ipsec status
000 using kernel interface: netkey
000 interface lo/lo ::1@500
000 interface lo/lo 127.0.0.1@4500
000 interface lo/lo 127.0.0.1@500
000 interface eth0/eth0 172.16.0.9@4500
000 interface eth0/eth0 172.16.0.9@500
000
000
000 fips mode=disabled;
000 SElinux=enabled
000
000 config setup options:
000
000 configdir=/etc, configfile=/etc/ipsec.conf, secrets=/etc/ipsec.secrets, ipsecdir=/etc/ipsec.d, dumpdir=/var/run/pluto/, statsbin=unset
000 sbindir=/usr/sbin, libexecdir=/usr/libexec/ipsec
000 pluto_version=3.18, pluto_vendorid=OE-Libreswan-3.18
000 nhelpers=-1, uniqueids=yes, perpeerlog=no, shuntlifetime=900s, xfrmlifetime=300s
000 ddos-cookies-threshold=50000, ddos-max-halfopen=25000, ddos-mode=auto
000 ikeport=500, strictcrlpolicy=no, crlcheckinterval=0, listen=<any>, nflog-all=0
000 secctx-attr-type=32001
000 myid = (none)
000 debug none
000
000 nat-traversal=yes, keep-alive=20, nat-ikeport=4500
000 virtual-private (%priv):
000 - allowed subnets: 10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12, 25.0.0.0/8, 100.64.0.0/10, fd00::/8, fe80::/10
000
000 ESP algorithms supported:
000
000 algorithm ESP encrypt: id=3, name=ESP_3DES, ivlen=8, keysizemin=192, keysizemax=192
000 algorithm ESP encrypt: id=6, name=ESP_CAST, ivlen=8, keysizemin=128, keysizemax=128
000 algorithm ESP encrypt: id=11, name=ESP_NULL, ivlen=0, keysizemin=0, keysizemax=0
000 algorithm ESP encrypt: id=12, name=ESP_AES, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=13, name=ESP_AES_CTR, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=14, name=ESP_AES_CCM_A, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=15, name=ESP_AES_CCM_B, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=16, name=ESP_AES_CCM_C, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=18, name=ESP_AES_GCM_A, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=19, name=ESP_AES_GCM_B, ivlen=12, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=20, name=ESP_AES_GCM_C, ivlen=16, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=22, name=ESP_CAMELLIA, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=252, name=ESP_SERPENT, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm ESP encrypt: id=253, name=ESP_TWOFISH, ivlen=8, keysizemin=128, keysizemax=256
000 algorithm AH/ESP auth: id=1, name=AUTH_ALGORITHM_HMAC_MD5, keysizemin=128, keysizemax=128
000 algorithm AH/ESP auth: id=2, name=AUTH_ALGORITHM_HMAC_SHA1, keysizemin=160, keysizemax=160
000 algorithm AH/ESP auth: id=5, name=AUTH_ALGORITHM_HMAC_SHA2_256, keysizemin=256, keysizemax=256
000 algorithm AH/ESP auth: id=6, name=AUTH_ALGORITHM_HMAC_SHA2_384, keysizemin=384, keysizemax=384
000 algorithm AH/ESP auth: id=7, name=AUTH_ALGORITHM_HMAC_SHA2_512, keysizemin=512, keysizemax=512
000 algorithm AH/ESP auth: id=8, name=AUTH_ALGORITHM_HMAC_RIPEMD, keysizemin=160, keysizemax=160
000 algorithm AH/ESP auth: id=9, name=AUTH_ALGORITHM_AES_XCBC, keysizemin=128, keysizemax=128
000 algorithm AH/ESP auth: id=251, name=AUTH_ALGORITHM_NULL_KAME, keysizemin=0, keysizemax=0
000
000 IKE algorithms supported:
000
000 algorithm IKE encrypt: v1id=0, v1name=0??, v2id=16, v2name=AES_CCM_C, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=0, v1name=0??, v2id=15, v2name=AES_CCM_B, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=0, v1name=0??, v2id=14, v2name=AES_CCM_A, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=5, v1name=OAKLEY_3DES_CBC, v2id=3, v2name=3DES, blocksize=8, keydeflen=192
000 algorithm IKE encrypt: v1id=24, v1name=OAKLEY_CAMELLIA_CTR, v2id=24, v2name=CAMELLIA_CTR, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=8, v1name=OAKLEY_CAMELLIA_CBC, v2id=23, v2name=CAMELLIA_CBC, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=20, v1name=OAKLEY_AES_GCM_C, v2id=20, v2name=AES_GCM_C, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=19, v1name=OAKLEY_AES_GCM_B, v2id=19, v2name=AES_GCM_B, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=18, v1name=OAKLEY_AES_GCM_A, v2id=18, v2name=AES_GCM_A, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=13, v1name=OAKLEY_AES_CTR, v2id=13, v2name=AES_CTR, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=7, v1name=OAKLEY_AES_CBC, v2id=12, v2name=AES_CBC, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=65004, v1name=OAKLEY_SERPENT_CBC, v2id=65004, v2name=SERPENT_CBC, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=65005, v1name=OAKLEY_TWOFISH_CBC, v2id=65005, v2name=TWOFISH_CBC, blocksize=16, keydeflen=128
000 algorithm IKE encrypt: v1id=65289, v1name=OAKLEY_TWOFISH_CBC_SSH, v2id=65289, v2name=TWOFISH_CBC_SSH, blocksize=16, keydeflen=128
000 algorithm IKE hash: id=1, name=OAKLEY_MD5, hashlen=16
000 algorithm IKE hash: id=2, name=OAKLEY_SHA1, hashlen=20
000 algorithm IKE hash: id=4, name=OAKLEY_SHA2_256, hashlen=32
000 algorithm IKE hash: id=5, name=OAKLEY_SHA2_384, hashlen=48
000 algorithm IKE hash: id=6, name=OAKLEY_SHA2_512, hashlen=64
000 algorithm IKE hash: id=9, name=DISABLED-OAKLEY_AES_XCBC, hashlen=16
000 algorithm IKE dh group: id=2, name=OAKLEY_GROUP_MODP1024, bits=1024
000 algorithm IKE dh group: id=5, name=OAKLEY_GROUP_MODP1536, bits=1536
000 algorithm IKE dh group: id=14, name=OAKLEY_GROUP_MODP2048, bits=2048
000 algorithm IKE dh group: id=15, name=OAKLEY_GROUP_MODP3072, bits=3072
000 algorithm IKE dh group: id=16, name=OAKLEY_GROUP_MODP4096, bits=4096
000 algorithm IKE dh group: id=17, name=OAKLEY_GROUP_MODP6144, bits=6144
000 algorithm IKE dh group: id=18, name=OAKLEY_GROUP_MODP8192, bits=8192
000 algorithm IKE dh group: id=22, name=OAKLEY_GROUP_DH22, bits=1024
000 algorithm IKE dh group: id=23, name=OAKLEY_GROUP_DH23, bits=2048
000 algorithm IKE dh group: id=24, name=OAKLEY_GROUP_DH24, bits=2048
000
000 stats db_ops: {curr_cnt, total_cnt, maxsz} :context={0,2,64} trans={0,2,6144} attrs={0,2,4096}
000
000 Connection list:
000
000 "net1": 172.16.0.0/28===172.16.0.9[13.115.82.28]---172.16.0.1...54.249.119.97<54.249.119.97>===172.16.1.0/28; erouted; eroute owner: #2
000 "net1":     oriented; my_ip=unset; their_ip=unset
000 "net1":   xauth us:none, xauth them:none,  my_username=[any]; their_username=[any]
000 "net1":   modecfg info: us:none, them:none, modecfg policy:push, dns1:unset, dns2:unset, domain:unset, banner:unset, cat:unset;
000 "net1":   labeled_ipsec:no;
000 "net1":   policy_label:unset;
000 "net1":   ike_life: 28800s; ipsec_life: 3600s; replay_window: 32; rekey_margin: 540s; rekey_fuzz: 100%; keyingtries: 0;
000 "net1":   retransmit-interval: 500ms; retransmit-timeout: 60s;
000 "net1":   sha2-truncbug:no; initial-contact:no; cisco-unity:no; fake-strongswan:no; send-vendorid:no; send-no-esp-tfc:no;
000 "net1":   policy: PSK+ENCRYPT+TUNNEL+UP+AGGRESSIVE+IKEV1_ALLOW+IKEV2_ALLOW+SAREF_TRACK+IKE_FRAG_ALLOW+ESN_NO;
000 "net1":   conn_prio: 28,28; interface: eth0; metric: 0; mtu: unset; sa_prio:auto; sa_tfc:none;
000 "net1":   nflog-group: unset; mark: unset; vti-iface:unset; vti-routing:no; vti-shared:no;
000 "net1":   dpd: action:restart; delay:10; timeout:10; nat-t: force_encaps:yes; nat_keepalive:yes; ikev1_natt:both
000 "net1":   newest ISAKMP SA: #1; newest IPsec SA: #2;
000 "net1":   IKE algorithms wanted: AES_CBC(7)_128-SHA1(2)-MODP1024(2)
000 "net1":   IKE algorithms found:  AES_CBC(7)_128-SHA1(2)-MODP1024(2)
000 "net1":   IKE algorithm newest: AES_CBC_128-SHA1-MODP1024
000 "net1":   ESP algorithms wanted: AES(12)_128-SHA1(2); pfsgroup=MODP1024(2)
000 "net1":   ESP algorithms loaded: AES(12)_128-SHA1(2)
000 "net1":   ESP algorithm newest: AES_128-HMAC_SHA1; pfsgroup=<N/A>
000 "v6neighbor-hole-in": ::/0===::1<::1>:58/34560...%any:58/34816===::/0; prospective erouted; eroute owner: #0
000 "v6neighbor-hole-in":     oriented; my_ip=unset; their_ip=unset
000 "v6neighbor-hole-in":   xauth us:none, xauth them:none,  my_username=[any]; their_username=[any]
000 "v6neighbor-hole-in":   modecfg info: us:none, them:none, modecfg policy:push, dns1:unset, dns2:unset, domain:unset, banner:unset, cat:unset;
000 "v6neighbor-hole-in":   labeled_ipsec:no;
000 "v6neighbor-hole-in":   policy_label:unset;
000 "v6neighbor-hole-in":   ike_life: 0s; ipsec_life: 0s; replay_window: 0; rekey_margin: 0s; rekey_fuzz: 0%; keyingtries: 0;
000 "v6neighbor-hole-in":   retransmit-interval: 0ms; retransmit-timeout: 0s;
000 "v6neighbor-hole-in":   sha2-truncbug:no; initial-contact:no; cisco-unity:no; fake-strongswan:no; send-vendorid:no; send-no-esp-tfc:no;
000 "v6neighbor-hole-in":   policy: PFS+IKEV1_ALLOW+IKEV2_ALLOW+SAREF_TRACK+IKE_FRAG_ALLOW+ESN_NO+PASS+NEVER_NEGOTIATE;
000 "v6neighbor-hole-in":   conn_prio: 0,0; interface: lo; metric: 0; mtu: unset; sa_prio:1; sa_tfc:none;
000 "v6neighbor-hole-in":   nflog-group: unset; mark: unset; vti-iface:unset; vti-routing:no; vti-shared:no;
000 "v6neighbor-hole-in":   newest ISAKMP SA: #0; newest IPsec SA: #0;
000 "v6neighbor-hole-out": ::/0===::1<::1>:58/34816...%any:58/34560===::/0; prospective erouted; eroute owner: #0
000 "v6neighbor-hole-out":     oriented; my_ip=unset; their_ip=unset
000 "v6neighbor-hole-out":   xauth us:none, xauth them:none,  my_username=[any]; their_username=[any]
000 "v6neighbor-hole-out":   modecfg info: us:none, them:none, modecfg policy:push, dns1:unset, dns2:unset, domain:unset, banner:unset, cat:unset;
000 "v6neighbor-hole-out":   labeled_ipsec:no;
000 "v6neighbor-hole-out":   policy_label:unset;
000 "v6neighbor-hole-out":   ike_life: 0s; ipsec_life: 0s; replay_window: 0; rekey_margin: 0s; rekey_fuzz: 0%; keyingtries: 0;
000 "v6neighbor-hole-out":   retransmit-interval: 0ms; retransmit-timeout: 0s;
000 "v6neighbor-hole-out":   sha2-truncbug:no; initial-contact:no; cisco-unity:no; fake-strongswan:no; send-vendorid:no; send-no-esp-tfc:no;
000 "v6neighbor-hole-out":   policy: PFS+IKEV1_ALLOW+IKEV2_ALLOW+SAREF_TRACK+IKE_FRAG_ALLOW+ESN_NO+PASS+NEVER_NEGOTIATE;
000 "v6neighbor-hole-out":   conn_prio: 0,0; interface: lo; metric: 0; mtu: unset; sa_prio:1; sa_tfc:none;
000 "v6neighbor-hole-out":   nflog-group: unset; mark: unset; vti-iface:unset; vti-routing:no; vti-shared:no;
000 "v6neighbor-hole-out":   newest ISAKMP SA: #0; newest IPsec SA: #0;
000
000 Total IPsec connections: loaded 3, active 1
000
000 State Information: DDoS cookies not required, Accepting new IKE connections
000 IKE SAs: total(1), half-open(0), open(0), authenticated(1), anonymous(0)
000 IPsec SAs: total(1), authenticated(1), anonymous(0)
000
000 #2: "net1":4500 STATE_QUICK_I2 (sent QI2, IPsec SA established); EVENT_SA_REPLACE in 2833s; newest IPSEC; eroute owner; isakmp#1; idle; import:admin initiate
000 #2: "net1" esp.132609f1@54.249.119.97 esp.c3c2929e@172.16.0.9 tun.0@54.249.119.97 tun.0@172.16.0.9 ref=0 refhim=0 Traffic: ESPin=0B ESPout=0B! ESPmax=4194303B
000 #1: "net1":4500 STATE_AGGR_I2 (sent AI2, ISAKMP SA established); EVENT_SA_REPLACE in 27792s; newest ISAKMP; lastdpd=5s(seq in:709 out:0); idle; import:admin initiate
000
000 Bare Shunt list:
000
[root@ip-172-16-0-9 ipsec.d]#
```

### SSH接続

```bash
[root@ip-172-16-0-9 ipsec.d]# sudo su - centos
Last login: Fri May  3 14:27:09 UTC 2024 on pts/0
[centos@ip-172-16-0-9 ~]$ ssh 172.16.1.8
Last login: Fri May  3 14:32:08 2024 from ip-172-16-0-9.ap-northeast-1.compute.internal
[centos@ip-172-16-1-8 ~]$
```
