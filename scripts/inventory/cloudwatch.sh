#!/bin/bash
REGION="${1:-us-east-1}"

echo "# CloudWatch Log Groups"
aws logs describe-log-groups --region "$REGION" \
  --query 'logGroups[].[logGroupName,retentionInDays,storedBytes]' \
  --output text 2>/dev/null | while read -r name retention bytes; do
  [ -z "$name" ] && continue
  echo "  log-group: $name  retention=$retention  bytes=$bytes"
done

echo ""
echo "# CloudWatch Alarms"
aws cloudwatch describe-alarms --region "$REGION" \
  --query 'MetricAlarms[].[AlarmName,MetricName,Namespace,StateValue]' \
  --output text 2>/dev/null | while read -r name metric ns state; do
  [ -z "$name" ] && continue
  echo "  alarm: $name  metric=$metric  namespace=$ns  state=$state"
done
