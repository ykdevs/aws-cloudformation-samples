#! /bin/bash
# Make AWS Cognito UserPool & IdPool
#
#  ./cognito-sample.sh -a [describe|create|delete] [-u UserPoolName] [-c ClientName] [-i IdPoolName]
#
#  -a action
#      describe : Describe UserPool & IdPool
#      create   : Create UserPool & IdPool
#      delete   : Delete UserPool & IdPool
#
#  -u UserPoolName : Default UserPoolSample
#  -c ClientName   : Default AppClientSample
#  -i IdPoolName   : Default IdPoolSample
#
# https://qiita.com/fkooo/items/660cab0090a80861155b
# https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/index.html#cli-aws-cognito-idp

set -eu

ACTION=describe
USER_POOL_NAME=UserPoolSample
CLIENT_NAME=AppClientSample
ID_POOL_NAME=IdPoolSample

while getopts a:u:c:i: OPT
do
  case $OPT in
     a) ACTION=${OPTARG};;
     u) USER_POOL_NAME=${OPTARG};;
     c) CLIENT_NAME=${OPTARG};;
     i) ID_POOL_NAME=${OPTARG};;
     *) usage;;
  esac
done

usage() {
  echo "$0 -a describe|create [-u UserPoolName] [-c ClientName] [-i IdPoolName]"
}

getUserPoolId() {
  USER_POOL_NAME=$1
  echo $(aws cognito-idp list-user-pools --max-results 20 \
   | jq -r '.UserPools[]|select(.Name=="'${USER_POOL_NAME}'")|.Id')
}

getClientId() {
  USER_POOL_NAME=$1
  CLIENT_NAME=$2
  echo $(aws cognito-idp list-user-pool-clients --user-pool-id ${USER_POOL_ID} \
   | jq -r '.UserPoolClients[]|select(.ClientName=="'${CLIENT_NAME}'")|.ClientId')
}

getIdPoolId() {
  ID_POOL_NAME=$1
  echo $(aws cognito-identity list-identity-pools --max-results 20 \
   | jq -r '.IdentityPools[]|select(.IdentityPoolName=="'${ID_POOL_NAME}'")|.IdentityPoolId')
}


describe() {
  USER_POOL_NAME=$1
  CLIENT_NAME=$2
  ID_POOL_NAME=$3

  # List UserPools
  # https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/list-user-pools.html
  aws cognito-idp list-user-pools --max-results 20
  USER_POOL_ID=$(getUserPoolId "${USER_POOL_NAME}")

  # Describe UserPool
  # https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/describe-user-pool.html
  aws cognito-idp describe-user-pool --user-pool-id ${USER_POOL_ID} | tee ${USER_POOL_NAME}.json

  # List UserPoolClients
  aws cognito-idp list-user-pool-clients --user-pool-id ${USER_POOL_ID}
  CLIENT_ID=$(getClientId "${USER_POOL_ID}" "${CLIENT_NAME}")

  # Describe UserPool Client
  aws cognito-idp describe-user-pool-client --user-pool-id ${USER_POOL_ID} --client-id ${CLIENT_ID} | tee ${CLIENT_NAME}.json

  # List IdentityPool
  aws cognito-identity list-identity-pools --max-results 20
  ID_POOL_ID=$(getIdPoolId "${ID_POOL_NAME}")

  # Describe IdPool
  aws cognito-identity describe-identity-pool --identity-pool-id ${ID_POOL_ID} | tee ${ID_POOL_NAME}.json

  echo "USER_POOL_ID=${USER_POOL_ID}"
  echo "CLIENT_ID=${CLIENT_ID}"
  echo "ID_POOL_ID=${ID_POOL_ID}"
}

