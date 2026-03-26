#!/bin/bash
REGION="${1:-us-east-1}"

echo "# EC2 Instances"
aws ec2 describe-instances --region "$REGION" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,InstanceType]' \
  --output text 2>/dev/null | while read -r id name state type; do
  [ -z "$id" ] && continue
  echo "  instance: $id  name=$name  state=$state  type=$type"
done

echo ""
echo "# Security Groups"
aws ec2 describe-security-groups --region "$REGION" \
  --query 'SecurityGroups[].[GroupId,GroupName,VpcId]' \
  --output text 2>/dev/null | while read -r id name vpc; do
  [ -z "$id" ] && continue
  echo "  sg: $id  name=$name  vpc=$vpc"
done

echo ""
echo "# ELBv2 (ALB/NLB)"
aws elbv2 describe-load-balancers --region "$REGION" \
  --query 'LoadBalancers[].[LoadBalancerArn,LoadBalancerName,Type]' \
  --output text 2>/dev/null | while read -r arn name type; do
  [ -z "$arn" ] && continue
  echo "  lb: name=$name  type=$type"
  echo "      arn=$arn"
done

echo ""
echo "# Target Groups"
aws elbv2 describe-target-groups --region "$REGION" \
  --query 'TargetGroups[].[TargetGroupArn,TargetGroupName,Protocol,Port]' \
  --output text 2>/dev/null | while read -r arn name proto port; do
  [ -z "$arn" ] && continue
  echo "  tg: name=$name  proto=$proto  port=$port"
  echo "      arn=$arn"
done

echo ""
echo "# Auto Scaling Groups"
aws autoscaling describe-auto-scaling-groups --region "$REGION" \
  --query 'AutoScalingGroups[].[AutoScalingGroupName,MinSize,MaxSize,DesiredCapacity]' \
  --output text 2>/dev/null | while read -r name min max desired; do
  [ -z "$name" ] && continue
  echo "  asg: $name  min=$min  max=$max  desired=$desired"
done

echo ""
echo "# Launch Templates"
aws ec2 describe-launch-templates --region "$REGION" \
  --query 'LaunchTemplates[].[LaunchTemplateId,LaunchTemplateName]' \
  --output text 2>/dev/null | while read -r id name; do
  [ -z "$id" ] && continue
  echo "  launch-template: $id  name=$name"
done
