
# AWS Functions for managing AWS resources and SSO login
# Usage: aws_login profile_name [-r] to refresh cache
aws_login() {
    local REFRESH=0
    local PROFILE="$1"
    local CACHE_DIR="$HOME/.cache/functions/aws/$PROFILE"
    
    local PIPELINE_CACHE_FILE="$CACHE_DIR/pipeline_list.txt"
    local LAMBDA_CACHE_FILE="$CACHE_DIR/lambda_list.txt"
    local LOG_GROUP_CACHE_FILE="$CACHE_DIR/log_group_list.txt"
    local CLOUDFORMATION_CACHE_FILE="$CACHE_DIR/stack_list.txt"

    local ACTIVE_PROFILE_FILE="$HOME/.cache/functions/aws/active_profile"
    aws sso login --profile "$PROFILE"

    
    echo "$PROFILE" > "$ACTIVE_PROFILE_FILE"
    echo "Logged in to AWS profile: $PROFILE"

    mkdir -p "$CACHE_DIR"
    if [ "$2" = "-r" ]; then
        REFRESH=1
    fi
    if [ $REFRESH -eq 1 ] || [ ! -f "$PIPELINE_CACHE_FILE" ] || [ ! -f "$LAMBDA_CACHE_FILE" ]; then
        echo "Refreshing cache for pipelines and Lambda functions..."
        aws codepipeline list-pipelines --profile "$PROFILE" --query 'pipelines[*].name' --output text | tr '\t' '\n' >"$PIPELINE_CACHE_FILE"
        aws lambda list-functions --profile "$PROFILE" --query 'Functions[*].FunctionName' --output text | tr '\t' '\n' >"$LAMBDA_CACHE_FILE"
        aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output text --profile $PROFILE | tr '\t' '\n' > "$LOG_GROUP_CACHE_FILE"
        aws cloudformation list-stacks --profile "$PROFILE" --query "StackSummaries[?StackStatus!='DELETE_COMPLETE'].StackName" --output text | tr '\t' '\n' >"$CLOUDFORMATION_CACHE_FILE"
    fi
}

get_active_profile() {
    local ACTIVE_PROFILE_FILE="$HOME/.cache/functions/aws/active_profile"
    if [[ -f "$ACTIVE_PROFILE_FILE" ]]; then
        cat "$ACTIVE_PROFILE_FILE"
    else
        echo "No active profile set."
        return 1
    fi
}

# Functions to login to DTA environments
aws_dta() {
    aws_login dta "$1"
}

aws_prod() {
    aws_login prod "$1"
}

s3explore() {
    local bucket
    bucket=$(aws s3 ls --profile $AWS_PROFILE | awk '{print $NF}' | fzf)
    if [ -z "$bucket" ]; then
        echo "No bucket selected."
        return 1
    fi
    local prefix=""
    local -a back_stack forward_stack
    while true; do
        local items_list items menu_choice
        items_list=$(aws s3 ls "s3://$bucket/$prefix" --profile $AWS_PROFILE | awk '{print $NF}')
        menu_choice=$(printf "[BACK]\n[FORWARD]\n%s" "$items_list" | fzf --prompt="s3://$bucket/$prefix")
        if [ -z "$menu_choice" ]; then
            break
        fi
        if [ "$menu_choice" = "[BACK]" ]; then
            if [ ${#back_stack[@]} -gt 0 ]; then
                forward_stack+=("$prefix")
                prefix="${back_stack[-1]}"
                unset 'back_stack[-1]'
            fi
            continue
        elif [ "$menu_choice" = "[FORWARD]" ]; then
            if [ ${#forward_stack[@]} -gt 0 ]; then
                back_stack+=("$prefix")
                prefix="${forward_stack[-1]}"
                unset 'forward_stack[-1]'
            fi
            continue
        fi
        items="$menu_choice"
        if [[ "$items" == */ ]]; then
            back_stack+=("$prefix")
            prefix="$prefix$items"
            forward_stack=()
        else
            local action
            action=$(printf "preview\ndownload\ncancel" | fzf --prompt="Choose action for $items: ")
            if [ "$action" = "preview" ]; then
                aws s3 cp "s3://$bucket/$prefix$items" - --profile $AWS_PROFILE | head -20
            elif [ "$action" = "download" ]; then
                aws s3 cp "s3://$bucket/$prefix$items" . --profile $AWS_PROFILE
                echo "Downloaded $items to current directory."
            fi
        fi
    done
}
