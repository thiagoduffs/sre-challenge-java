#!/bin/bash
# Route53 e global

echo "# Route53 Hosted Zones"
aws route53 list-hosted-zones \
  --query 'HostedZones[].[Id,Name,Config.PrivateZone]' \
  --output text 2>/dev/null | while read -r id name private; do
  [ -z "$id" ] && continue
  zone_id=$(echo "$id" | sed 's|/hostedzone/||')
  echo "  zone: $zone_id  name=$name  private=$private"

  echo "  Records:"
  aws route53 list-resource-record-sets --hosted-zone-id "$zone_id" \
    --query 'ResourceRecordSets[].[Name,Type]' \
    --output text 2>/dev/null | while read -r rname rtype; do
    echo "    record: ${rname}  type=$rtype"
  done
  echo ""
done
