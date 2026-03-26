#!/bin/bash
REGION="${1:-us-east-1}"

echo "# AWS Glue - Catalog Databases"
aws glue get-databases --region "$REGION" \
  --query 'DatabaseList[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r db; do
  [ -z "$db" ] && continue
  echo "  database: $db"
done

echo ""
echo "# AWS Glue - Crawlers"
aws glue get-crawlers --region "$REGION" \
  --query 'Crawlers[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  [ -z "$name" ] && continue
  echo "  crawler: $name"
done

echo ""
echo "# AWS Glue - Jobs"
aws glue get-jobs --region "$REGION" \
  --query 'Jobs[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  [ -z "$name" ] && continue
  echo "  job: $name"
done

echo ""
echo "# AWS Glue - Triggers"
aws glue get-triggers --region "$REGION" \
  --query 'Triggers[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  [ -z "$name" ] && continue
  echo "  trigger: $name"
done

echo ""
echo "# AWS Glue - Connections"
aws glue get-connections --region "$REGION" \
  --query 'ConnectionList[].Name' --output text 2>/dev/null | tr '\t' '\n' | while read -r name; do
  [ -z "$name" ] && continue
  echo "  connection: $name"
done
