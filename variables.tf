# Region to run the VSI doing the conversion
variable "region" {
  default = "ca-tor"
}

# Zone for the VSI - data volumes will be stored here
variable "zone" {
  default = "1"
}

# z/OS Custom image name
variable "custom_image_name" {
  default = "wazi-custom-image"
}

# z/OS Volume name prefix
variable "volume_prefix" {
  default = "wazi-custom-image"
}
# z/OS Volume name prefix
variable "volume_purpose" {
  #default = "general-purpose" # 3 IOPS/GB
  #default = "5iops-tier"
  default = "10iops-tier"
}

# VSI name
variable "mover_vsi_name" {
  default = "wazi-custom-image-build"
}

variable "cos_instance_name" {
  default = "Cloud Object Storage-6q"
}

variable "cos_bucket_name" {
  default = "wibtest-eu-gb"
}

variable "cos_bucket_type" {
  default = "region_location"
}

variable "cos_bucket_region" {
  default = "eu-gb"
}


# Most likelly you do not need to change the values bellow

variable "vpc" {
  default = "wazi-custom-image"
}

variable "ssh_public_key_name" {
  default = "wazi-custom-image"
}

variable "ssh_private_key" {
  default = "~/.ssh/id_rsa" # If this file does not exist, a terraform generated key is used
}
variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub" # If this file does not exist, a terraform generated key is used
}

variable "subnetwork_name" {
  default = "wazi-custom-image"
}

variable "total_ipv4_address_count" {
    default = 256
}

variable "mover_image_name" {
  # Regular expresions allowed
  default = ".*ubuntu.*"
}

variable "mover_profile" {
  default = "bx2d-16x64"
}

variable "security_group_name" {
  default = "wazi-custom-image"
}