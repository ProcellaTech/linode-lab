resource "linode_instance" "traffic_generator" {
  image = var.image
  label = "traffic"
  region = var.region
  type = var.type
  
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.proxy_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
    user_data = base64encode(templatefile("${path.module}/install_traffic.tftpl", {label="traffic-generator",lab_ips=local.all_ips}))
  }
}

locals {
  all_ips = join(" ",concat(local.accounting_ips,local.crm_ips,local.billing_ips))
}

# generate a unique password for root and store it in 1password
resource "onepassword_item" "traffic_root" {
  vault = var.Linode-lab

  title    = "Traffic root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}


