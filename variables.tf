# Image variables
variable "custom_image_name" {
  description = "z/OS Custom image name" 
  type        = string
  default = "wazi-custom-image"
}

variable "custom_image_os" {
  description = "OS for generated image - it must match the OS uploaded to COS"
  default = "zos-2-4-s390x"
}

# Target location for image
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

# Souce COS bucket with the CKD files
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
variable "volume_purpose" {
  #default = "general-purpose" # 3 IOPS/GB
  #default = "5iops-tier"
  default = "10iops-tier"
}

variable "cos_bucket_type" {
  description = "bucket type"
  default = "region_location"
}


# Most likelly you do not need to change the values bellow

variable "ssh_private_key" {
  description = "path to private ssh for data mover VSI - if not set terraform will generate a random one" 
  type        = string
  default     = null
}

variable "total_ipv4_address_count" {
    description = "total IPs for subnetwork"
    default = 256
}

variable "mover_image_name" {
  # Regular expresions allowed
  description = "image used for the VSI data mover"
  default = ".*ubuntu.*22-04.*amd64.*"
}

variable "mover_profile" {
  description = "image used for the VSI data mover"
  default = "bx2d-16x64"
}