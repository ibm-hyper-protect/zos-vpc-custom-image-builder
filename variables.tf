variable "custom_image_name" {
  description = "z/OS Custom image name" 
  type        = string
  default = "wazi-custom-image"
}
variable "region" {
  description = "Region to run the VSI doing the conversion" 
  type        = string
  default = "ca-tor"
}

variable "zone" {
  description = "Zone for the VSI - data volumes will be stored here" 
  type        = string
  default = "1"
}

variable "cos_bucket_region" {
  description = "Region of the COS instance" 
  type        = string
}

variable "cos_instance_name" {
  description = "Name of the COS instance" 
  type        = string
}

variable "cos_bucket_name" {
  description = "Name of the COS bucket" 
  type        = string
}





# The options bellow should not need to be changed

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

variable "cos_bucket_type" {
  default = "region_location"
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
  default = ".*ubuntu.*amd64.*"
}

variable "custom_image_os" {
  default = "zos-2-4-s390x"
}

variable "mover_profile" {
  default = "bx2d-16x64"
}

variable "security_group_name" {
  default = "wazi-custom-image"
}