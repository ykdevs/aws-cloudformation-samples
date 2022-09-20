# MakeEcsWithApiGateway

以下の４段階のCloudFormationテンプレートでAPI Gateway経由のECSを構築する。

1. Networkの構築
1. Application LoadBalancerの構築
1. API Gatewayの構築
1. ECSの構築

## Networkの構築

ECSのネットワークを構築する。

[private-subnet-for-ecs.yaml](templates/private-subnet-for-ecs.yaml)

### リソース

以下のリソースが作成される。

| 論理ID | タイプ | 説明 |
|---|---|---|
| SampleVPC | AWS::EC2::VPC | Sampleを構築するVPC |
| SampleVPCIGW | AWS::EC2::InternetGateway | VPCのInternet GW |
| SampleVPCVPCGW | AWS::EC2::VPCGatewayAttachment | VPCとInternetGWの紐付け |
| SampleVPCPrivateSubnet1Subnet | AWS::EC2::Subnet | ZapAppを構築するPrivateSubnet1 |
| SampleVPCPrivateSubnet1RouteTable | AWS::EC2::RouteTable | PrivateSubnet1のRoutingTable |
| SampleVPCPrivateSubnet1DefaultRoute | AWS::EC2::Route | PrivateSubnet1のDefaultRoute |
| SampleVPCPrivateSubnet1RouteTableAssociation | AWS::EC2::SubnetRouteTableAssociation | PrivateSubnet1のSubnetとRouteTableを紐付け |
| SampleVPCPrivateSubnet2Subnet | AWS::EC2::Subnet | ZapAppを構築するPrivateSubnet2 |
| SampleVPCPrivateSubnet2RouteTable | AWS::EC2::RouteTable | PrivateSubnet2のRoutingTable |
| SampleVPCPrivateSubnet2DefaultRoute | AWS::EC2::Route | PrivateSubnet2のDefaultRoute |
| SampleVPCPrivateSubnet2RouteTableAssociation | AWS::EC2::SubnetRouteTableAssociation | PrivateSubnet2のSubnetとRouteTableを紐付け |
| SampleVPCPublicSubnet1Subnet	 | AWS::EC2::Subnet | ZapAppを構築するPublicSubnet1 |
| SampleVPCPublicSubnet1RouteTable | AWS::EC2::RouteTable | PublicSubnet1のRoutingTable |
| SampleVPCPublicSubnet1DefaultRoute | AWS::EC2::RouteTable | PublicSubnet1のDefaultRoute |
| SampleVPCPublicSubnet1RouteTableAssociation | AWS::EC2::SubnetRouteTableAssociation | PublicSubnet1のSubnetとRouteTableを紐付け |
| SampleVPCPublicSubnet1EIP | AWS::EC2::EIP | PublicSubnet1のEIP（Public IP Address） |
| SampleVPCPublicSubnet1NATGateway | AWS::EC2::NATGateway | PublicSubnet1のNATGateway |
| SampleVPCPublicSubnet2Subnet	 | AWS::EC2::Subnet | ZapAppを構築するPublicSubnet2 |
| SampleVPCPublicSubnet2RouteTable | AWS::EC2::RouteTable | PublicSubnet2のRoutingTable |
| SampleVPCPublicSubnet2DefaultRoute | AWS::EC2::RouteTable | PublicSubnet2のDefaultRoute |
| SampleVPCPublicSubnet2RouteTableAssociation | AWS::EC2::SubnetRouteTableAssociation | PublicSubnet2のSubnetとRouteTableを紐付け |
| SampleVPCPublicSubnet2EIP | AWS::EC2::EIP | PublicSubnet2のEIP（Public IP Address） |
| SampleVPCPublicSubnet2NATGateway | AWS::EC2::NATGateway | PublicSubnet2のNATGateway |


### 入力

| スタック名          |
|----------------|
| sample-app-network |

| キー | 説明 | デフォルト | 備考 |
|---|---|---|---|
| VpcCidrBlock | VPCのIPレンジ | 10.0.0.0/16 | |
| PrivateSubnet1CidrBlock | PrivateSubnet1のIPレンジ | 10.0.128.0/18 | |
| PrivateSubnet2CidrBlock | PrivateSubnet2のIPレンジ | 10.0.192.0/18 | |
| PublicSubnet1CidrBlock | PublicSubnet1のIPレンジ | 10.0.0.0/18 | |
| PublicSubnet2CidrBlock | PublicSubnet2のIPレンジ | 10.0.64.0/18 | |

### 出力

| キー | 説明 | 備考 | Export名 |
|---|---|---|---|
| SampleVPC | VPC ID | ECSの構築で使用する。| ${AWS::StackName}-SampleVPC |
| SampleVPCPrivateSubnet1Subnet | PrivateSubnet1のSubnetId | ECSの構築で使用する。| ${AWS::StackName}-SampleVPCPrivateSubnet1Subnet |
| SampleVPCPrivateSubnet2Subnet | PrivateSubnet2のSubnetId | ECSの構築で使用する。| ${AWS::StackName}-SampleVPCPrivateSubnet2Subnet |

## Application Load Balancerの構築

ALBを構築する。

[alb-for-ecs.yaml](templates/alb-for-ecs.yaml)

### リソース

以下のリソースが作成される。

