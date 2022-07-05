# Render a multi-part cloud-init config making use of the part
# above, and other source files
data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
packages:
 - jq
 - unzip
 - python3
 - python3-pip
 - libguestfs-tools
 - parted
write_files:
- path: /tmp/data_mover.zip
  encoding: b64
  content: ${filebase64(data.archive_file.data_mover.output_path)}
- path: /tmp/data_mover.env
  content: |
    cosEndpoint='https://${data.ibm_cos_bucket.cos_bucket.s3_endpoint_direct}'
    cosAPIKey='${sensitive(var.ibmcloud_api_key)}'
    cosInstanceCRN='${data.ibm_cos_bucket.cos_bucket.crn}'
    cosBucketName='${var.cos_bucket_name}'
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<EOF
#!/bin/sh
rm -rf /data_mover
mkdir /data_mover
cd /data_mover
unzip /tmp/data_mover.zip
cp /tmp/data_mover.env .env
pip3 install --no-cache-dir -r requirements.txt
#./data_mover.sh #TBD: execute when adapted to metadata
EOF
  }
}