create() {
  USER_POOL_NAME=$1
  CLIENT_NAME=$2
  ID_POOL_NAME=$3

  # Create UserPool
  # https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/create-user-pool.html
  aws cognito-idp create-user-pool --pool-name ${USER_POOL_NAME} \
  --auto-verified-attributes email \
  --username-attributes email \
  --username-configuration 'CaseSensitive=false' \
  --account-recovery-setting 'RecoveryMechanisms=[{Priority=1,Name=verified_email},{Priority=2,Name=verified_phone_number}]' \
  --schema 'Name=role,AttributeDataType=String,DeveloperOnlyAttribute=false,Mutable=true,Required=false,StringAttributeConstraints={MinLength=1,MaxLength=256}'

  # Get UserPoolId
  USER_POOL_ID=$(getUserPoolId "${USER_POOL_NAME}")

  # Create UserPoolClient
  aws cognito-idp create-user-pool-client --user-pool-id ${USER_POOL_ID} --client-name ${CLIENT_NAME} \
  --refresh-token-validity 30 \
  --access-token-validity  60 \
  --id-token-validity 60 \
  --token-validity-units 'AccessToken=minutes,IdToken=minutes,RefreshToken=days' \
  --read-attributes "address" "birthdate" "custom:role" "email" "email_verified" "family_name" "gender" "given_name" \
  "locale" "middle_name" "name" "nickname" "phone_number" "phone_number_verified" "picture" "preferred_username" \
  "profile" "updated_at" "website" "zoneinfo" \
  --write-attributes "address" "birthdate" "custom:role" "email" "family_name" "gender" "given_name" "locale" "middle_name" \
  "name" "nickname" "phone_number" "picture" "preferred_username" "profile" "updated_at" "website" "zoneinfo" \
  --explicit-auth-flows "ALLOW_REFRESH_TOKEN_AUTH" "ALLOW_USER_SRP_AUTH" \
  --prevent-user-existence-errors ENABLED

  # Get ClientId
  CLIENT_ID=$(getClientId "${USER_POOL_ID}" "${CLIENT_NAME}")

  # Create IdPool
  aws cognito-identity create-identity-pool --identity-pool-name ${ID_POOL_NAME} \
  --no-allow-unauthenticated-identities --no-allow-classic-flow \
  --cognito-identity-providers "ProviderName=cognito-idp.ap-northeast-1.amazonaws.com/${USER_POOL_ID},ClientId=${CLIENT_ID},ServerSideTokenCheck=false"

  ID_POOL_ID=$(getIdPoolId "${ID_POOL_NAME}")

  AUTH_ROLE_NAME="Cognito_${ID_POOL_NAME}Auth_Role"
  UNAUTH_ROLE_NAME="Cognito_${ID_POOL_NAME}Unauth_Role"
cat << EOF > ${AUTH_ROLE_NAME}.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "cognito-identity.amazonaws.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "cognito-identity.amazonaws.com:aud": "${ID_POOL_ID}"
                },
                "ForAnyValue:StringLike": {
                    "cognito-identity.amazonaws.com:amr": "authenticated"
                }
            }
        }
    ]
}
EOF
cat << EOF > ${UNAUTH_ROLE_NAME}.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "cognito-identity.amazonaws.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "cognito-identity.amazonaws.com:aud": "${ID_POOL_ID}"
                },
                "ForAnyValue:StringLike": {
                    "cognito-identity.amazonaws.com:amr": "unauthenticated"
                }
            }
        }
    ]
}
EOF
  aws iam create-role --role-name ${AUTH_ROLE_NAME} --assume-role-policy-document file://${AUTH_ROLE_NAME}.json
  aws iam create-role --role-name ${UNAUTH_ROLE_NAME} --assume-role-policy-document file://${UNAUTH_ROLE_NAME}.json

cat << EOF > ${AUTH_ROLE_NAME}.policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "mobileanalytics:PutEvents",
                "cognito-sync:*",
                "cognito-identity:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
cat << EOF > ${UNAUTH_ROLE_NAME}.policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "mobileanalytics:PutEvents",
                "cognito-sync:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
  aws iam put-role-policy --role-name ${AUTH_ROLE_NAME} --policy-name "oneClick_Cognito_${AUTH_ROLE_NAME}_Role" \
    --policy-document file://${AUTH_ROLE_NAME}.policy.json
  AUTH_ROLE_ARN=$(aws iam get-role --role-name ${AUTH_ROLE_NAME} | jq -r .Role.Arn)
  aws iam put-role-policy --role-name ${UNAUTH_ROLE_NAME} --policy-name "oneClick_Cognito_${UNAUTH_ROLE_NAME}_Role" \
    --policy-document file://${UNAUTH_ROLE_NAME}.policy.json
  UNAUTH_ROLE_ARN=$(aws iam get-role --role-name ${UNAUTH_ROLE_NAME} | jq -r .Role.Arn)

  # Set IdentityPoolRoles
  aws cognito-identity set-identity-pool-roles --identity-pool-id ${ID_POOL_ID} \
    --roles authenticated="${AUTH_ROLE_ARN}",unauthenticated="${UNAUTH_ROLE_ARN}"

  rm -f ${AUTH_ROLE_NAME}.json ${UNAUTH_ROLE_NAME}.json ${AUTH_ROLE_NAME}.policy.json ${UNAUTH_ROLE_NAME}.policy.json
}

delete() {
  USER_POOL_NAME=$1
  CLIENT_NAME=$2
  ID_POOL_NAME=$3

  USER_POOL_ID=$(getUserPoolId "${USER_POOL_NAME}")
  CLIENT_ID=$(getClientId "${USER_POOL_ID}" "${CLIENT_NAME}")
  ID_POOL_ID=$(getIdPoolId "${ID_POOL_NAME}")

  # Delete IdPool
  aws cognito-identity delete-identity-pool --identity-pool-id ${ID_POOL_ID}

  # Delete IAM Role
  AUTH_ROLE_NAME="Cognito_${ID_POOL_NAME}Auth_Role"
  UNAUTH_ROLE_NAME="Cognito_${ID_POOL_NAME}Unauth_Role"
  aws iam delete-role-policy --role-name ${AUTH_ROLE_NAME} --policy-name "oneClick_Cognito_${AUTH_ROLE_NAME}_Role"
  aws iam delete-role --role-name ${AUTH_ROLE_NAME}
  aws iam delete-role-policy --role-name ${UNAUTH_ROLE_NAME} --policy-name "oneClick_Cognito_${UNAUTH_ROLE_NAME}_Role"
  aws iam delete-role --role-name ${UNAUTH_ROLE_NAME}

  # Delete Client
  aws cognito-idp delete-user-pool-client --user-pool-id ${USER_POOL_ID} --client-id ${CLIENT_ID}

  # Delete UserPool
  aws cognito-idp delete-user-pool --user-pool-id ${USER_POOL_ID}
}

case ${ACTION} in
  describe) describe "${USER_POOL_NAME}" "${CLIENT_NAME}" "${ID_POOL_NAME}";;
  create) create "${USER_POOL_NAME}" "${CLIENT_NAME}" "${ID_POOL_NAME}";;
  delete) delete "${USER_POOL_NAME}" "${CLIENT_NAME}" "${ID_POOL_NAME}";;
esac
