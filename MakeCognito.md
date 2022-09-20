# MakeCognito

## Cognito環境の構築

[cognito-for-app.yaml](cloudformation-templates/cognito-for-app.yaml)

### リソース

以下のリソースが作成される。

| 論理ID | タイプ | 説明 |
|---|---|---|
| SampleUserPool | AWS::Cognito::UserPool | CognitoのUser Pool。ユーザーを管理する。 |
| SampleUserPoolClient | AWS::Cognito::UserPoolClient | CognitoのAppClient。IdPoolとのつなぎ込みのクライアント。 |
| SampleIdPool | AWS::Cognito::IdentityPool | CognitoのId Pool。認証を行う。 |
| SampleAuthRole | AWS::IAM::Role | 認証OK時に付与されるIAMロール |
| SampleAuthRolePolicy | AWS::IAM::Policy | 認証OKロールに付与されるポリシー |
| SampleUnAuthRole | AWS::IAM::Role | 認証NG時に付与されるIAMロール |
| SampleUnAuthRolePolicy | AWS::IAM::Policy | 認証NGロールに付与されるポリシー |
| SampleIdPoolRoleAttachment | AWS::Cognito::IdentityPoolRoleAttachment | 認証OK、NGのロールをIdPoolに紐付ける。|

### 入力

| スタック名           |
|-----------------|
| sample-app-auth |

| キー | 説明 | デフォルト |
|---|---|-----|
| UserPoolName | UserPoolの名称 | SampleUserPool |
| ClientName | UserPoolAppClientの名称 | SampleClient |
| IdPoolName | IdPoolの名称 | SampleIdPool |
| DomainName | CognitoのDomain名 | sample-demo |

### 出力

| キー | 説明 | Export名 |
|---|---|---|
| SampleUserPoolId | UserPoolId | ${AWS::StackName}-SampleUserPoolId |
| SampleUserPoolClientId | UserPoolClientId | ${AWS::StackName}-SampleUserPoolClientId |
| SampleIdPoolId | IdPoolId | ${AWS::StackName}-SampleIdPoolId |
| SampleDomainName | CognitoのDomain名 | ${AWS::StackName}-SampleDomainName |
