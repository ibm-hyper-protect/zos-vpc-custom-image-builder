# data "ibm_resource_group" "cos_group" {
#   name = "cos-resource-group"
# }

data "ibm_resource_instance" "cos_instance" {
  name              = var.cos_instance_name
  #resource_group_id = data.ibm_resource_group.cos_group.id
  service           = "cloud-object-storage"
}

data "ibm_cos_bucket" "cos_bucket" {
  resource_instance_id = data.ibm_resource_instance.cos_instance.id
  bucket_name          = var.cos_bucket_name
  bucket_type          = var.cos_bucket_type
  bucket_region        = var.cos_bucket_region
}

data "ibm_cos_bucket_object" "image_metadata" {
  bucket_crn      = data.ibm_cos_bucket.cos_bucket.crn
  bucket_location = data.ibm_cos_bucket.cos_bucket.bucket_region
  key             = "image-metadata2.json" #TBD: enforce json format
}

# #Debug only
# output "image_metadata_output" {
#   value = jsondecode(data.ibm_cos_bucket_object.image_metadata.body)
# }

# #Debug only
# output "image_metadata_type" {
#   value = data.ibm_cos_bucket_object.image_metadata.content_type
# }