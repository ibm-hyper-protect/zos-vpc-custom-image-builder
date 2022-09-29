# The value of the qcow2 is depending on the bucket object etag
resource "null_resource" "value_of_qcow2" {
  depends_on = [
    data.ibm_cos_bucket_object.image_qcow2
  ]

  triggers = {
    etag = data.ibm_cos_bucket_object.image_qcow2.etag
  }
}

resource "ibm_is_image" "custom_image" {
  depends_on = [
    null_resource.value_of_qcow2
  ]
  name               = var.custom_image_name
  href               = data.ibm_cos_bucket_object.image_qcow2.object_sql_url
  operating_system   = var.custom_image_os
  #encrypted_data_key = "eJxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0="
  #encryption_key     = "crn:v1:bluemix:public:kms:us-south:a/6xxxxxxxxxxxxxxx:xxxxxxx-xxxx-xxxx-xxxxxxx:key:dxxxxxx-fxxx-4xxx-9xxx-7xxxxxxxx"//increase timeouts as per volume size

  timeouts {
    create = "300m"
  }
  # Commenting it for now since it needs terraform 1.2.x, and schematics won't
  # support that until end of Q3.
  #lifecycle {
  #  replace_triggered_by = [null_resource.value_of_qcow2.id]
  #}
}

#Create a VPC
resource "ibm_is_vpc" "testacc_vpc" {
  name = local.custom_vsi_name
}

# ssh key
resource "ibm_is_ssh_key" "testacc_sshkey" {
  name      = local.custom_vsi_name
  public_key = local.ssh_public_key
}

# subnetwork
resource "ibm_is_subnet" "testacc_subnet" {
  name                     = local.custom_vsi_name
  vpc                      = ibm_is_vpc.testacc_vpc.id
  zone                     = local.full_zone
  total_ipv4_address_count = var.total_ipv4_address_count
}

# security group
resource "ibm_is_security_group" "testacc_security_group" {
  name = local.custom_vsi_name
  vpc  = ibm_is_vpc.testacc_vpc.id
}

# rule that allows the VSI to make outbound connections, this is required
# to connect to the logDNA instance as well as to docker to pull the image
resource "ibm_is_security_group_rule" "testacc_security_group_rule_outbound" {
  group     = ibm_is_security_group.testacc_security_group.id
  direction = "outbound"
  depends_on = [ibm_is_security_group.testacc_security_group]
}

# Configure Security Group Rule to open SSH
resource "ibm_is_security_group_rule" "testacc_security_group_rule_ssh" {
  group     = ibm_is_security_group.testacc_security_group.id
  direction = "inbound"
  depends_on = [ibm_is_security_group.testacc_security_group]    
  tcp {
    port_min = 22
    port_max = 22
  }
}

# vsi
resource "ibm_is_instance" "testacc_vsi" {
  name    = local.custom_vsi_name
  image   = ibm_is_image.custom_image.id
  profile = local.profile

  primary_network_interface {
    subnet          = ibm_is_subnet.testacc_subnet.id
    security_groups = [ibm_is_security_group.testacc_security_group.id]
  }

  vpc  = ibm_is_vpc.testacc_vpc.id
  zone = "${var.region}-${var.zone}"
  keys = [ibm_is_ssh_key.testacc_sshkey.id]
}

# Floating IP
resource "ibm_is_floating_ip" "testacc_floatingip" {
  name   = local.custom_vsi_name
  target = ibm_is_instance.testacc_vsi.primary_network_interface[0].id
}


resource "ibm_is_instance_volume_attachment" "example-snapshot-attach" {
  instance = ibm_is_instance.testacc_vsi.id
  name =  "${var.custom_image_name}-data"
  profile = "general-purpose"
  snapshot = ibm_is_snapshot.custom_image_data.id
  delete_volume_on_attachment_delete = false
  delete_volume_on_instance_delete = true
  volume_name = "${var.custom_image_name}-data-custom-test"
}

