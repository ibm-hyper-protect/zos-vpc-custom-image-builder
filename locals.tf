locals {
  full_zone = "${var.region}-${var.zone}"
  image_metadata_body = jsondecode(data.ibm_cos_bucket_object.image_metadata.body)
  image_metadata_boot_volumes = [for volume in local.image_metadata_body.volumes: merge({size=10}, volume) if volume.boot]
  image_metadata_local_volumes = [for volume in local.image_metadata_body.volumes: merge({size=10}, volume) if volume.boot == false]
  ssh_private_key = fileexists(var.ssh_private_key) ? file(var.ssh_private_key) : tls_private_key.ssh_key.private_key_openssh
  ssh_public_key = fileexists(var.ssh_public_key) ? file(var.ssh_public_key) : tls_private_key.ssh_key.public_key_openssh
}

#Debug only
# output "image_metadata_local_volumes" {
#   value = local.image_metadata_local_volumes
# }