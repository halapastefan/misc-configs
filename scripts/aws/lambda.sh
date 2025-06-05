# Select Lambda function with fzf and show config in preview
lambdaDetails() {
    CACHE_DIR="$HOME/.cache/.myfunctions"
    CACHE_FILE="$CACHE_DIR/lambda_list.txt"
    REFRESH=0

    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Check for -r flag
    if [[ "$1" == "-r" ]]; then
        REFRESH=1
    fi

    # Refresh cache if needed or if cache doesn't exist
    if [[ $REFRESH -eq 1 || ! -f "$CACHE_FILE" ]]; then
        aws lambda list-functions --profile dta --query 'Functions[*].FunctionName' --output text | tr '\t' '\n' > "$CACHE_FILE"
    fi

    cat "$CACHE_FILE" | \
    fzf --preview '
    aws lambda get-function-configuration --profile dta --function-name {} | jq
    ' --preview-window=right:60% --height 100%
}