# Create lxd container and install cloudflared tunnel using ansible

Based on
https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deploy-tunnels/deployment-guides/ansible/

Install terraform, lxd and ansible
```
# https://developer.hashicorp.com/terraform/install
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# https://documentation.ubuntu.com/lxd/en/latest/tutorial/first_steps/
sudo snap install lxd
lxd init --minimal

# https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
```

On LXC machine create a folder
```
ssh lxd-mashine
mkdir lxc
cd lxc
# clone under different name
git clone git@github.com:duleorlovic/cloudflare_tunnel_tf.git my-app_cloudflare_tunnel_tf
cd my-app_cloudflare_tunnel_tf
```

Create `terraform.tfvars`
```
# terraform.tfvars
# https://developers.cloudflare.com/fundamentals/api/get-started/create-token/ with Cloudflare Tunnel and DNS permissions.
# My Profile > Api Tokens > Create Token > Create Custom Token
# Name >
#  EDIT-THIS-computer-name
# Permissions >
#   Account: Cloudflare Tunnel: Edit
#   Zone: DNS: Edit
# you can filter limit specific resources if needed
# copy API token and put to EDIT-THIS-api-token
cloudflare_zone           = "trk.in.rs"
# find zone id when you go websites and click on your domain and scroll down
cloudflare_zone_id        = "EDIT-THIS-zone-id"
# find account id in url eg https://dash.cloudflare.com/123-this-is-account-id
cloudflare_account_id     = "EDIT-THIS-account-id"
cloudflare_email          = "EDIT-THIS-email@example.com"
cloudflare_token          = "EDIT-THIS-api-token"

# this is also used for dns and tunnel ingress hostname so use only alphanumeric
# and hyphens, for my-app it will create two entries:
# my-app.trk.in.rs
# ssh-my-app.trk.in.rs
lxd_container_name        = "my-app"
lxd_machine_name          = "EDIT-THIS-computer-name"
```

Run terraform
```
terraform init

ssh-keygen -f my-key

terraform plan
terraform apply -auto-approve
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
scp lxd-mashine:lxc/my-app_cloudflare_tunnel_tf/my-key*  .

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
