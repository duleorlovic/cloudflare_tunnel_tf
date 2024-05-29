# Create lxd container and install cloudflared tunnel using ansible

Based on
https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deploy-tunnels/deployment-guides/ansible/

On LXC machine create a folder
```
ssh lxd-mashine
mkdir lxc
cd lxc
# clone under different name
git clone git@github.com:duleorlovic/cloudflare_tunnel_tf.git my-app
cd my-app_cloudflared_tunnel_tf
```

Create `terraform.tfvars`
```
# terraform.tfvars
# https://developers.cloudflare.com/fundamentals/api/get-started/create-token/ with Cloudflare Tunnel and DNS permissions.
# My Profile > Api Tokens > Permissions >
#   Account: Cloudflare Tunnel: Edit
#   Zone: DNS: Edit
# you can filter limit specific resources if needed
cloudflare_zone           = "trk.in.rs"
cloudflare_zone_id        = "asd..."
cloudflare_account_id     = "asd..."
cloudflare_email          = "email@..."
cloudflare_token          = "asd..."

# this is also used for dns and tunnel ingress hostname so use only alphanumeric
# and hyphens, for my-app it will create two entries:
# my-app.trk.in.rs
# ssh-my-app.trk.in.rs
lxd_container_name        = "my-app"
```

Run terraform
```
terraform init

ssh-keygen -f my-key

TF_VAR_created_by="$(whoami)@$(hostname):$(pwd)" terraform plan
TF_VAR_created_by="$(whoami)@$(hostname):$(pwd)" terraform apply -auto-approve
```

Delete machine
```
terraform destroy -auto-approve
```

## Test connection from remote machine

From machine you want to ssh you need to install `brew install cloudflared` tool
and configure ssh to use it
```
# .ssh/config
# https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/use-cases/ssh/
Host ssh-my-app.trk.in.rs
  ProxyCommand $(brew --prefix)/bin/cloudflared access ssh --hostname %h
```
In your project create deploy folder
```
mkdir deploy
cd deploy

cat > .gitignore << HERE_DOC
my-key
my-key.pub
HERE_DOC

# download keys `my-key` and `my-key.pub`
scp lxd-mashine:lxc/my-app_cloudflared_tunnel_tf/my-key*  .

ssh-add my-key
```

and connect with
```
ssh ubuntu@ssh-my-app.trk.in.rs
```

Create ansible files
```
# inventory
[default]
ssh-my-app.trk.in.rs ansible_user=ubuntu

# ansible.cfg
[defaults]
inventory = inventory
```
and test connection
```
ansible all -m ping
```

## Debug

Test connection from lxd host using output command
```
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i 10.89.228.210, playbook.yml

# or this generic command
ssh ubuntu@"$(get_container_ip my-app)" cat .ssh/authorized_keys
```

Debug tunnel with
```
lxc shell my-app
service cloudflared start
systemctl status cloudflared
tail /var/log/cloudflared.log
```
Debug ansible with
```
terraform output ansible_playbook_command
```

## Deploy app using ansible from remote machine
