# z/OS dev/test VPC Custom Image Builder

This set of scripts and automation can be used in conjunction with Wazi Image Builder to create a custom image for use with Wazi-aaS Virtual Server Instances, in IBM Cloud. Wazi Image Builder, after selecting a set of z/OS volumes, will upload them to Cloud Object Storage as ECKD files. These scripts can then process these files, split them between boot and data volumes, and create a qcow2 image from the boot volumes. This qcow2 image is then uploaded back to the Cloud Object Storage bucket, to be used to create a custom image in a VPC environment.

## Preparations

1. [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2. `cp my-settings.auto.tfvars-template my-settings.auto.tfvars`
3. Adjust [my-settings.auto.tfvars](my-settings.auto.tfvars-template)
   - set `ibmcloud_api_key=<your API key>.
      - this will likelly require a paying account
      - you can create an API account by visiting the [IBM Cloud API keys page](https://cloud.ibm.com/iam/apikeys). Ensure you have
        selected the account you want to use before creating the key as the key will be associtated to the account you have selected
        at the time of creation.
      - If you have downloaded your `apikey.json` file from the IBM Cloud UI you may use this command:
        `export IC_API_KEY=$(cat ~/apikey.json | jq -r .apikey)`
4. `terraform init`

## Running

1. Use the Wazi image builder to upload your z/OS image to IBM Cloud Object Store (COS)
2. Adjust [my-settings.auto.tfvars](my-settings.auto.tfvars-template) with the name of the COS bucket
   - **NOTE:** there is currently a bug in the Image builder not uploading the `image-metadata.json` as json. As circumvention
     you can use the COS UI to download it and upload it again. This will correct the format.
3. `terraform apply` - this will create the VSI with the required data volumes. You might want to use the VSI serial console: the progress logs are written there by cloud init.
   - bootable qcow2 is uploaded to the COS bucket
   - data volume is created
5. Create the z/OS image from the `wazi-custom-image` qcow2 in COS and snapshots out of the remaining `wazi-custom-image-data` data volume
  - **TBD**: this will be done by `terraform apply` in following versions
6. `terraform destroy` to clean up temp resources (VSI, boot volume, data volume)


## Using the custom image

**TBD**

The steps will consist in checking out the VSI creation terraform sample and use a config file with the name of the image and data volume snapshots
as parameter. Until this is ready the data volumes have to be created manually out of the snapshots before the VSI can be then created as described
in the [VPC documentation](https://cloud.ibm.com/docs/vpc?topic=vpc-snapshots-vpc-restore)
