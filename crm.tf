# app server is wordpress

resource "linode_instance" "crm_app" {
  image = var.image
  label = "crm_app"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.crm_app_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_wordpress.tftpl", {label="crm-app",wppw=onepassword_item.crm_db.password,gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password,mysqlip=local.crm_db_ip,wordpressname="crm-app.${var.domain}", proxy=local.proxy_ip}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}



resource "linode_instance" "crm_db" {
  image = var.image
  label = "crm_db"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.crm_db_root.password


  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_mysql.tftpl", {label="crm-db",wppw=onepassword_item.crm_db.password,gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password, proxy=local.proxy_ip}))
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}

resource "linode_instance" "crm_web" {
  image = var.image
  label = "crm_web"
  region = var.region
  type = var.type
  authorized_keys = [ linode_sshkey.procellab_sshkey.ssh_key ]
  root_pass = onepassword_item.crm_web_root.password

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.gc-procellab.id
  }

  metadata  {
  user_data = base64encode(templatefile("${path.module}/install_nginx.tftpl", {label="crm-web",gcagg=var.gcagg_ip,gcuium=data.onepassword_item.gcuium.password,wordpressip=local.crm_app_ip, wordpressname="crm-app.${var.domain}",proxy=local.proxy_ip}))
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./delete_agent.py ${self.label}"
  }
  
}



data "linode_instances" "crm_app" {
  depends_on = [linode_instance.crm_app]
  filter {
    name = "label"
    values = [ "crm_app" ]
  }
}

data "linode_instances" "crm_web" {
  depends_on = [linode_instance.crm_web]
  filter {
    name = "label"
    values = [ "crm_web" ]
  }
}

data "linode_instances" "crm_db" {
  depends_on = [linode_instance.crm_db]
  filter {
    name = "label"
    values = [ "crm_db" ]
  }
}






# variables to hold IP addresses
locals {
  crm_app_ip = data.linode_instances.crm_app.instances.0.config.0.interface.1.ipv4.0.vpc
  crm_web_ip = data.linode_instances.crm_web.instances.0.config.0.interface.1.ipv4.0.vpc
  crm_db_ip = data.linode_instances.crm_db.instances.0.config.0.interface.1.ipv4.0.vpc
  crm_ips = concat([local.crm_app_ip],[local.crm_web_ip],[local.crm_db_ip])
}


resource "onepassword_item" "crm_app_root" {
  vault = var.Linode-lab

  title    = "crm_app root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "crm_db_root" {
  vault = var.Linode-lab

  title    = "crm_db root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "crm_web_root" {
  vault = var.Linode-lab

  title    = "crm_web root"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

resource "onepassword_item" "crm_db" {
  vault = var.Linode-lab

  title    = "crm_db password"
  category = "password"

  password_recipe {
    length  = 40
    symbols = false
  }
}

