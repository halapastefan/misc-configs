# invoke the lambda function
aws lambda invoke --function-name incision-assist-backend-ehr-sync-dev-ehr-sync output.json \
    --profile dta --no-cli-pager

# tail the logs
aws logs tail "/aws/lambda/$(aws lambda list-functions \
        --query 'Functions[*].FunctionName' --output text \
        --profile dta --no-cli-pager | tr '\t' '\n' | fzf)" \
    --follow \
    --profile dta

