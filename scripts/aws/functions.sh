aws_dta() {
  export AWS_PROFILE=dta
  aws sso login --profile dta
}

aws_prod() {
  export AWS_PROFILE=prod
  aws sso login --profile prod
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

# Get the latest pipeline state
# usage: pipeline <pipeline-name> <stage-name>
pipeline() {
  aws codepipeline get-pipeline-state --name "$1"-"$2"-pipeline \
  --query "stageStates[].{Stage: stageName, Status: latestExecution.status}" \
  --output table  --profile $AWS_PROFILE --no-cli-pager
}

pls() {
  aws codepipeline list-pipelines --profile $AWS_PROFILE --no-cli-pager  --query "pipelines[].name"  --output text | tr '\t' '\n' | fzf
}

# get pipeline details
pd() {
    local pipeline_name
    if [ -z "$1" ]; then
        pipeline_name=$(pls)
    else
        pipeline_name="$1"
    fi
    aws codepipeline get-pipeline-state --name "$pipeline_name" \
    --profile $AWS_PROFILE --no-cli-pager \
    --query "stageStates[].{Stage: stageName, Status: latestExecution.status, actions: actionStates[].{Name: actionName, Status: latestExecution.status, id: latestExecution.externalExecutionId, summary: latestExecution.summary}}"
}

# get short pipeline details. Only status of the actions per stage
psd() {
    local pipeline_name
    if [ -z "$1" ]; then
        pipeline_name=$(pls)
    else
        pipeline_name="$1"
    fi
    aws codepipeline get-pipeline-state --name "$pipeline_name" \
    --profile $AWS_PROFILE --no-cli-pager \
    --query "stageStates[].{Stage: stageName, Status: latestExecution.status}" --output table
}

pipelineLogs() {
    local pipeline_id
    if [ -z "$1" ]; then
        pipeline_id=$(pls | xargs -I {} pd {} | jq -r '.[].actions[].id' | fzf)
    else
        pipeline_id="$1"
    fi

    echo "Fetching logs for pipeline: $pipeline_id"
    LOG_INFO=$(aws codebuild batch-get-builds \
        --ids "$pipeline_id" \
        --query "builds[].{logs: logs.{groupName: groupName, streamName: streamName}}" \
        --profile $AWS_PROFILE \
        --no-cli-pager) 

    echo "Log info: $LOG_INFO"
    LOG_GROUP=$(echo "$LOG_INFO" | jq -r '.[0].logs.groupName')
    LOG_STREAM=$(echo "$LOG_INFO" | jq -r '.[0].logs.streamName')

    aws logs get-log-events \
    --log-group-name "${LOG_GROUP}" \
    --log-stream-name "${LOG_STREAM}" \
    --profile $AWS_PROFILE \
    --query "events[*].message"  \
    --no-cli-pager --output text \
     --output json | jq -r '.[]' | \

        awk '
        BEGIN{RS=""} {gsub(/\n/, " ", $0)}
        /error/   { print "\033[1;31m" $0 "\033[0m"; next }
        /ERROR/   { print "\033[1;31m" $0 "\033[0m"; next }
        /WARN/    { print "\033[1;33m" $0 "\033[0m"; next }
        /INFO/    { print "\033[1;32m" $0 "\033[0m"; next }
                    { print $0 }' | \
        sed 's/[\r\n]*$//' 
}

# This function is used to tail logs from a specific log group and stream
tailLogs() {
    LOG_GROUP="$1"

    LOG_INFO=$(aws codebuild batch-get-builds \
        --ids "$1" \
        --query "builds[].{logs: logs.{groupName: groupName, streamName: streamName}}" \
        --profile $AWS_PROFILE \
        --no-cli-pager) 

    LOG_GROUP=$(echo "$LOG_INFO" | jq -r '.[0].logs.groupName')
    LOG_STREAM=$(echo "$LOG_INFO" | jq -r '.[0].logs.streamName')

    aws logs tail "$LOG_GROUP" \
        --log-stream-name-prefix "$LOG_STREAM" \
        --follow \
        --profile dta
}


# tail lambda logs
tll() {
    # tail the logs
    aws logs tail "/aws/lambda/$(aws lambda list-functions \
            --query 'Functions[*].FunctionName' --output text \
            --profile $AWS_PROFILE --no-cli-pager | tr '\t' '\n' | fzf)" \
        --follow \
        --profile $AWS_PROFILE

}

tpl() {        
    local pipeline_name
    if [ -z "$1" ]; then
        pipeline_name=$(pls)
    else
        pipeline_name="$1"
    fi
    local pipeline_id
    pipeline_id=$(pd "$pipeline_name" | jq -r '.[].actions[].id' | fzf)
    tailLogs "$pipeline_id"
}

#Read pipeline logs
rpl() {
    local pipeline_name
    if [ -z "$1" ]; then
        pipeline_name=$(pls)
    else
        pipeline_name="$1"
    fi
    local pipeline_id
    pipeline_id=$(pd "$pipeline_name" | jq -r '.[].actions[].id' | fzf)
    pipelineLogs "$pipeline_id"
}

#Tail logs for choosen log group
tl() {
    local log_group
    log_group=$(aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output text --profile $AWS_PROFILE | tr '\t' '\n' | fzf)
    if [ -z "$log_group" ]; then
        echo "No log group selected."
        return 1
    fi
    aws logs tail "$log_group" --follow --profile $AWS_PROFILE
}


# read logs for choosen log group
rl() {
    local log_group
    log_group=$(aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output text --profile $AWS_PROFILE | tr '\t' '\n' | fzf)
    if [ -z "$log_group" ]; then
        echo "No log group selected."
        return 1
    fi
    echo "Selected log group: $log_group"

    local log_stream
    log_stream=$(aws logs describe-log-streams --log-group-name "$log_group" --order-by LastEventTime --descending --query 'logStreams[*].logStreamName' --output text --profile $AWS_PROFILE | tr '\t' '\n' | fzf)
    if [ -z "$log_stream" ]; then
        echo "No log stream selected."
        return 1
    fi
    echo "Selected log stream: $log_stream"

    # Debugging timestamps

    # Fetching logs with time range and query for messages, adding color for errors and warnings, and piping to less
    aws logs get-log-events \
        --log-group-name "$log_group" \
        --log-stream-name "$log_stream" \
        --query 'events[*].message' \
        --output text \
        --profile $AWS_PROFILE | awk '
        /error/   { print "\033[1;31m" $0 "\033[0m"; next } # Red for errors
        /ERROR/   { print "\033[1;31m" $0 "\033[0m"; next }
        /warn/    { print "\033[1;33m" $0 "\033[0m"; next } # Orange for warnings
        /WARN/    { print "\033[1;33m" $0 "\033[0m"; next }
                    { print $0 }' | less -R
}