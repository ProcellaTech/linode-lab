# app server is wordpress

resource "linode_instance" "accounting_app" {
  image = var.image
  label = "accounting_app"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.accounting_app_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_wordpress.tftpl", {label="accounting-app",wppw=onepassword_item.accounting_db.password,gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password,mysqlip=local.accounting_db_ip,domain=var.domain, proxy=local.proxy_ip}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}



resource "linode_instance" "accounting_db" {
  image = var.image
  label = "accounting_db"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.accounting_db_root.password


  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_mysql.tftpl", {label="accounting-db",wppw=onepassword_item.accounting_db.password,gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password, proxy=local.proxy_ip}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}

resource "linode_instance" "accounting_web" {
  image = var.image
  label = "accounting_web"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.accounting_web_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_nginx.tftpl", {label="accounting-web",gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password,wordpressip=local.accounting_app_ip, wordpressname="accounting-app.${var.domain}",proxy=local.proxy_ip}))
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}



data "linode_instances" "accounting_app" {
  depends_on = [linode_instance.accounting_app]
  filter {
    name = "label"
    values = [ "accounting_app" ]
  }
}

data "linode_instances" "accounting_web" {
  depends_on = [linode_instance.accounting_web]
  filter {
    name = "label"
    values = [ "accounting_web" ]
  }
}

data "linode_instances" "accounting_db" {
  depends_on = [linode_instance.accounting_db]
  filter {
    name = "label"
    values = [ "accounting_db" ]
  }
}






# variables to hold IP addresses
locals {
  accounting_app_ip = data.linode_instances.accounting_app.instances.0.config.0.interface.1.ipv4.0.vpc
  accounting_web_ip = data.linode_instances.accounting_web.instances.0.config.0.interface.1.ipv4.0.vpc
  accounting_db_ip = data.linode_instances.accounting_db.instances.0.config.0.interface.1.ipv4.0.vpc
  accounting_ips = concat([local.accounting_app_ip],[local.accounting_web_ip],[local.accounting_db_ip])
}


resource "onepassword_item" "accounting_app_root" {
  vault = var.Linode-lab

  title    = "accounting_app root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "accounting_db_root" {
  vault = var.Linode-lab

  title    = "accounting_db root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "accounting_web_root" {
  vault = var.Linode-lab

  title    = "accounting_web root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "accounting_db" {
  vault = var.Linode-lab

  title    = "accounting_db password"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "null_resource" "eaa_accounting" {
  depends_on = [linode_instance.accounting_web]
  
  provisioner "local-exec" {
      command = "${path.module}/publish_app.py accounting ${var.domain} ${local.accounting_web_ip} ${data.external.eaa_connector.result.agentid}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/unpublish_app.py accounting"
  }  
}

