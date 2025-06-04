
ple() {
    local pipeline_name
    if [ -z "$1" ]; then
        pipeline_name=$(pls)
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