# Image variables
variable "custom_image_name" {
  description = "z/OS Custom image name" 
  type        = string
  default = "wazi-custom-image"
}

variable "custom_image_os" {
  description = "OS for generated image - it must match the OS uploaded to COS"
  default = "zos-2-4-s390x-dev-test-byol"
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

variable "cos_resource_group" {
  description = "Resource group of the COS instance"
  type        = string
  default     = "Default"
}

variable "cos_endpoint" {
  description = "Endpoint of COS service"
  type        = string
  default     = ""
}

variable "encryption_type" {
  type        = string
  default     = "provider_managed"
  description = <<-DESC
                 If the value is "provider_managed", then the block storage
                 volumes will be encrypted automatically with the key chosen
                 by IBM. However, if the user wishes to use own keys, then the
                 value should be "user_managed"

                 If the value is "user_managed", then, value for the variable
                  "customer_root_key_crn" must be specified
                DESC

  validation {
    condition     = ( var.encryption_type == "user_managed"  ||
                      var.encryption_type == "provider_managed" )

    error_message = "Value of encryption_type must be either user_managed or provider_managed."
  }
}

variable "customer_root_key_crn" {
  type        = string
  default     = ""
  description = <<-DESC
                  CRN of the root key that is in the KMS instance
                  created by the user. It can either be Key Protect
                  or Hyper Protect Crypto Services(recommended)
                DESC
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
  # Only Terraform 1.2 can connect to Ubuntu 22.
  # Ubuntu 20.04 is more widely supported
  description = "image used for the VSI data mover"
  default = ".*ubuntu.*20-04.*amd64.*"
}

variable "mover_profile" {
  description = "image used for the VSI data mover"
  default = "bx2d-16x64"
}

variable "iam_endpoint_url" {
    description = "IAM endpoint url"
    type        = string
    default     = "https://iam.cloud.ibm.com"
}

variable "profile" {
  default = null # Default depends on os_type - see locals.tf
}

variable "os_type" {
  default = "zlinux"
}