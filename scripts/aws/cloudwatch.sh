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