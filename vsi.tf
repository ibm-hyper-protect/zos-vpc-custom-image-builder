# Create a VPC
resource "ibm_is_vpc" "vpc" {
  name = var.vpc
}

# subnetwork
resource "ibm_is_subnet" "subnet" {
  name                     = var.subnetwork_name
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.full_zone
  total_ipv4_address_count = var.total_ipv4_address_count
}

# Images
data "ibm_is_images" "vpc_images" {
}
locals {
  image = [for image in data.ibm_is_images.vpc_images.images : image if length(regexall(var.image_name, image.name)) > 0][0]
}

# vsi
resource "ibm_is_instance" "vsi" {
  name    = var.vsi_name
  image   = local.image.id
  profile = var.profile
  metadata_service_enabled  = true

  primary_network_interface {
    subnet = ibm_is_subnet.subnet.id
  }

  vpc  = ibm_is_vpc.vpc.id
  zone = "${var.region}-${var.zone}"
  keys = [ibm_is_ssh_key.sshkey.id]

  user_data = <<EOF
#cloud-config
packages:
 - jq
EOF
}

#Volumes
resource "ibm_is_instance_volume_attachment" "zos_volumes" {
  instance = ibm_is_instance.vsi.id
  for_each = merge(
     {boot = "250"}, #TBD: calculate size
     {for volume in local.image_metadata_local_volumes: lower(volume.name) => volume.size}
  )

  name                               = each.key
  profile                            = var.volume_purpose
  capacity                           = each.value
  delete_volume_on_attachment_delete = true
  delete_volume_on_instance_delete   = false
  volume_name                        = "${var.volume_prefix}-${each.key}"
}


# DEBUG ONLY - SSH enablement

# Floating IP
resource "ibm_is_floating_ip" "floatingip" {
  name   = "testfip1"
  target = ibm_is_instance.vsi.primary_network_interface[0].id
}


# ssh key
resource "ibm_is_ssh_key" "sshkey" {
  name      = var.ssh_public_key_name
  public_key = file(var.ssh_public_key)
}

# security group
resource "ibm_is_security_group" "security_group" {
    name = "test"
    vpc = ibm_is_vpc.vpc.id
}

# Configure Security Group Rule to open SSH
resource "ibm_is_security_group_rule" "security_group_rule_ssh" {
    group = ibm_is_security_group.security_group.id
    direction = "inbound"
    remote = "0.0.0.0"
    depends_on = [ibm_is_security_group.security_group]
    # tcp {
    #   port_min = 22
    #   port_max = 22
    # }
 }