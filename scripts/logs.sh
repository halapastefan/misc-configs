#!/bin/bash

pipelineLogs() {
    PIPELINE_NAME="$1"

    # Step 1: Get latest pipeline execution ID
    EXECUTION_ID=$(aws codepipeline list-pipeline-executions \
        --pipeline-name "$PIPELINE_NAME" \
        --max-items 1 \
        --query "pipelineExecutionSummaries[0].pipelineExecutionId" \
        --output text)

        

    echo "Latest execution ID: $EXECUTION_ID"

    # Step 2: Get execution details
    ACTION_EXECUTION_ID=$(aws codepipeline get-pipeline-execution \
        --pipeline-name "$PIPELINE_NAME" \
        --pipeline-execution-id "$EXECUTION_ID" \
        --query "pipelineExecution.artifactRevisions[0].revisionId" \
        --output text)

    # Step 3: Find CodeBuild execution ID
    BUILD_ID=$(aws codepipeline get-pipeline-execution \
        --pipeline-name "$PIPELINE_NAME" \
        --pipeline-execution-id "$EXECUTION_ID" \
        --query "pipelineExecution.stageStates[].actionStates[].latestExecution.externalExecutionId" \
        --output text | grep build)

    if [[ -z "$BUILD_ID" ]]; then
    echo "❌ No CodeBuild execution found in this pipeline execution."
    exit 1
    fi

    echo "CodeBuild build ID: $BUILD_ID"

    # Step 4: Get CodeBuild log info
    LOG_INFO=$(aws codebuild batch-get-builds --ids "$BUILD_ID")

    LOG_GROUP=$(echo "$LOG_INFO" | jq -r '.builds[0].logs.groupName')
    LOG_STREAM=$(echo "$LOG_INFO" | jq -r '.builds[0].logs.streamName')
    DEEP_LINK=$(echo "$LOG_INFO" | jq -r '.builds[0].logs.deepLink')

    echo "Log group: $LOG_GROUP"
    echo "Log stream: $LOG_STREAM"
    echo "CloudWatch link: $DEEP_LINK"

    # Step 5: Get last 100 log lines from CloudWatch
    echo
    echo "Fetching latest logs:"
    aws logs get-log-events \
        --log-group-name "$LOG_GROUP" \
        --log-stream-name "$LOG_STREAM" \
        --limit 100 \
        --query "events[*].message" \
        --output text
}
# Set your pipeline name

