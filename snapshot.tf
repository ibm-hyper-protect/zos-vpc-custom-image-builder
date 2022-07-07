resource "ibm_is_snapshot" "custom_image_data_volume" {
  name          = "${var.volume_prefix}-data"
  source_volume = ibm_is_instance_volume_attachment.zos_volumes["data"].volume
  
  depends_on = [
    time_sleep.wait_for_cloudinit # Created by data_mover VSI
  ]

  //increase timeouts as per volume size
  timeouts {
    create = "45m"
  }

}