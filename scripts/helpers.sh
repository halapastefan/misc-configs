aws codepipeline list-pipeline-executions \
  --pipeline-name assist-dev-pipeline \
  --query "pipelineExecutionSummaries[].{id: pipelineExecutionId, status: status}" \
  --max-items 5 --profile dta \
  --no-cli-pager

# this is to get latest pipeline with stage and actions and id
aws codepipeline get-pipeline-state --name assist-dev-pipeline \
  --profile dta --no-cli-pager \
  --query "stageStates[].{Stage: stageName, Status: latestExecution.status,  actions: actionStates[].{Name: actionName, Status: latestExecution.status, id: latestExecution.externalExecutionId}}"

aws codepipeline get-pipeline-state --name assist-dev-pipeline \
  --profile dta --no-cli-pager \
  --query "stageStates[]}"

aws codebuild batch-get-builds \
  --ids assist-be-deploy-dev:135c8fe3-3883-4341-a36a-e646eaddccd8 \
  --query "builds[].{logs: logs.{groupName: groupName, streamName: streamName}}" \
  --profile dta \
  --no-cli-pager 

aws logs get-log-events \
    --log-group-name "/aws/codebuild/assist-be-deploy-dev" \
    --log-stream-name "135c8fe3-3883-4341-a36a-e646eaddccd8" \
    --profile dta \
    --query "events[*].message"  \
    --no-cli-pager --output text \
     --output json | jq -r '.[]' | \

        awk '
        BEGIN{RS=""} {gsub(/\n/, " ", $0)}
        /error/   { print "\033[1;31m" $0 "\033[0m"; next }
        /ERROR/   { print "\033[1;31m" $0 "\033[0m"; next }
        /WARN/    { print "\033[1;33m" $0 "\033[0m"; next }
        /INFO/    { print "\033[1;32m" $0 "\033[0m"; next }
                    { print $0 }' | \
        sed 's/[\r\n]*$//' 

aws codepipeline get-pipeline-execution \
  --pipeline-name assist-dev-pipeline \
  --profile dta \
  --pipeline-execution-id 

# get lambdas
aws lambda list-functions \
  --query 'Functions[?contains(FunctionName, `ehr-sync`)].FunctionName' \
  --output json --profile dta  --no-cli-pager

aws lambda list-functions --query 'Functions[*].FunctionName' --output text \
  --profile dta  --no-cli-pager | tr '\t' '\n'| fzf


aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/incision-assist-backend-ehr-sync-dev-ehr-sync" \
  --output json --profile dta  --no-cli-pager

aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/$(aws lambda list-functions \
    --query 'Functions[*].FunctionName' --output text \
    --profile dta --no-cli-pager | tr '\t' '\n' | fzf)" \
  --output json --profile dta --no-cli-pager

aws logs filter-log-events \
  --log-group-name "/aws/lambda/$(aws lambda list-functions \
    --query 'Functions[*].FunctionName' --output text \
    --profile dta --no-cli-pager | tr '\t' '\n' | fzf)" \
  --output text --profile dta --no-cli-pager\
   --query "events[*].message"  \
  --limit 100