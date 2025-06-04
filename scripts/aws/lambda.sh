


# Select Lambda function with fzf and show config in preview
lambdaDetails() {
    aws lambda list-functions --profile dta --query 'Functions[*].FunctionName' --output text | tr '\t' '\n' | \
    fzf --preview '
    aws lambda get-function-configuration --profile dta --function-name {} | jq
    ' --preview-window=right:90% --height 100%
}