CACHE_DIR="$HOME/.cache/functions/aws/$(get_active_profile)"
PIPELINE_CACHE_FILE="$CACHE_DIR/pipeline_list.txt"

pl_help() {
    cat <<EOF
Supported operations in pipeline.sh:

pd [pipeline_name]        - Get pipeline details (select with fzf if not provided)
ple [pipeline_name]       - List pipeline executions (select with fzf if not provided)
rpl [pipeline_name]       - Read pipeline logs (select with fzf if not provided)
tpl [pipeline_name]       - Tail logs for a specific pipeline action (select with fzf if not provided)
pipeline_help             - Show this help message

You can also use TAB completion for pipeline names.
EOF
}
# get pipeline details
pd() {
    if [ -z "$1" ]; then
        local pipeline_name
        pipeline_name=$(cat "$PIPELINE_CACHE_FILE" | fzf --prompt="Select pipeline: ")
    else
        pipeline_name="$1"
    fi
    if [ -z "$pipeline_name" ]; then
        echo "No pipeline selected."
        return 1
    fi
    aws codepipeline get-pipeline-state --name "$pipeline_name" \
        --profile $(get_active_profile) --no-cli-pager \
        --query "stageStates[].{Stage: stageName, Status: latestExecution.status, actions: actionStates[].{Name: actionName, Status: latestExecution.status, id: latestExecution.externalExecutionId, summary: latestExecution.summary}}"
}

_pd_completion() {
    if [[ -f "$PIPELINE_CACHE_FILE" ]]; then
        compadd -- $(cat "$PIPELINE_CACHE_FILE")
    fi
}
compdef _pd_completion pd

# Read pipeline executions states
# Usage: ple pipeline_name or just ple to select from list
ple() {
    if [ -z "$1" ]; then
        local pipeline_name
        pipeline_name=$(cat "$PIPELINE_CACHE_FILE" | fzf --prompt="Select pipeline: ")
    else
        pipeline_name="$1"
    fi
    if [ -z "$pipeline_name" ]; then
        echo "No pipeline selected."
        return 1
    fi
    aws codepipeline list-pipeline-executions \
        --pipeline-name "$pipeline_name" \
        --profile dta \
        --no-cli-pager \
        --query 'pipelineExecutionSummaries[].{ExecutionId: pipelineExecutionId, Status: status, StartTime: startTime, LastUpdate: lastUpdateTime}' \
        --output table | fzf --prompt="Select execution for $pipeline_name: "
}

_ple_completion() {
    if [[ -f "$PIPELINE_CACHE_FILE" ]]; then
        compadd -- $(cat "$PIPELINE_CACHE_FILE")
    fi
}
compdef _ple_completion ple

# Read pipeline logs
# Usage: rpl pipeline_name or just rpl to select from list
rpl() {
    local pipeline_name
    if [ -z "$1" ]; then
        pipeline_name=$(cat "$PIPELINE_CACHE_FILE" | fzf --prompt="Select pipeline: ")
    else
        pipeline_name="$1"
    fi
    if [ -z "$pipeline_name" ]; then
        echo "No pipeline selected."
        return 1
    fi
    local pipeline_id
    pipeline_id=$(pd "$pipeline_name" | jq -r '.[].actions[].id' | fzf)
    pipelineLogs "$pipeline_id"
}

_rpl_completion() {
    if [[ -f "$PIPELINE_CACHE_FILE" ]]; then
        compadd -- $(cat "$PIPELINE_CACHE_FILE")
    fi
}
compdef _rpl_completion rpl

# Tail logs for a specific pipeline action
# Usage: tpl pipeline_name or just tpl to select from list
tpl() {
    local pipeline_name
    if [ -z "$1" ]; then
        pipeline_name=$(cat "$CACHE_FILE" | fzf --prompt="Select pipeline: ")
    else
        pipeline_name="$1"
    fi
    if [ -z "$pipeline_name" ]; then
        echo "No pipeline selected."
        return 1
    fi
    local pipeline_id
    pipeline_id=$(pd "$pipeline_name" | jq -r '.[].actions[].id' | fzf)
    tailLogs "$pipeline_id"
}

_pipeline_name_completion() {
    if [[ -f "$PIPELINE_CACHE_FILE" ]]; then
        compadd -- $(cat "$PIPELINE_CACHE_FILE")
    fi
}
compdef _pipeline_name_completion pd
compdef _pipeline_name_completion ple
compdef _pipeline_name_completion rpl
compdef _pipeline_name_completion tpl

##########################################################
############# Helper functions for pipelines #############
##########################################################

# This function is used to tail logs from a specific log group and stream
tailLogs() {
    LOG_GROUP="$1"

    LOG_INFO=$(aws codebuild batch-get-builds \
        --ids "$1" \
        --query "builds[].{logs: logs.{groupName: groupName, streamName: streamName}}" \
        --profile $(get_active_profile) \
        --no-cli-pager)

    LOG_GROUP=$(echo "$LOG_INFO" | jq -r '.[0].logs.groupName')
    LOG_STREAM=$(echo "$LOG_INFO" | jq -r '.[0].logs.streamName')

    aws logs tail "$LOG_GROUP" \
        --log-stream-name-prefix "$LOG_STREAM" \
        --follow \
        --profile dta
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
        --profile $(get_active_profile) \
        --no-cli-pager)

    echo "Log info: $LOG_INFO"
    LOG_GROUP=$(echo "$LOG_INFO" | jq -r '.[0].logs.groupName')
    LOG_STREAM=$(echo "$LOG_INFO" | jq -r '.[0].logs.streamName')

    aws logs get-log-events \
        --log-group-name "${LOG_GROUP}" \
        --log-stream-name "${LOG_STREAM}" \
        --profile $(get_active_profile) \
        --query "events[*].message" \
        --no-cli-pager --output text \
        --output json | jq -r '.[]' |
        awk '
        BEGIN{RS=""} {gsub(/\n/, " ", $0)}
        /error/   { print "\033[1;31m" $0 "\033[0m"; next }
        /ERROR/   { print "\033[1;31m" $0 "\033[0m"; next }
        /WARN/    { print "\033[1;33m" $0 "\033[0m"; next }
        /INFO/    { print "\033[1;32m" $0 "\033[0m"; next }
                    { print $0 }' |
        sed 's/[\r\n]*$//'
}

# Get the latest pipeline state
# usage: pipeline <pipeline-name> <stage-name>
pipeline() {
    aws codepipeline get-pipeline-state --name "$1"-"$2"-pipeline \
        --query "stageStates[].{Stage: stageName, Status: latestExecution.status}" \
        --output table --profile $(get_active_profile) --no-cli-pager
}

# Pipeline list
pls() {
    aws codepipeline list-pipelines --profile $(get_active_profile) --no-cli-pager --query "pipelines[].name" --output text | tr '\t' '\n' | fzf
}
