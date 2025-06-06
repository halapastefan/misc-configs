CACHE_DIR="$HOME/.cache/functions/aws/$(get_active_profile)"
LAMBDA_CACHE_FILE="$CACHE_DIR/lambda_list.txt"

# Select Lambda function with fzf and show config in preview
lambdaDetails() {
    local profile selected_lambda
    profile="$(get_active_profile)"

    if [ -z "$1" ]; then
        selected_lambda=$(cat "$LAMBDA_CACHE_FILE" |
            fzf --preview "
            aws lambda get-function-configuration --profile \"$profile\" --function-name {} | jq \".\" | bat --language json --style=plain --paging=never --color=always
        " --preview-window=right:60% --height 100%)
    else
        selected_lambda="$1"
    fi

    if [ -n "$selected_lambda" ]; then
        aws lambda get-function-configuration --profile "$profile" --function-name "$selected_lambda" | jq "."
    fi
}

# tail lambda logs
tll() {
    local lambda_name
    if [ -z "$1" ]; then
        lambda_name=$(cat "$LAMBDA_CACHE_FILE" | fzf --prompt="Select Lambda function: ")
    else
        lambda_name="$1"
    fi
    if [ -z "$lambda_name" ]; then
        echo "No pipeline selected."
        return 1
    fi

    # tail the logs
    aws logs tail "$lambda_name" \
        --follow --profile "$(get_active_profile)"
}

_lambda_completion() {
    if [[ -f "$LAMBDA_CACHE_FILE" ]]; then
        compadd -- $(cat "$LAMBDA_CACHE_FILE")
    fi
}
compdef _lambda_completion lambdaDetails
compdef _lambda_completion tll
