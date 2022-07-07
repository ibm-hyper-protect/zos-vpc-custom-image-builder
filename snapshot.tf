resource "ibm_is_snapshot" "custom_image_data_volume" {
  name          = "${var.volume_prefix}-data"
  source_volume = ibm_is_instance_volume_attachment.zos_volumes["data"].volume_id
}