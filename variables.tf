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

variable "lxd_machine_name" {
  type          = string
  description   = "Hostname of the lxd machine"
}

variable "public_key_file" {
   type        = string
   description = "Path to the public SSH key file"
   default     = "my-key.pub"
   # you can use ~/.ssh/id_rsa.pub for local public key so you can access from
   # local machine but better is to create new key and use it for remote access
   # Generate with: ssh-keygen -f my-key
}
