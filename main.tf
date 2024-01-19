terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "2.13.0"
    }
    onepassword = {
      source = "1Password/onepassword"
      version = "1.4.1-beta01"
    }
  }
}

provider "onepassword" {
  # Configuration options
  account = "procellatechnologies.1password.com"
}

provider "linode" {
  # Configuration options
  # VLANs are in early access
  api_version = "v4beta"

  token = data.onepassword_item.token.password
}

data "onepassword_item" "token" {
  vault = var.Linode-lab
  uuid = "iavygzndgytesbvjaautylg4ly"
}

data "onepassword_item" "gcuium" {
  vault = var.Linode-lab
  uuid = "ea7fghtxoc7bbo3zn2npn6pohy"
}

# I wanted to have no NAT 1:1 but there's no cloud gateway, I can't build
# my own nat gateway and i can't access the metadata service to configure
# proxies without having the proxy configured.  so we're going to go with 
# nat 1:1 for now.  Never mind - i need a public IP for metadata service

# I also need to find a way to extract the vpc IP assigned so i don't have
# to statically assign (and we can use DNS records instead)


# ok, so we can boot up with public interface, in the metadata tell guardicore
# agent to use a proxy and then disable the public interface elsewhere.  Let's 
# see if it works!


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
    user_data = base64encode(templatefile("${path.module}/install_proxy.tftpl", {}))
  }
}

data "linode_instances" "proxy" {
  depends_on = [linode_instance.lab_proxy]
  filter {
    name = "label"
    values = [ "proxy" ]
  }
}


locals {
  proxy_ip = data.linode_instances.proxy.instances.0.config.0.interface.1.ipv4.0.vpc
  wordpress_ip = data.linode_instances.wordpress.instances.0.config.0.interface.1.ipv4.0.vpc
  nginx_ip = data.linode_instances.nginx.instances.0.config.0.interface.1.ipv4.0.vpc
  mysql_ip = data.linode_instances.mysql.instances.0.config.0.interface.1.ipv4.0.vpc
}

resource "linode_domain_record" "proxy_dns_record" {
  domain_id = "${linode_domain.procellab_domain.id}"
  name = "proxy"
  record_type = "A"
  ttl_sec = 30
  target = "${local.proxy_ip}"
}



resource "linode_instance" "wordpress_linode" {
  image = var.image
  label = "wordpress-app"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.wordpress_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_wordpress.tftpl", {wppw=onepassword_item.mysql_db.password,gcagg="34.121.212.145",gcuium=data.onepassword_item.gcuium.password,mysqlip=local.mysql_ip,wordpressname="wordpress.${var.domain}", proxy=local.proxy_ip}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py wordpress.${var.domain}"
  }
  
}



resource "linode_instance" "mysql_linode" {
  image = var.image
  label = "mysql-app"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.mysql_root.password


  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_mysql.tftpl", {wppw=onepassword_item.mysql_db.password,gcagg="34.121.212.145",gcuium=data.onepassword_item.gcuium.password, proxy=local.proxy_ip}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py mysql"
  }
  
}

resource "linode_instance" "nginx_linode" {
  image = var.image
  label = "nginx-app"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.nginx_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_nginx.tftpl", {gcagg="34.121.212.145",gcuium=data.onepassword_item.gcuium.password,wordpressip=local.wordpress_ip, proxy=local.proxy_ip}))
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py nginx"
  }
  
}

# Create a VPC and a subnet
resource "linode_vpc" "gc-procellab" {
    label = "gc-procellab-vpc"
    region = var.region
    description = "test description"
}

resource "linode_vpc_subnet" "gc-procellab" {
    vpc_id = linode_vpc.gc-procellab.id
    label = "gc-procellab-subnet"
    ipv4 = "10.0.4.0/24"
}

resource "onepassword_item" "proxy_root" {
  vault = var.Linode-lab

  title    = "Proxy root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}


resource "onepassword_item" "wordpress_root" {
  vault = var.Linode-lab

  title    = "Wordpress root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "mysql_root" {
  vault = var.Linode-lab

  title    = "MySQL root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "nginx_root" {
  vault = var.Linode-lab

  title    = "nginx root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "mysql_db" {
  vault = var.Linode-lab

  title    = "db password"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}


resource "linode_sshkey" "procellab_sshkey" {
  label = "Procellab_SSH_Key"
  ssh_key = chomp(file("linode_sshkey.pub"))
}

resource "linode_domain" "procellab_domain" {
  domain = var.domain
  soa_email = var.soa_email
  type = "master"
}


resource "linode_domain_record" "nginx_dns_record" {
  domain_id = "${linode_domain.procellab_domain.id}"
  name = "nginx"
  record_type = "A"
  target = "${local.nginx_ip}"
  ttl_sec = 30
}


resource "linode_domain_record" "wordpress_dns_record" {
  domain_id = "${linode_domain.procellab_domain.id}"
  name = "wordpress"
  record_type = "A"
  target = "${local.wordpress_ip}"
  ttl_sec = 30
}

resource "linode_domain_record" "blog_dns_record" {
  domain_id = "${linode_domain.procellab_domain.id}"
  name = "blog"
  record_type = "CNAME"
  target = "nginx.${var.domain}"
  ttl_sec = 30
}


resource "linode_firewall" "my_firewall" {
  label = "my_firewall"

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }
  
  inbound_policy = "DROP"

  outbound_policy = "ACCEPT"

  #linodes = [linode_instance.my_instance.id]
}


data "linode_instances" "wordpress" {
  depends_on = [linode_instance.wordpress_linode]
  filter {
    name = "label"
    values = [ "wordpress-app" ]
  }
}

data "linode_instances" "nginx" {
  depends_on = [linode_instance.nginx_linode]
  filter {
    name = "label"
    values = [ "nginx-app" ]
  }
}

data "linode_instances" "mysql" {
  depends_on = [linode_instance.mysql_linode]
  filter {
    name = "label"
    values = [ "mysql-app" ]
  }
}

