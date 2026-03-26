#!/bin/bash
REGION="${1:-us-east-1}"

echo "# RDS Instances"
aws rds describe-db-instances --region "$REGION" \
  --query 'DBInstances[].[DBInstanceIdentifier,Engine,EngineVersion,DBInstanceClass,DBInstanceStatus]' \
  --output text 2>/dev/null | while read -r id engine ver class status; do
  [ -z "$id" ] && continue
  echo "  rds: $id  engine=$engine  version=$ver  class=$class  status=$status"
done

echo ""
echo "# RDS Clusters (Aurora)"
aws rds describe-db-clusters --region "$REGION" \
  --query 'DBClusters[].[DBClusterIdentifier,Engine,EngineVersion,Status]' \
  --output text 2>/dev/null | while read -r id engine ver status; do
  [ -z "$id" ] && continue
  echo "  cluster: $id  engine=$engine  version=$ver  status=$status"
done

echo ""
echo "# RDS Subnet Groups"
aws rds describe-db-subnet-groups --region "$REGION" \
  --query 'DBSubnetGroups[].[DBSubnetGroupName,VpcId]' \
  --output text 2>/dev/null | while read -r name vpc; do
  [ -z "$name" ] && continue
  echo "  subnet-group: $name  vpc=$vpc"
done

echo ""
echo "# RDS Parameter Groups (custom)"
aws rds describe-db-parameter-groups --region "$REGION" \
  --query 'DBParameterGroups[?starts_with(DBParameterGroupName, `default.`) == `false`].[DBParameterGroupName,DBParameterGroupFamily]' \
  --output text 2>/dev/null | while read -r name family; do
  [ -z "$name" ] && continue
  echo "  param-group: $name  family=$family"
done
