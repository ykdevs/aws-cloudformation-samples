#! /bin/bash
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

describe() {
  USER_POOL_NAME=$1
  CLIENT_NAME=$2
  ID_POOL_NAME=$3

  # List UserPools
  # https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/list-user-pools.html
  aws cognito-idp list-user-pools --max-results 20
  USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 20 \
   | jq -r '.UserPools|map(select(.Name=="'${USER_POOL_NAME}'"))|.[0].Id')

  # Describe UserPool
  # https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/describe-user-pool.html
  aws cognito-idp describe-user-pool --user-pool-id ${USER_POOL_ID} | tee ${USER_POOL_NAME}.json

  # List UserPoolClients
  aws cognito-idp list-user-pool-clients --user-pool-id ${USER_POOL_ID}
  CLIENT_ID=$(aws cognito-idp list-user-pool-clients --user-pool-id ${USER_POOL_ID} \
   | jq -r '.UserPoolClients|map(select(.ClientName=="'${CLIENT_NAME}'"))|.[0].ClientId')

  # Describe UserPool Client
  aws cognito-idp describe-user-pool-client --user-pool-id ${USER_POOL_ID} --client-id ${CLIENT_ID} | tee ${CLIENT_NAME}.json

  # List IdentityPool
  aws cognito-identity list-identity-pools --max-results 20
  ID_POOL_ID=$(aws cognito-identity list-identity-pools --max-results 20 \
   | jq -r '.IdentityPools|map(select(.IdentityPoolName=="'${ID_POOL_NAME}'"))|.[0].IdentityPoolId')

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
  USER_POOL_NAME=UserPoolSample2
  aws cognito-idp create-user-pool --pool-name ${USER_POOL_NAME} \
  --auto-verified-attributes email \
  --username-configuration 'CaseSensitive=false' \
  --account-recovery-setting 'RecoveryMechanisms=[{Priority=1,Name=verified_email},{Priority=2,Name=verified_phone_number}]' \
  --schema 'Name=email,AttributeDataType=String,DeveloperOnlyAttribute=false,Mutable=true,Required=true,StringAttributeConstraints={MinLength=0,MaxLength=2048}'

  # Get UserPoolId
  USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 20 \
   | jq -r '.UserPools|map(select(.Name=="'${USER_POOL_NAME}'"))|.[0].Id')

  # Create UserPoolClient
  CLIENT_NAME=AppClientSample2
  aws cognito-idp create-user-pool-client --user-pool-id ${USER_POOL_ID} --client-name ${CLIENT_NAME} \
  --refresh-token-validity 30 \
  --access-token-validity  60 \
  --id-token-validity 60 \
  --token-validity-units 'AccessToken=minutes,IdToken=minutes,RefreshToken=days' \
  --read-attributes "address" "birthdate" "email" "email_verified" "family_name" "gender" "given_name" "locale" \
  "middle_name" "name" "nickname" "phone_number" "phone_number_verified" "picture" "preferred_username" "profile" \
  "updated_at" "website" "zoneinfo" \
  --write-attributes "address" "birthdate" "email" "family_name" "gender" "given_name" "locale" "middle_name" \
  "name" "nickname" "phone_number" "picture" "preferred_username" "profile" "updated_at" "website" "zoneinfo" \
  --explicit-auth-flows "ALLOW_REFRESH_TOKEN_AUTH" "ALLOW_USER_SRP_AUTH" \
  --prevent-user-existence-errors ENABLED

  # Get ClientId
  CLIENT_ID=$(aws cognito-idp list-user-pool-clients --user-pool-id ${USER_POOL_ID} \
   | jq -r '.UserPoolClients|map(select(.ClientName=="'${CLIENT_NAME}'"))|.[0].ClientId')

  # Create IdPool
  aws cognito-identity create-identity-pool --identity-pool-name ${ID_POOL_NAME} \
  --no-allow-unauthenticated-identities --no-allow-classic-flow \
  --cognito-identity-providers "ProviderName=cognito-idp.ap-northeast-1.amazonaws.com/${USER_POOL_ID},ClientId=${CLIENT_ID},ServerSideTokenCheck=false"
}

case ${ACTION} in
  describe) describe "${USER_POOL_NAME}" "${CLIENT_NAME}" "${ID_POOL_NAME}";;
  create) create "${USER_POOL_NAME}" "${CLIENT_NAME}" "${ID_POOL_NAME}";;
esac
