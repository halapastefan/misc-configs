
get_pipelines() {
    aws codepipeline list-pipelines --profile dta --no-cli-pager  --query "pipelines[].name"  --output text | tr '\t' '\n' | fzf
}


# Get pipline state
aws codepipeline get-pipeline-state --name $(aws codepipeline list-pipelines --profile dta --no-cli-pager  --query "pipelines[].name"  --output text | tr '\t' '\n' | fzf) \
  --profile dta --no-cli-pager \
  --query "stageStates[].{Stage: stageName, Status: latestExecution.status,  actions: actionStates[].{Name: actionName, Status: latestExecution.status, id: latestExecution.externalExecutionId}}"

# GEt log group
aws codepipeline get-pipeline-state --name $(aws codepipeline list-pipelines --profile dta --no-cli-pager  --query "pipelines[].name"  --output text | tr '\t' '\n' | fzf) \
  --profile dta --no-cli-pager \
  --query "stageStates[].{actions: actionStates[].{id: latestExecution.externalExecutionId}}"  | tr '\t' '\n' 

# tail logs

aws logs tail "$LOG_GROUP" \
        --log-stream-name-prefix "$LOG_STREAM" \
        --follow \
        --profile dta
}