| 論理ID | タイプ | 説明 |
|---|---|---|
| SampleAlb | AWS::ElasticLoadBalancingV2::LoadBalancer | SampleのApplicationLoadBalancer |
| SampleAlbListener | AWS::ElasticLoadBalancingV2::Listener | ALBのリスナー（待受け） |
| SampleAlbTargetGroup | AWS::ElasticLoadBalancingV2::TargetGroup | ALBのターゲット（接続先） |
| SampleSecurityGroupForAlb | AWS::EC2::SecurityGroup | ALB用のSecurityGroup。Ingress(InBoundルール) |

### 入力

| スタック名 |
|---|
| sample-app-alb |

| キー | 説明 | デフォルト | 備考 |
|---|---|---|---|
| NetworkStackName | Network構築のスタック名 | sample-app-network | Export値を取得するために利用する。 |
| AlbPort | Application Load BalancerのPort | 80 | HTTPSを使う場合は証明書が必要 |
| ContainerPort | ContainerのAppのPort | 8080 | |

### 出力

| キー | 説明 | 備考 | Export名 |
|---|---|---|---|
| SampleAlbListener | ALBリスナーのARN | ECSの構築で使用する。| ${AWS::StackName}-SampleAlbListener |
| SampleAlbPort | ALBのPort | ECSの構築で使用する。| ${AWS::StackName}-SampleAlbPort |
| SampleContainerPort | ConteinerのAppのPort | ECSの構築で使用する。| ${AWS::StackName}-SampleContainerPort |

## API Gatewayの構築

API Gatewayを構築してインターネットからアクセスできるようにする。

※ サンプルでは認証はないので注意

[api-gateway-for-ecs.yaml](templates/api-gateway-for-ecs.yaml)

### リソース

以下のリソースが作成される。

| 論理ID | タイプ | 説明 |
|---|---|---|
| SampleVpcLink | AWS::ApiGatewayV2::VpcLink | ApiGatewayとVPCをつなぐVpcLink |
| SampleApi | AWS::ApiGatewayV2::Api | ApiGateway |
| SampleApiIntegration | AWS::ApiGatewayV2::Integration | ApiGatewayの設定 |
| SampleApiRoute | AWS::ApiGatewayV2::Route | ApiGatewayのRoute設定 |
| SampleApiStage | AWS::ApiGatewayV2::Stage | ApiGatewayのStageの設定。HTTP Proxyなのでdefault。 |
| SampleApiDeployment | AWS::ApiGatewayV2::Deployment | ApiGatewayのDeployment |

### 入力

| スタック名 |
|---|
| sample-app-apigw |

| キー | 説明 | デフォルト | 備考 |
|---|---|---|---|
| NetworkStackName | Network構築のスタック名 | sample-app-network | Export値を取得するために利用する。 |

### 出力

| キー | 説明 | 備考 |
|---|---|---|
| SampleExternalURL | 外部公開のAPI Gateway URL | 今のところ認証はなし |

## ECSの構築

作成したネットワーク上にFargateのECSを構築し、指定したDockerImageを展開する。

[fargate-in-private-subnet.yaml](templates/fargate-in-private-subnet.yaml)

### リソース

以下のリソースが作成される。

SecurityGroupはIngress(InBound)とEgress(OutBound)を同時に設定すると不具合になるので２回で設定する。

| 論理ID | タイプ | 説明 |
|---|---|---|
| SampleSecurityGroupEgressForAlb | AWS::EC2::SecurityGroupEgress | ALB用のSecurityGroupのEgress(OutBoundルール) |
| SampleSecurityGroupForEcs | AWS::EC2::SecurityGroup | ECS用のSecurityGroup。Egress(OutBoundルール) |
| SampleSecurityGroupIngressForEcs | AWS::EC2::SecurityGroupIngress | ECS用のSecurityGroupのEgress(InBoundルール) |
| SampleCluster | AWS::ECS::Cluster | ECSのコンテナクラスタ |
| SampleServiceTaskDef | AWS::ECS::TaskDefinition | ECSのタスク定義 |
| SampleServiceTaskDefExecutionRole | AWS::IAM::Role | タスクを実行するIAMロール |
| SampleServiceTaskDefExecutionRoleDefaultPolicy | AWS::IAM::Policy | タスクを実行するIAMロールに付与されるポリシー |
| SampleServiceTaskDefTaskRole | AWS::IAM::Role | ECSのログを落とすIAMロール |
| SampleServiceTaskDefwebLogGroup | AWS::Logs::LogGroup | ECSのログを出力するCloudWatch Logsのグループ |

### 入力

| スタック名      |
|------------|
| sample-app |

| キー | 説明 | デフォルト | 備考 |
|---|---|---|---|
| NetworkStackName | Network構築のスタック名 | sample-app-network | Export値を取得するために利用する。 |
| ApiGwStackName | ApiGw構築のスタック名 | sample-app-apigw | Export値を取得するために利用する。 |
|EcrImageName| ECRのImage名 | sample/sample-demo | |
| SpringProfilesActive | 環境変数SPRING_PROFILES_ACTIVE | prod | |

### 出力

| キー | 説明 | 備考 |
|---|---|---|
| SampleCluster | ECSのクラスタ名 |  |
| SampleServiceTaskDef | ECSのタスク定義名 |  |
| SampleService | ECSのサービス名 |  |


