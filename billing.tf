# app server is wordpress

resource "linode_instance" "billing_app" {
  image = var.image
  label = "billing_app"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.billing_app_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_wordpress.tftpl", {label="billing-app",wppw=onepassword_item.billing_db.password,gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password,mysqlip=local.billing_db_ip,domain=var.domain, proxy=local.proxy_ip}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}



resource "linode_instance" "billing_db" {
  image = var.image
  label = "billing_db"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.billing_db_root.password


  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_mysql.tftpl", {label="billing-db",wppw=onepassword_item.billing_db.password,gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password, proxy=local.proxy_ip}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}

resource "linode_instance" "billing_web" {
  image = var.image
  label = "billing_web"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.billing_web_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_nginx.tftpl", {label="billing-web",gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password,wordpressip=local.billing_app_ip, wordpressname="billing-app.${var.domain}",proxy=local.proxy_ip}))
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}



data "linode_instances" "billing_app" {
  depends_on = [linode_instance.billing_app]
  filter {
    name = "label"
    values = [ "billing_app" ]
  }
}

data "linode_instances" "billing_web" {
  depends_on = [linode_instance.billing_web]
  filter {
    name = "label"
    values = [ "billing_web" ]
  }
}

data "linode_instances" "billing_db" {
  depends_on = [linode_instance.billing_db]
  filter {
    name = "label"
    values = [ "billing_db" ]
  }
}






# variables to hold IP addresses
locals {
  billing_app_ip = data.linode_instances.billing_app.instances.0.config.0.interface.1.ipv4.0.vpc
  billing_web_ip = data.linode_instances.billing_web.instances.0.config.0.interface.1.ipv4.0.vpc
  billing_db_ip = data.linode_instances.billing_db.instances.0.config.0.interface.1.ipv4.0.vpc
  billing_ips = concat([local.billing_app_ip],[local.billing_web_ip],[local.billing_db_ip])
}


resource "onepassword_item" "billing_app_root" {
  vault = var.Linode-lab

  title    = "billing_app root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "billing_db_root" {
  vault = var.Linode-lab

  title    = "billing_db root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "billing_web_root" {
  vault = var.Linode-lab

  title    = "billing_web root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "billing_db" {
  vault = var.Linode-lab

  title    = "billing_db password"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "null_resource" "eaa_billing" {
  depends_on = [linode_instance.billing_web]
  
  provisioner "local-exec" {
      command = "${path.module}/publish_app.py billing ${var.domain} ${local.billing_web_ip} ${data.external.eaa_connector.result.agentid}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/unpublish_app.py billing"
  }  
}