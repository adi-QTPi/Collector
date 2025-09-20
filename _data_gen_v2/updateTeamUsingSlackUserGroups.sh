#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Check for at least two arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <output_yml_file> <usergroup_handle1> [usergroup_handle2 ...]"
    exit 1
fi

bash _data_gen_v2/latestUserGroups.sh

# Define folders
ASSETS_DIR="assets/images/members/current"
OUTPUT_DIR="_data"
OUTPUT_FILE="$OUTPUT_DIR/$1.yml"

# Create folders if they don't exist
mkdir -p "$ASSETS_DIR"
mkdir -p "$OUTPUT_DIR"

shift  # Remove first argument so $@ contains only handles

# Start YAML file
echo "---" > "$OUTPUT_FILE"

USERGROUP_MAP_FILE="usergroups.json"

declare -A DOWNLOADED_USERS
declare -A WRITTEN_USERS

for HANDLE in "$@"; do
    GROUP_ID=$(jq -r --arg handle "$HANDLE" '.[$handle]' "$USERGROUP_MAP_FILE")
    if [ "$GROUP_ID" == "null" ]; then
        echo "Usergroup handle '$HANDLE' not found. Skipping."
        continue
    fi

    echo "Fetching users for $HANDLE (ID: $GROUP_ID)..."

    USER_IDS=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
        "https://slack.com/api/usergroups.users.list?usergroup=$GROUP_ID" \
        | jq -r '.users // empty | .[]')

    if [ -z "$USER_IDS" ]; then
        echo "No users found or API call failed for '$HANDLE'. Skipping."
        continue
    fi

    while IFS= read -r USER_ID; do
        USER_INFO=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
                    "https://slack.com/api/users.info?user=$USER_ID" \
                    | jq '.user')

        REAL_NAME=$(echo "$USER_INFO" | jq -r '.profile.real_name')
        FULL_NAME=$(echo "$REAL_NAME" | tr ' ' '_')
        IMAGE_FILE="${ASSETS_DIR}/${FULL_NAME}.webp"

        if [ -z "${DOWNLOADED_USERS[$FULL_NAME]}" ]; then
            # Pick the largest available image
            IMAGE_URL=$(echo "$USER_INFO" | jq -r '
            .profile.image_1024 // 
            .profile.image_512 // 
            .profile.image_192 // 
            .profile.image_72 // 
            .profile.image_48 // 
            .profile.image_32 // 
            .profile.image_24
            ')

            if [ "$IMAGE_URL" != "null" ]; then
                # Download original image temporarily
                TMP_FILE=$(mktemp)
                curl -s "$IMAGE_URL" -o "$TMP_FILE"

                # Convert to WebP with high quality
                cwebp -q 100 "$TMP_FILE" -o "$IMAGE_FILE" >/dev/null 2>&1

                # Remove temporary file
                rm "$TMP_FILE"
            fi

            DOWNLOADED_USERS[$FULL_NAME]=1
        fi

        if [ -z "${WRITTEN_USERS[$FULL_NAME]}" ]; then
            echo "- name: $REAL_NAME" >> "$OUTPUT_FILE"
            echo "  pic: ${FULL_NAME}.webp" >> "$OUTPUT_FILE"
            echo "  links:" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            WRITTEN_USERS[$FULL_NAME]=1
        fi
    done <<< "$USER_IDS"
done

echo "YAML file saved to $OUTPUT_FILE"
