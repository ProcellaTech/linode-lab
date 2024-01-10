variable "Linode-lab" {
  type = string
  default = "jjkz7xwzfg67whlw2cex2tedxa"
}

variable "soa_email" {
  type = string
  default = "dns@procella.tech"
}

variable "domain" {
  type = string
  default = "linode.procellab.zone"
}

variable "image" {
  description = "Image to use for Linode instance"
  default = "linode/ubuntu22.04"
}

variable "region" {
  description = "The region where your Linode will be located."
  default = "us-iad"
}

variable "type" {
  description = "Your Linode's plan type."
  default = "g6-nanode-1"
}

variable "install_wordpress" {
  description = "install and configure wordpress"
  default = <<-EOF
  
EOF
}


variable "install_nginx" {
  description = "install and configure nginx"
  default = <<-EOF
  
EOF
}

