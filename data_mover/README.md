# z/OS dev/test VPC Custom Image Builder

This set of scripts and automation can be used in conjunction with Wazi Image Builder to create a custom image for use with Wazi-aaS Virtual Server Instances, in IBM Cloud. Wazi Image Builder, after selecting a set of z/OS volumes, will upload them to Cloud Object Storage as ECKD files. These scripts can then process these files, split them between boot and data volumes, and create a qcow2 image from the boot volumes. This qcow2 image is then uploaded back to the Cloud Object Storage bucket, to be used to create a custom image in a VPC environment.

**NOTE:** Usually this script will be called from the Terraform automation in the above folder. For debugging you can also run it manually.

## How to Use the Scripts

1. ssh into the VSI you created with Terraform
2. `cd /data_mover`
3. If you did not create the VSI with Terraform you will need to create an `.env` file with the COS configuration (see bellow). You will also need to run `pip3 install --no-cache-dir -r requirements.txt`
4. `data_mover.py` - this will format the VSI data volumes, fetch the volume files from COS and finally create a qcow2 boot image
5. `upload.py` - this uploads the qcow2 image to COS

## Deployment

The qcow2 file created will be uploaded to the same Cloud Object Storage bucket where the volume files were pulled from. From this, a custom image in the VPC can be defined.

Take a snapshot of the block storage instance holding the data volumes, to use as the main source for future Wazi-aaS (z/OS for dev/test) VSI creation.

Create a Wazi-aaS instance, using this custom image, and define an additional block storage device from the snapshot taken of the data volumes. Confirm in the syslog, SDSF operator console, or ISMF, that all volumes are present. The block storage used for the boot volumes can now be deleted once the running system is verified.

## Configuration

Pass the following environment variables:

```bash
cosEndpoint=''     # COS endpoint to use
cosAPIKey=''       # COS API key
cosInstanceCRN=''  # COS instance CRN
cosBucketName=''   # COS bucket name
customImageName='' # Name of the boot image to be uploaded to COS
```

These lines above can be placed in a `.env` file for dewvelopment. When not developing or testing the script, set the environment variables above and the script will pick them up instead.
