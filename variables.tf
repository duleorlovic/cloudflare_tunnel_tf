# Cloudflare variables
variable "cloudflare_zone" {
  description = "Domain used to expose the GCP VM instance to the Internet"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for your domain"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Account ID for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Email address for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "cloudflare_token" {
  description = "Cloudflare API token created at https://dash.cloudflare.com/profile/api-tokens"
  type        = string
  sensitive   = true
}

# lxc variables
variable "lxd_container_name" {
  type          = string
  description   = "Name of the container"
}

variable "subdomain" {
  type          = string
  description   = "Name of the subdomain"
}

variable "lxd_machine_name" {
  type          = string
  description   = "Hostname of the lxd machine"
}

variable "ubuntu_version" {
  type          = string
  description   = "Ubuntu version"
}

variable "default_public_key_file" {
   type        = string
   description = "Path to the default public SSH key file. ssh-keygen -f"
}

variable "additional_public_key_file" {
   type        = string
   description = "Path to the additional public SSH key file. Not required"
}
