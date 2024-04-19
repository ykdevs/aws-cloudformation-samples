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

[Oracle Cloud：Oracle Cloud と AWS を IPSec VPN(Libreswan)でマルチクラウド接続してみてみた](https://qiita.com/shirok/items/a0848df3d3d67fccd4f9)



## Libreswan3.18に落としてインストール


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


### VPC1 EC2

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
    leftid=3.113.89.173
    leftsubnet=172.16.0.0/28
    right=18.176.227.35
    rightid=18.176.227.35
    rightsubnet=172.16.1.0/28
    dpdaction=restart_by_peer
    dpdtimeout=10
    dpddelay=10
EOF
```

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
    leftid=18.176.227.35
    leftsubnet=172.16.1.0/28
    right=%any
    rightid=%any
    rightsubnet=172.16.0.0/28
    dpdaction=restart_by_peer
    dpdtimeout=10
    dpddelay=10
EOF
```



```bash

cat << EOF > net1.conf
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
    left=\${LEFT}
    leftid=\${LEFT_ID}
    leftsubnet=\${LEFT_SUBNET}
    right=\${RIGHT_ID}
    rightid=\${RIGHT_ID}
    rightsubnet=\${RIGHT_SUBNET}
    dpdaction=restart_by_peer
    dpdtimeout=10
    dpddelay=10
EOF

export LEFT=%defaultroute
export LEFT_ID=
export LEFT_SUBNET=172.16.0.1
export RIGHT_ID=
export RIGHT_SUBNET=172.16.0.1
envsubst < net1.conf > /etc/ipsec.d/net1.conf

cat << EOF > net1.secrets
%any : PSK "\${PSK}"
EOF

export PSK=
envsubst < net1.secrets > /etc/ipsec.d/net1.secrets
```


```bash
export LEFT=%defaultroute
export LEFT_ID=3.115.72.40
export LEFT_SUBNET=172.16.0.0/28
export RIGHT_ID=35.76.160.9
export RIGHT_SUBNET=172.16.1.0/28

envsubst < net1.conf > /etc/ipsec.d/net1.conf

export PSK=sRkkJ7sfczXi2BH1WzUnxRiJiLtNFPxO

envsubst < net1.secrets > /etc/ipsec.d/net1.secrets
```

```bash
export LEFT=%defaultroute
export LEFT_ID=35.76.160.9
export LEFT_SUBNET=172.16.1.0/28
export RIGHT_ID=%any
export RIGHT_SUBNET=172.16.0.0/28

envsubst < net1.conf > /etc/ipsec.d/net1.conf

export PSK=sRkkJ7sfczXi2BH1WzUnxRiJiLtNFPxO

envsubst < net1.secrets > /etc/ipsec.d/net1.secrets
```

```bash
systemctl enable ipsec
systemctl stop ipsec
systemctl start ipsec
systemctl status ipsec
```


```bash
export LEFT=%defaultroute
export LEFT_ID=35.74.113.176
export LEFT_SUBNET=10.100.85.0/24
export RIGHT_ID=210.227.29.77
export RIGHT_SUBNET=210.227.29.88/30

envsubst < net1.conf > /etc/ipsec.d/net1.conf

export PSK=owcsvDRhdfW5V0Mi7U1OeSqNPutlEbJj

envsubst < net1.secrets > /etc/ipsec.d/net1.secrets
```
