#!/bin/bash
REGION="${1:-us-east-1}"

echo "# VPCs"
aws ec2 describe-vpcs --region "$REGION" \
  --query 'Vpcs[].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock,IsDefault]' \
  --output text 2>/dev/null | while read -r id name cidr default; do
  [ -z "$id" ] && continue
  echo "  vpc: $id  name=$name  cidr=$cidr  default=$default"
done

echo ""
echo "# Subnets"
aws ec2 describe-subnets --region "$REGION" \
  --query 'Subnets[].[SubnetId,Tags[?Key==`Name`].Value|[0],CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
  --output text 2>/dev/null | while read -r id name cidr az public; do
  [ -z "$id" ] && continue
  echo "  subnet: $id  name=$name  cidr=$cidr  az=$az  public=$public"
done

echo ""
echo "# Internet Gateways"
aws ec2 describe-internet-gateways --region "$REGION" \
  --query 'InternetGateways[].[InternetGatewayId,Tags[?Key==`Name`].Value|[0],Attachments[0].VpcId]' \
  --output text 2>/dev/null | while read -r id name vpc; do
  [ -z "$id" ] && continue
  echo "  igw: $id  name=$name  vpc=$vpc"
done

echo ""
echo "# NAT Gateways"
aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=state,Values=available" \
  --query 'NatGateways[].[NatGatewayId,Tags[?Key==`Name`].Value|[0],SubnetId,State]' \
  --output text 2>/dev/null | while read -r id name subnet state; do
  [ -z "$id" ] && continue
  echo "  nat: $id  name=$name  subnet=$subnet  state=$state"
done

echo ""
echo "# Route Tables"
aws ec2 describe-route-tables --region "$REGION" \
  --query 'RouteTables[].[RouteTableId,Tags[?Key==`Name`].Value|[0],VpcId]' \
  --output text 2>/dev/null | while read -r id name vpc; do
  [ -z "$id" ] && continue
  echo "  rtb: $id  name=$name  vpc=$vpc"
done

echo ""
echo "# Elastic IPs"
aws ec2 describe-addresses --region "$REGION" \
  --query 'Addresses[].[AllocationId,PublicIp,Tags[?Key==`Name`].Value|[0],InstanceId]' \
  --output text 2>/dev/null | while read -r id ip name instance; do
  [ -z "$id" ] && continue
  echo "  eip: $id  ip=$ip  name=$name  instance=$instance"
done
