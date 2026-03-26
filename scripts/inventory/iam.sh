#!/bin/bash
# IAM e global, nao usa --region

echo "# IAM Roles (custom - excluindo AWS service-linked e aws-reserved)"
aws iam list-roles \
  --query 'Roles[?starts_with(RoleName, `AWS`) == `false` && starts_with(Path, `/aws-`) == `false`].[RoleName,Path,CreateDate]' \
  --output text 2>/dev/null | while read -r name path created; do
  [ -z "$name" ] && continue
  echo "  role: $name  path=$path  created=$created"
done

echo ""
echo "# IAM Policies (custom - somente local/account)"
aws iam list-policies --scope Local \
  --query 'Policies[].[PolicyName,Arn]' \
  --output text 2>/dev/null | while read -r name arn; do
  [ -z "$name" ] && continue
  echo "  policy: $name"
  echo "          arn=$arn"
done

echo ""
echo "# IAM Instance Profiles"
aws iam list-instance-profiles \
  --query 'InstanceProfiles[].[InstanceProfileName,Roles[0].RoleName]' \
  --output text 2>/dev/null | while read -r name role; do
  [ -z "$name" ] && continue
  echo "  instance-profile: $name  role=$role"
done
