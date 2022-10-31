# Image variables
variable "custom_image_name" {
  type        = string
  default     = "wazi-custom-image"
  description = "Name of the z/OS custom image that will be generated"
}

variable "custom_vsi"{
  type        = bool
  default     = false
  description = "Builds VSI using the custom image"
}
variable "custom_image_os" {
  default     = "zos-2-4-s390x-dev-test-byol"
  description = "OS for generated image - it must match the OS uploaded to COS"
}

# Target location for image
variable "region" {
  type        = string
  default     = "ca-tor"
  description = "Region to run the VSI doing the conversion. Custom image will be stored here"
}

variable "zone" {
  type        = string
  default     = "1"
  description = "Zone for the VSI - data volumes will be stored here"
}

# Source COS bucket with the CKD files
variable "cos_bucket_region" {
  type        = string
  description = "Region of the COS bucket"
}

variable "cos_instance_name" {
  type        = string
  description = "Name of the COS instance that holds the COS bucket"
}

variable "cos_bucket_name" {
  type        = string
  description = <<-DESC
                 Name of the COS bucket that contains the z/OS volumes archive 
                 files uploaded by on-prem Wazi Image Builder
                DESC
}

variable "cos_resource_group" {
  type        = string
  default     = "Default"
  description = "Resource group of the COS instance"
}

variable "cos_endpoint" {
  type        = string
  default     = "null"
  description = "COS service Endpoint. By default, cos bucket s3 direct end point will be used"
}

variable "encryption_type" {
  type        = string
  default     = "user_managed"
  description = <<-DESC
                 If the value is 'user_managed', and 'customer_root_key_crn' holds a valid 
                 root key CRN, then the block storage volume and the snapshot will be 
                 encrypted by root key that is provided. 

                 If the value is "provider_managed", then the block storage volume and the 
                 snapshot will be encrypted automatically with the key chosen by IBM. 

                 NOTE: If the value is "user_managed", and the 'customer_root_key_crn' 
                 is having a default value of **null**, then, it defaults to 'provider_managed'
                DESC

  validation {
    condition     = ( var.encryption_type == "user_managed"  ||
                      var.encryption_type == "provider_managed" )

    error_message = "Value of encryption_type must be either user_managed or provider_managed."
  }
}

variable "customer_root_key_crn" {
  type        = string
  default     = "null"
  description = <<-DESC
                  CRN of the root key that is in the KMS instance created by the user. 
                  It can either be in Key Protect or Hyper Protect Crypto Services. 
                  It is **highly recommended** that Hyper Protect Crypto Services be used. 

                  If the 'encryption_type' is 'user_managed', and 'customer_root_key_crn' 
                  holds a valid root key CRN, then the block storage volume and the snapshot 
                  will be encrypted by root key that is provided. 

                  NOTE: Leaving the default value of **null** for this will result in 
                  'encryption_type' defaulting to provider_managed'.
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
  default     = "region_location"
  description = "bucket type"
}

# ssh private key to establish a session with data mover VSI
variable "ssh_private_key" {
  type        = string
  default     = "null"
  description = <<-DESC
                  This is needed for terraform to establish a ssh session with 
                  the VSI that is executing the data_mover script. Post 
                  establishing the ssh session, it would wait for certain service 
                  to be finished on the VSI, and that gives a go ahead to terraform 
                  to create other resources. Because of this, there is no real need 
                  to pass in a user generated ssh key, and it is recommended that 
                  the default be used and, terraform will then create pair of keys 
                  automatically
                DESC
}

# This is needed to be passed-in while creating the data mover VSI
variable "ssh_public_key" {
  type        = string
  default     = "null"
  description = <<-DESC
                  This is needed while creating an instance of data mover VSI. 
                  When terraform establishes the ssh session with the VSI, 
                  the passed-in private key is matched with this public key. 
                  Because of this, there is no real need to pass in a user 
                  generated ssh key, and it is recommended that the default 
                  be used, and terraform will then create pair of keys 
                  automatically
                DESC
}

variable "total_ipv4_address_count" {
    default     = 256
    description = "total IPs for subnetwork"
}

variable "mover_image_name" {
  # Regular expresions allowed
  # Only Terraform 1.2 can connect to Ubuntu 22.
  # Ubuntu 20.04 is more widely supported
  default = ".*ubuntu.*20-04.*amd64.*"
  description = "image used for the VSI data mover"
}

variable "mover_profile" {
  default     = "bx2d-16x64"
  description = "image used for the VSI data mover"
}

variable "iam_endpoint_url" {
    type        = string
    default     = "https://iam.cloud.ibm.com"
    description = "IAM endpoint url"
}
