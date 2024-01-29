# I wanted to have no NAT 1:1 but there's no cloud gateway, I can't build
# my own nat gateway and i can't access the metadata service to configure
# proxies without having the proxy configured.  so we're going to go with 
# nat 1:1 for now.  Never mind - i need a public IP for metadata service

# I also need to find a way to extract the vpc IP assigned so i don't have
# to statically assign (and we can use DNS records instead)


# ok, so we can boot up with public interface, in the metadata tell guardicore
# agent to use a proxy and then disable the public interface elsewhere.  Let's 
# see if it works!

# the actual proxy

resource "linode_instance" "lab_proxy" {
  image = var.image
  label = "proxy"
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
    user_data = base64encode(templatefile("${path.module}/install_proxy.tftpl", {label="proxy",gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password,eaaconn=data.external.eaa_connector.result.download_url}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/delete_agent_and_connector.sh ${self.label}"
  }
  
}



# used to pull out the IP address for use by other things

data "linode_instances" "proxy" {
  depends_on = [linode_instance.lab_proxy]
  filter {
    name = "label"
    values = [ "proxy" ]
  }
}


# a local "variable" to hold the proxy IP address
locals {
  proxy_ip = data.linode_instances.proxy.instances.0.config.0.interface.1.ipv4.0.vpc
}

# create a DNS record for proxy.linode.procellab.zone pointing to the VPC IP
resource "linode_domain_record" "proxy_dns_record" {
  domain_id = "${linode_domain.procellab_domain.id}"
  name = "proxy"
  record_type = "A"
  ttl_sec = 30
  target = "${local.proxy_ip}"
}


# generate a unique password for root and store it in 1password
resource "onepassword_item" "proxy_root" {
  vault = var.Linode-lab

  title    = "Proxy root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}


# this will create the EAA connector and return the download URL and agentid in JSON
data "external" "eaa_connector" {
  program = [
    "${path.module}/install_eaa_connector.py", "proxy",
  ]
  query = {
    # You can pass something to STDIN of your program here, 
    # but as per current version, the input will be given as JSON (map of string)
  }
}

output "connector" {
  value = data.external.eaa_connector.result
}

# this will approve the EAA connector
resource "null_resource" "approve_connector" {
  # make sure proxy is up
  depends_on = [linode_instance.lab_proxy]
  
  provisioner "local-exec" {
      command = "${path.module}/approve_eaa_connector.py proxy"
  }
}
