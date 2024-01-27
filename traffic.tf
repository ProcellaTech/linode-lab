resource "linode_instance" "traffic_generator" {
  image = var.image
  label = "traffic"
  region = var.region
  type = var.type
  
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.traffic_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
    user_data = base64encode(templatefile("${path.module}/install_traffic.tftpl", {label="traffic-generator",accounting_ips=join(" ",local.accounting_ips),billing_ips=join(" ",local.billing_ips),crm_ips=join(" ",local.crm_ips)}))
  }
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


