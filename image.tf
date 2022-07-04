# resource "ibm_is_image" "custom_image" {
#   name = var.custom_image_name

#   depends_on = [
#     time_sleep.wait_for_cloudinit
#   ]

#   //optional field, either of (href, operating_system) or source_volume is required

#   # source_volume      = "r038-9dc33283-a843-4855-91ab-b95c6622bd31" It does not work -
#   #href = ibm_is_instance_volume_attachment.zos_volumes["boot"].volume_href
#   operating_system = "zos-2-4-s390x"
#   #encrypted_data_key = "eJxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0="
#   #encryption_key     = "crn:v1:bluemix:public:kms:us-south:a/6xxxxxxxxxxxxxxx:xxxxxxx-xxxx-xxxx-xxxxxxx:key:dxxxxxx-fxxx-4xxx-9xxx-7xxxxxxxx"

#   //increase timeouts as per volume size
#   timeouts {
#     create = "45m"
#   }

# }