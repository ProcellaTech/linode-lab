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




resource "linode_sshkey" "procellab_sshkey" {
  label = "Procellab_SSH_Key"
  ssh_key = chomp(file("linode_sshkey.pub"))
}

resource "linode_domain" "procellab_domain" {
  domain = var.domain
  soa_email = var.soa_email
  type = "master"
}


data "linode_instances" "all-instances" {}


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
  
  inbound {
    label    = "allow-lab"
    action   = "ACCEPT"
    protocol = "TCP"
    ipv4     = [linode_vpc_subnet.gc-procellab.ipv4]
  }
  
  inbound_policy = "DROP"

  outbound_policy = "ACCEPT"

  linodes = data.linode_instances.all-instances.instances.*.id
}


