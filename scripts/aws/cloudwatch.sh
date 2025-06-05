CACHE_DIR="$HOME/.cache/functions/aws/$(get_active_profile)"
CACHE_FILE="$CACHE_DIR/log_group_list.txt"

#Tail logs for choosen log group
tl() {
    local log_group

    log_group=$(_select_log_group "$1")

    aws logs tail "$log_group" --follow --profile "$(get_active_profile)"
}

# read logs for choosen log group
rl() {
    local log_group
    log_group=$(_select_log_group "$1")

    local log_stream
    log_stream=$(aws logs describe-log-streams --log-group-name "$log_group" --order-by LastEventTime --descending --query 'logStreams[*].logStreamName' --output text --profile "$(get_active_profile)" | tr '\t' '\n' | fzf)
    if [ -z "$log_stream" ]; then
        echo "No log stream selected."
        return 1
    fi

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

_log_group_completion() {
    if [[ -f "$CACHE_FILE" ]]; then
        compadd -- $(cat "$CACHE_FILE")
    fi
}
compdef _log_group_completion tl
compdef _log_group_completion rl

_select_log_group() {
    local log_group

    if [ -z "$1" ]; then
        log_group=$(cat "$CACHE_FILE" | fzf --prompt="Select log group: ")
    else
        log_group="$1"
    fi

    if [ -z "$log_group" ]; then
        echo "No log group selected."
        return 1
    fi
    echo "$log_group"
}
