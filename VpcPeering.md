# VPC Peering で　VPC間を接続


- [vpc-peering.yaml](templates/vpc-peering.yaml)

![vpc-peering1.png](images%2Fvpc-peering1.png)
![vpc-peering2.png](images%2Fvpc-peering2.png)
![vpc-peering3.png](images%2Fvpc-peering3.png)
![vpc-peering4.png](images%2Fvpc-peering4.png)
![vpc-peering5.png](images%2Fvpc-peering5.png)

# EC2にログインして接続確認

秘密鍵を設定

```shell
cd
mkdir -m 755 .ssh
vi .ssh/id_rsa
chmod 400 .ssh/id_rsa
```

```shell
VPC1_SUBNET1_EC2=ip-172-16-0-4.ap-northeast-1.compute.internal
VPC2_SUBNET1_EC2=ip-172-16-1-6.ap-northeast-1.compute.internal
```

VPC1_SUBNET1_EC2にログインして検証

同一EC2

```shell
ssh -i .ssh/id_rsa ec2-user@$VPC1_SUBNET1_EC2
```

```shell
Last login: Wed Apr  3 10:21:06 2024 from 172.16.0.4
[ec2-user@ip-172-16-0-4 ~]$ hostname
ip-172-16-0-4.ap-northeast-1.compute.internal
```

VPC2_SUBNET1_EC2にログインして検証

```shell
ssh -i .ssh/id_rsa ec2-user@$VPC2_SUBNET1_EC2
```

```shell
Last login: Wed Apr  3 10:16:35 2024 from 172.16.0.4
[ec2-user@ip-172-16-1-6 ~]$ hostname
ip-172-16-1-6.ap-northeast-1.compute.internal
```