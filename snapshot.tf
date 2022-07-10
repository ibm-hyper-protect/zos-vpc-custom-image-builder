resource "ibm_is_snapshot" "custom_image_data" {
  name          = "${var.custom_image_name}-data"
  source_volume = ibm_is_volume.zos_volumes["data"].id

  depends_on = [
    time_sleep.wait_for_cloudinit # Created by data_mover VSI
  ]

  //increase timeouts as per volume size
  timeouts {
    create = "2h"
    delete = "2h"
  }

}