resource "template_file" "user_data" {
  template = <<EOF
#!/bin/bash
set -eo pipefail

echo ECS_CLUSTER=${aws_ecs_cluster.ecs.name} > /etc/ecs/ecs.config

yum -y update
yum install -y aws-cli
yum install -y jq

REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
VOLUME_ID=${aws_ebs_volume.factorio.id}
aws ec2 attach-volume \
  --volume-id $VOLUME_ID \
  --instance-id $INSTANCE_ID \
  --region $REGION \
  --device /dev/xvdh

# Wait for the volume to be attached
while [ ! -e /dev/xvdh ]; do sleep 1; done

file -s /dev/xvdh | grep ext4 || mkfs -t ext4 /dev/xvdh
mkdir /data
mount /dev/xvdh /data
echo "/dev/xvdh /data ext4 defaults,nofail 0 2" >> /etc/fstab

# docker restart doesn't work sometimes...
for i in {1..5}; do
  service docker restart && break || sleep 15
done

PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

any_records() {
  curl  -H 'X-DNSimple-Token: ${var.dnsimple_token}' \
        -H 'Accept: application/json' \
        https://api.dnsimple.com/v1/domains/${var.domain}/records\?name=${var.subdomain} | jq -e 'any'
}

update_record() {
  recordid = $(curl  -H 'X-DNSimple-Token: ${var.dnsimple_token}' \
        -H 'Accept: application/json' \
        https://api.dnsimple.com/v1/domains/${var.domain}/records\?name=${var.subdomain} | jq -r -e '.[0].record.id')

  curl  -H 'X-DNSimple-Token: ${var.dnsimple_token}' \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -X PUT \
        -d '{
          "record": {
            "name": "${var.subdomain}",
            "record_type": "A",
            "content": "'"$PUBLIC_IP"'",
            "ttl": 60,
            "prio": 10
          }
        }' \
        https://api.dnsimple.com/v1/domains/example.com/records/$recordid
}

add_record() {
  curl  -H 'X-DNSimple-Token: ${var.dnsimple_token}' \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -X POST \
        -d '{
          "record": {
            "name": "${var.subdomain}",
            "record_type": "A",
            "content": "'"$PUBLIC_IP"'",
            "ttl": 60,
            "prio": 10
          }
        }' \
        https://api.dnsimple.com/v1/domains/${var.domain}/records
}

if any_records; then
  update_record
else
  add_record
end

EOF
}
