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
          ${fileexists(var.additional_public_key_file) ? "- ${file(var.additional_public_key_file)}" : ""}
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
        eval "$(ssh-agent -s)"
      fi
      ssh-add ${replace(var.default_public_key_file, ".pub", "")}
      echo ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i ${self.ipv4_address}, playbook.yml
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i ${self.ipv4_address}, playbook.yml
    EOF
  }

  depends_on = [
    local_file.tf_ansible_vars_file,
  ]
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
