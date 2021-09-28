#!/bin/bash
ENTERPRISE_API_KEY=$1
SECRETS_MANAGER_REGION=$2
SECRETS_MANAGER_NAME=$3
SECRETS_GROUP_NAME=$4
SECRET_NAME=$5
CHILD_ACCOUNT_API_KEY=$6

# Encode secrets manager name to ignore spaces
URL_ENCODED_SECRETS_MANAGER_NAME=$(echo "$SECRETS_MANAGER_NAME" | sed 's/:/%3A/g' | sed 's/\//%2F/g' | sed 's: :%20:g')

# Get token
TOKEN=$(
    echo $(
        curl -s -X POST \
            -H "Content-Type: application/x-www-form-urlencoded" \
            --data-urlencode "apikey=$ENTERPRISE_API_KEY" \
            --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
            "https://iam.cloud.ibm.com/identity/token" | jq -r ".access_token"
    )
)

# Get secrets manager guid from name
SECRETS_MANAGER_GUID=$(
    curl -s -X GET \
        https://resource-controller.cloud.ibm.com/v2/resource_instances?name=$URL_ENCODED_SECRETS_MANAGER_NAME \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/json" | jq -r ".resources[0].guid"
)

# Get list of secrets manager groups
SECRETS_MANAGER_GROUPS=$(
    curl -s https://$SECRETS_MANAGER_GUID.$SECRETS_MANAGER_REGION.secrets-manager.appdomain.cloud/api/v1/secret_groups \
        -H "Authorization: Bearer $TOKEN" | jq ".resources"
)

# Number of Groups 
GROUPS_COUNT=$(echo $SECRETS_MANAGER_GROUPS | jq ". | length")
# Get length of array
GROUPS_LENGTH=$(($GROUPS_COUNT - 1))
# Store ID if found
GROUP_ID=0

# Look for group name and get id
for i in $(seq 0 $GROUPS_LENGTH)
do
    FOUND_NAME=$(echo $SECRETS_MANAGER_GROUPS | jq -r ".[$i].name")
    if [ "$FOUND_NAME" == "$SECRETS_GROUP_NAME" ]; then
        GROUP_ID=$(echo $SECRETS_MANAGER_GROUPS | jq -r ".[$i].id")
    fi
done

if [ "$GROUP_ID" == "0" ]; then
    echo "Could not find secrets manager group $SECRETS_GROUP_NAME"
    exit 2
else
    # POST to secrets mananger
    RESPONSE=$(
        echo $(
            curl -s -X POST \
                -H "Authorization: Bearer $TOKEN" \
                -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                -d '{
                    "metadata": {
                        "collection_type": "application/vnd.ibm.secrets-manager.secret+json",
                        "collection_total": 1
                    },
                    "resources": [{
                        "name": "'$SECRET_NAME'",
                        "description": "Extended description for this secret.",
                        "secret_group_id": "'$GROUP_ID'",
                        "payload": "'$CHILD_ACCOUNT_API_KEY'",
                        "expiration_date": "2030-01-01T00:00:00Z"
                    }]
                }' \
                "https://$SECRETS_MANAGER_GUID.$SECRETS_MANAGER_REGION.secrets-manager.appdomain.cloud/api/v1/secrets/arbitrary"
        )
    )

    ERROR_MESSAGE=$(echo $RESPONSE | jq -r ".errors[0].message")
    if [ "$ERROR_MESSAGE" != "null" ]; then
        echo $ERROR_MESSAGE
    else
        SECRET_ID=$(echo $RESPONSE | jq -r ".resources[0].id")
        echo "Secret name $SECRET_NAME created with ID $SECRET_ID"
    fi
fi

