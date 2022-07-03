locals {
  full_zone = "${var.region}-${var.zone}"
  image_metadata_body = jsondecode(data.ibm_cos_bucket_object.image_metadata.body)
  image_metadata_boot_volumes = [for volume in local.image_metadata_body.volumes: merge({size=10}, volume) if volume.boot]
  image_metadata_local_volumes = [for volume in local.image_metadata_body.volumes: merge({size=10}, volume) if volume.boot == false]
}

#Debug only
# output "image_metadata_local_volumes" {
#   value = local.image_metadata_local_volumes
# }