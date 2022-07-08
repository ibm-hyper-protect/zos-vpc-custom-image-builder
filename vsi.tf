# Create a VPC
resource "ibm_is_vpc" "vpc" {
  name = local.mover_vsi_name

}

# subnetwork
resource "ibm_is_subnet" "subnet" {
  name                     = local.mover_vsi_name

  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.full_zone
  total_ipv4_address_count = var.total_ipv4_address_count
}

# ssh key
resource "ibm_is_ssh_key" "sshkey" {
  name      = local.mover_vsi_name

  public_key = local.ssh_public_key
}

# security group
resource "ibm_is_security_group" "security_group" {
    name = local.mover_vsi_name

    vpc = ibm_is_vpc.vpc.id
}

# Configure Security Group Rule to open SSH
resource "ibm_is_security_group_rule" "security_group_rule_ssh" {
    group = ibm_is_security_group.security_group.id
    direction = "inbound"
    depends_on = [ibm_is_security_group.security_group]    
    tcp {
      port_min = 22
      port_max = 22
    }
 }
resource "ibm_is_security_group_rule" "security_group_rule_outbound" {
    group = ibm_is_security_group.security_group.id
    direction = "outbound"
    depends_on = [ibm_is_security_group.security_group]   
 }

# Images
data "ibm_is_images" "vpc_images" {
}
locals {
  mover_image = [for image in data.ibm_is_images.vpc_images.images : image if length(regexall(var.mover_image_name, image.name)) > 0][0]
}

# vsi
resource "ibm_is_instance" "vsi" {
  name    = local.mover_vsi_name

  image   = local.mover_image.id
  profile = var.mover_profile
  metadata_service_enabled  = true

  primary_network_interface {
    subnet = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.security_group.id]
  }

  vpc  = ibm_is_vpc.vpc.id
  zone = "${var.region}-${var.zone}"
  keys = [ibm_is_ssh_key.sshkey.id]

  user_data = sensitive(data.cloudinit_config.config.rendered)
}

#Volumes
resource "ibm_is_instance_volume_attachment" "zos_volumes" {
  instance = ibm_is_instance.vsi.id
  for_each = {
    boot  = 10, # (local.image_metadata_body.image["boot-size"]/1000000000)*1.10, //Adding extra space for file system overhead
    qcow2 = 15, # (local.image_metadata_body.image["boot-size"]/1000000000)*1.15, //Adding extra space for file system overhead + qcow2
    data  = ceil((local.image_metadata_body.image["size"]/1000000000)*1.10), //Adding extra space for file system overhead
  }

  name                               = each.key
  profile                            = var.volume_purpose
  capacity                           = each.value
  delete_volume_on_attachment_delete = true
  delete_volume_on_instance_delete   = false
  volume_name                        = "${local.mover_vsi_name
}-${each.key}"
}


# Floating IP
resource "ibm_is_floating_ip" "floatingip" {
  name   = local.mover_vsi_name

  target = ibm_is_instance.vsi.primary_network_interface[0].id
}

resource "time_sleep" "wait_for_cloudinit" {
  depends_on = [
    ibm_is_floating_ip.floatingip,
    ibm_is_instance.vsi
  ]

  create_duration = "0s"

  triggers = {
    vsi_id = ibm_is_instance.vsi.id
  }

  # Establishes connection to be used by all
  # generic remote provisioners (i.e. file/remote-exec)
  connection {
    type     = "ssh"
    user     = "root"
    host     = ibm_is_floating_ip.floatingip.address
    private_key = local.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
    ]
  }
}