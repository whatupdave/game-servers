# Game servers

## Table of Contents

- [Factorio](#factorio)

### Factorio

First you'll want to make an aws account. If you want ssh access to the instances make sure you create a key pair and then set the env var below.

```
brew update && brew install awscli   # install the aws cli

export TF_VAR_key_name=my_key        # if you want ssh access to instances
export TF_VAR_domain=mydomain        # domain registered in dnsimple
export TF_VAR_subdomain=factorio     # subdomain to point to server
export TF_VAR_dnsimple_token=me@email.com:token1234 # dnsimple token

cd terraform
terraform apply

# want mods?
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@factorio.mydomain.com
sudo curl -L "https://forums.factorio.com/download/file.php?id=9914" -o /data/factorio-mods/rso-mod_1.5.2.zip
```
