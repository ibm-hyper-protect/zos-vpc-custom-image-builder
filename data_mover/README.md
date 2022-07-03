# z/OS dev/test VPC Custom Image Builder

This set of scripts and automation can be used in conjunction with Wazi Image Builder to create a custom image for use with Wazi-aaS Virtual Server Instances, in IBM Cloud. Wazi Image Builder, after selecting a set of z/OS volumes, will upload them to Cloud Object Storage as ECKD files. These scripts can then process these files, split them between boot and data volumes, and create a qcow2 image from the boot volumes. This qcow2 image is then uploaded back to the Cloud Object Storage bucket, to be used to create a custom image in a VPC environment.

## How to Use the Scripts



1. ssh into the VSI you created with Terraform
2. Copy the contents of this repo to the Linux VSI, e.g.,

    ```bash
        git clone https://github.com/ibm-hyper-protect/zos-vpc-custom-image-builder
        cd zos-vpc-custom-image-builder
    ```
4. See _Configuration_ below for environment variables to set (or, parameters in a `.env` file).

4. Run `start.sh` from the clean Linux VSI to install the dependencies, mount the attached block storage instances, and then run the data mover script, and create a qcow2 file.

## Deployment

The qcow2 file created will be uploaded to the same Cloud Object Storage bucket where the volume files were pulled from. From this, a custom image in the VPC can be defined.

Take a snapshot of the block storage instnace holding the data volumes, to use as the main source for future Wazi-aaS (z/OS for dev/test) VSI creation.

Create a Wazi-aaS instance, using this custom image, and define an additional block storage device from the snapshot taken of the data volumes. Confirm in the syslog, SDSF operator console, or ISMF, that all volumes are present. The block storage used for the boot volumes can now be deleted once the running system is verified.

## Configuration

Pass the following environment variables:

```bash
cosEndpoint=''    # COS endpoint to use
cosAPIKey=''      # COS API key
cosInstanceCRN='' # COS instance CRN
cosBucketName=''  # COS bucket name
```

These lines above can be placed in a `.env` file for dewvelopment. When not developing or testing the script, set the environment variables above and the script will pick them up instead.

You can also add the following environment variables, though sensible defaults will be chosen otherwise:

```bash
WAZI_SLOW         # Default: false. true or false, fast or slow qcow2 image creation
$AZI_BLOCK_SIZE   # Default: 1000G. Size of block storage devices for boot and data, read from lsblk
WAZI_IMAGE_NAME   # Default: wazi-custom-$(date). Without suffix, name of qcow2 image
```

If you just want to test the scripts once the Linux environment has the necessary prerequisies, run `runner.sh`.
