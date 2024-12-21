locals {
  additional_public_keys = fileexists(var.additional_public_key_file) ? join("\n", [for line in split("\n", file(var.additional_public_key_file)) : "    - ${line}" if trimspace(line) != ""]) : ""
}
resource "lxd_instance" "instance1" {
  name  = var.lxd_container_name
  # https://cloud-images.ubuntu.com go to releases
  image = "ubuntu-daily:${var.ubuntu_version}"
  description = "~/lxc/ on  ${var.lxd_machine_name}"

  # for old ubuntu-daily:20.04 use user.user-data instead cloud-init.user-data
  # check the content with lxc shell ${var.lxd_container_name} and
  # cat /var/lib/cloud/instance/cloud-config.txt
  config = {
    "boot.autostart" = true
    "user.user-data" = <<-HERE_DOC
      #cloud-config
      users:
        - name: ubuntu
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          groups: sudo
          ssh_authorized_keys:
          - ${file(var.default_public_key_file)}
          ${local.additional_public_keys}
      package_update: true
      packages:
        - git
        - vim-nox
    HERE_DOC
  }

  limits = {
    # cpu = 2
  }

  provisioner "local-exec" {
   command = <<-EOF
      while ! nc -z ${self.ipv4_address} 22; do
        echo "Waiting for SSH to be ready..."
        sleep 0.3
      done
      if [ -z "$SSH_AGENT_PID" ]; then
        echo "No ssh agent, starting new one..."
        eval "$(ssh-agent -s)"
      fi
      echo ssh-add ${replace(var.default_public_key_file, ".pub", "")}
      ssh-add ${replace(var.default_public_key_file, ".pub", "")}
      echo You should be able to connect with: ssh ubuntu@${self.ipv4_address}
      echo ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i ${self.ipv4_address}, playbook.yml
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i ${self.ipv4_address}, playbook.yml
    EOF
  }

  depends_on = [
    local_file.tf_ansible_vars_file,
  ]
}

# Same names are used for CNAME in cloud-config.tf
locals {
  hostname_80 = var.subdomain == "" ? var.cloudflare_zone : "${var.subdomain}.${var.cloudflare_zone}" # myapp.my-domain.com
  hostname_22 = var.subdomain == "" ? "ssh.${var.cloudflare_zone}" : "${var.subdomain}-ssh.${var.cloudflare_zone}" # myapp-ssh.my-domain.com
}

output "ansible_playbook_command" {
  value = <<-HERE_DOC
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i ${lxd_instance.instance1.ipv4_address}, playbook.yml
  HERE_DOC
}

output "check_cloudflared_tunnel" {
  value = <<-HERE_DOC
    ssh-add ${replace(var.default_public_key_file, ".pub", "")}
    ssh ubuntu@${lxd_instance.instance1.ipv4_address} cloudflared tunnel info ${cloudflare_tunnel.auto_tunnel.name}
  HERE_DOC
}

output "ssh_config_needed_for_deploy_on_development_machine" {
  value = <<-HERE_DOC
    # add to ~/.ssh/config
    Host ${local.hostname_22}
      ProxyCommand cloudflared access ssh --hostname %h

    # or if brew is used
    Host ${local.hostname_22}
      ProxyCommand $(brew --prefix)/bin/cloudflared access ssh --hostname %h

    # NOTE that you need to use subdomain that ends with -ssh.
    # and connect with
    ssh ubuntu@${local.hostname_22}
  HERE_DOC
}

output "ssh_from_development_machine" {
  value = <<-HERE_DOC
    ssh ubuntu@${local.hostname_80}
  HERE_DOC
}
