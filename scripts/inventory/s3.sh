#!/bin/bash
# S3 e global, nao usa --region

echo "# S3 Buckets"
aws s3api list-buckets \
  --query 'Buckets[].[Name,CreationDate]' --output text 2>/dev/null | while read -r name created; do
  [ -z "$name" ] && continue
  echo "  bucket: $name  created=$created"
done
