locals {
  full_zone = "${var.region}-${var.zone}"
  mover_vsi_name = "${var.custom_image_name}-build"
  image_metadata_body = jsondecode(data.ibm_cos_bucket_object.image_metadata.body)
  image_metadata_boot_volumes = [for volume in local.image_metadata_body.volumes: volume if volume.boot]
  image_metadata_local_volumes = [for volume in local.image_metadata_body.volumes: volume if volume.boot == false]
  ssh_private_key = var.ssh_private_key != "null" ? var.ssh_private_key : tls_private_key.ssh_key.private_key_openssh
  ssh_public_key  = var.ssh_public_key != "null" ? var.ssh_public_key : trimspace(tls_private_key.ssh_key.public_key_openssh)

  # This is used when the user chooses encryption_type as user_managed.
  # By default, it is null
  volume_encryption_key_crn = ( var.encryption_type == "provider_managed" || var.customer_root_key_crn == "null") ? "" : var.customer_root_key_crn
}

#Debug only
# output "image_metadata_local_volumes" {
#   value = local.image_metadata_local_volumes
# }
