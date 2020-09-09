#!/bin/bash

# Description:
#  Keeps EC2 instance dns up to date across deploys  / instance replacement
#  This script checks on boot if the private ipv4 ip matches the dns records
#  vs the ipv4 from the ec2 metadata and if not, it makes a upsert request
# Dependencies:
#  Requires curl, dig, aws-cli and a role to allow route53 requests
# Installation:
#  Place in /etc/rc.local and ensure rc.local and the script has executable permissions
#  Rename myinstance to your instance name, kept static in the actions to avoid
#  accidental issues

my_hostname="myinstance-prod-ec2-instance"
r53_hostedzone="mydomain.com"
ec2_private_ip=$(curl -fs http://169.254.169.254/latest/meta-data/local-ipv4)
r53_hostedzone_id=$(aws route53 list-hosted-zones-by-name --dns-name "${r53_hostedzone}" --query 'HostedZones[0].Id' | cut -d / -f 3 | tr -d '"')
tmp_file=/tmp/record.json

update_dns(){
cat << EOF > /tmp/record.json
{
  "Comment": "Update the A record set",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "myinstance-prod-ec2-instance.mydomain.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "${ec2_private_ip}"
          }
        ]
      }
    }
  ]
}
EOF

sleep 1

aws route53 change-resource-record-sets --hosted-zone-id "${r53_hostedzone_id}" --change-batch file:///tmp/record.json
echo "DNS Updated for: ${my_hostname}.${r53_hostedzone} to: ${ec2_private_ip}"
}

if [ "$(dig a myinstance-prod-ec2-instance.mydomain.com +short)" == $(curl -fs http://169.254.169.254/latest/meta-data/local-ipv4) ]
  then
    echo "its the same"
    echo "[$(date +%F)] no changes to dns" >> /var/log/dns_updater.log
    exit 0
  else
    echo "its not the same"
    echo "updating dns"
    update_dns
    rm -rf /tmp/record.json
    echo "[$(date +%F)] ip changed and dns was updated" >> /var/log/dns_updater.log
fi
