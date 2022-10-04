
#Create a VPC
resource "ibm_is_vpc" "testacc_vpc" {
  count = var.custom_vsi ? 1 : 0
  name = local.custom_vsi_name
}

# ssh key
resource "ibm_is_ssh_key" "testacc_sshkey" {
  count = var.custom_vsi ? 1 : 0
  name      = local.custom_vsi_name
  public_key = local.ssh_public_key
}

# subnetwork
resource "ibm_is_subnet" "testacc_subnet" {
  count = var.custom_vsi ? 1 : 0
  name                     = local.custom_vsi_name
  vpc                      = ibm_is_vpc.testacc_vpc[count.index].id
  zone                     = local.full_zone
  total_ipv4_address_count = var.total_ipv4_address_count
}

# security group
resource "ibm_is_security_group" "testacc_security_group" {
  count = var.custom_vsi ? 1 : 0
  name = local.custom_vsi_name
  vpc  = ibm_is_vpc.testacc_vpc[count.index].id
}

# rule that allows the VSI to make outbound connections, this is required
# to connect to the logDNA instance as well as to docker to pull the image
resource "ibm_is_security_group_rule" "testacc_security_group_rule_outbound" {
  count = var.custom_vsi ? 1 : 0
  group     = ibm_is_security_group.testacc_security_group[count.index].id
  direction = "outbound"
  depends_on = [ibm_is_security_group.testacc_security_group]
}

# Configure Security Group Rule to open SSH
resource "ibm_is_security_group_rule" "testacc_security_group_rule_ssh" {
  count = var.custom_vsi ? 1 : 0
  group     = ibm_is_security_group.testacc_security_group[count.index].id
  direction = "inbound"
  depends_on = [ibm_is_security_group.testacc_security_group]    
  tcp {
    port_min = 22
    port_max = 22
  }
}

# vsi
resource "ibm_is_instance" "testacc_vsi" {
  count = var.custom_vsi ? 1 : 0
  name    = local.custom_vsi_name
  image   = ibm_is_image.custom_image.id
  profile = local.profile

  primary_network_interface {
    subnet          = ibm_is_subnet.testacc_subnet[count.index].id
    security_groups = [ibm_is_security_group.testacc_security_group[count.index].id]
  }

  vpc  = ibm_is_vpc.testacc_vpc[count.index].id
  zone = "${var.region}-${var.zone}"
  keys = [ibm_is_ssh_key.testacc_sshkey[count.index].id]
}

# Floating IP
resource "ibm_is_floating_ip" "testacc_floatingip" {
  count = var.custom_vsi ? 1 : 0
  name   = local.custom_vsi_name
  target = ibm_is_instance.testacc_vsi[count.index].primary_network_interface[0].id
}


resource "ibm_is_instance_volume_attachment" "example-snapshot-attach" {
  count = var.custom_vsi ? 1 : 0
  instance = ibm_is_instance.testacc_vsi[count.index].id
  name =  "${var.custom_image_name}-data"
  profile = "general-purpose"
  snapshot = ibm_is_snapshot.custom_image_data.id
  delete_volume_on_attachment_delete = false
  delete_volume_on_instance_delete = true
  volume_name = "${var.custom_image_name}-data-custom-test"
}