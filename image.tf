resource "ibm_is_image" "custom_image" {
  name               = var.custom_image_name
  href               = data.ibm_cos_bucket_object.image_qcow2.object_sql_url
  operating_system   = var.custom_image_os
  #encrypted_data_key = "eJxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0="
  #encryption_key     = "crn:v1:bluemix:public:kms:us-south:a/6xxxxxxxxxxxxxxx:xxxxxxx-xxxx-xxxx-xxxxxxx:key:dxxxxxx-fxxx-4xxx-9xxx-7xxxxxxxx"//increase timeouts as per volume size

  timeouts {
    create = "300m"
  }
}