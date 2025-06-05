#!/bin/bash

# Select CloudFormation stack with fzf and show details in preview

cloudformation() {
  aws cloudformation list-stacks --profile dta \
  --query "StackSummaries[?StackStatus!='DELETE_COMPLETE'].StackName" \
  --output text | tr '\t' '\n' | \
    fzf --preview '
      aws cloudformation describe-stacks --profile dta --stack-name {} | jq ".Stacks[0]" | jq "." | bat --language json --style=plain --paging=never --color=always
    ' --preview-window=right:70% --height 100% 

}