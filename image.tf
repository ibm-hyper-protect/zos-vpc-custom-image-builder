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
