# Read pipeline executions states
ple() {
    CACHE_DIR="$HOME/.cache/.myfunctions"
    CACHE_FILE="$CACHE_DIR/pipeline_list.txt"
    REFRESH=0

    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Check for -r flag
    if [ "$1" = "-r" ]; then
        REFRESH=1
        shift
    fi

    # Refresh cache if needed or if cache doesn't exist
    if [ $REFRESH -eq 1 ] || [ ! -f "$CACHE_FILE" ]; then
        aws codepipeline list-pipelines --profile dta --query 'pipelines[*].name' --output text | tr '\t' '\n' > "$CACHE_FILE"
    fi

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
    aws codepipeline list-pipeline-executions \
        --pipeline-name "$pipeline_name" \
        --profile dta \
        --no-cli-pager \
        --query 'pipelineExecutionSummaries[].{ExecutionId: pipelineExecutionId, Status: status, StartTime: startTime, LastUpdate: lastUpdateTime}' \
        --output table | fzf --prompt="Select execution for $pipeline_name: "
}

#Read pipeline logs
rpl() {
    CACHE_DIR="$HOME/.cache/.myfunctions"
    CACHE_FILE="$CACHE_DIR/pipeline_list.txt"
    REFRESH=0

    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Check for -r flag
    if [ "$1" = "-r" ]; then
        REFRESH=1
        shift
    fi

    # Refresh cache if needed or if cache doesn't exist
    if [ $REFRESH -eq 1 ] || [ ! -f "$CACHE_FILE" ]; then
        aws codepipeline list-pipelines --profile dta --query 'pipelines[*].name' --output text | tr '\t' '\n' > "$CACHE_FILE"
    fi

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
    pipelineLogs "$pipeline_id"
}

tpl() {
    CACHE_DIR="$HOME/.cache/.myfunctions"
    CACHE_FILE="$CACHE_DIR/pipeline_list.txt"
    REFRESH=0

    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Check for -r flag
    if [ "$1" = "-r" ]; then
        REFRESH=1
        shift
    fi

    # Refresh cache if needed or if cache doesn't exist
    if [ $REFRESH -eq 1 ] || [ ! -f "$CACHE_FILE" ]; then
        aws codepipeline list-pipelines --profile dta --query 'pipelines[*].name' --output text | tr '\t' '\n' > "$CACHE_FILE"
    fi

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