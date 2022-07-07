#!/usr/bin/env -S python3 -u
import json
import ibm_boto3
from ibm_botocore.client import Config, ClientError
from dotenv import load_dotenv
import os
import os.path
import gzip
from multiprocessing import Pool
import re
from pathlib import Path
import requests
import shlex
import subprocess
import gzip
import shutil
import uuid

load_dotenv()

METADATA_URL = "http://169.254.169.254"
METADATA_VERSION = "2022-06-28"

COS_ENDPOINT = os.environ.get('cosEndpoint')
COS_API_KEY = os.environ.get('cosAPIKey')
COS_INSTANCE_CRN = os.environ.get('cosInstanceCRN')
COS_BUCKET_NAME = os.environ.get('cosBucketName')
CUSTOM_IMAGE_NAME = os.environ.get('customImageName')
CUSTOM_IMAGE_PATH = f"/volumes/qcow2/{CUSTOM_IMAGE_NAME}.qcow2"

METADATA_FILE = 'image-metadata.json'
DEVMAP_FILE = 'devmap'
VOLUME_DIRECTORIES = '/volumes/'
BOOT_VOLUME_DIRECTORY = VOLUME_DIRECTORIES+'boot/' # Trailing slashes
DATA_VOLUME_DIRECTORY = VOLUME_DIRECTORIES+'data/' # Trailing slashes

cos = ibm_boto3.resource('s3',
    ibm_api_key_id=COS_API_KEY,
    ibm_service_instance_id=COS_INSTANCE_CRN,
    config=Config(signature_version='oauth'),
    endpoint_url=COS_ENDPOINT)


def pull_metadata_file():
    '''
    Pulls the metadata file from a COS bucket, and returns it.
    '''
    metadata_file = get_item(COS_BUCKET_NAME, METADATA_FILE)
    with open(BOOT_VOLUME_DIRECTORY + '../image-metadata.json', 'wb') as file:
        file.write(get_item(COS_BUCKET_NAME, METADATA_FILE).read())
    return metadata_file


def pull_devmap():
    '''
    Pulls the devmap file from a COS bucket, and saves it to disk.
    '''
    with open(BOOT_VOLUME_DIRECTORY + 'devmap', 'wb') as file:
        file.write(get_item(COS_BUCKET_NAME, DEVMAP_FILE).read())
    os.chown(BOOT_VOLUME_DIRECTORY + 'devmap', 999, 999)


def get_item(bucket_name, item_name):
    '''
    For a given bucket name and item name (file name), return the contents of that file, 
    as a StreamingBody object.
    '''
    global bucket_contents
    print('Retrieving item from bucket: {0}, key: {1}'.format(bucket_name, item_name))
    try:
        if item_name in get_bucket_contents(COS_BUCKET_NAME):
            return cos.Object(bucket_name, item_name).get()['Body']
        else:
            exit('File {0} not found in bucket'.format(item_name))
    except ClientError as ce:
        print('CLIENT ERROR: {0}\n'.format(ce))
    except Exception as e:
        print('Unable to retrieve file contents: {0}'.format(e))


def get_bucket_contents(bucket_name):
    '''
    Take a name of a bucket and return a list of file names: items in that bucket.
    '''
    print('Retrieving bucket contents from: {0}'.format(bucket_name))
    try:
        files = cos.Bucket(bucket_name).objects.all()
        return [file.key for file in files]
    except ClientError as be:
        print('CLIENT ERROR: {0}\n'.format(be))
    except Exception as e:
        print('Unable to retrieve bucket contents: {0}'.format(e))


def parse_metadata_file(file):
    '''
    Pass the JSON file (from COS) to parse.
    
    Output is a list of volumes from WIB.
    '''
    try:
        metadata = json.load(file)
        return metadata['volumes']
    except (OSError, IOError) as e:
        exit('Unable to open metadata file')


def fix_path_data_volume_in_devmap(data_vol_part_uuid, volumes):
    '''
    Takes a list of (data) volume names, finds the device in the devmap, 
    and removes that mountpoint name. Cleans up after itself by removing 
    the temp file and overwriting the devmap file.
    '''
    with open(BOOT_VOLUME_DIRECTORY + 'devmap', 'r') as devmap, open(BOOT_VOLUME_DIRECTORY + 'devmap_tmp', 'w') as devmap_tmp:
        for line in devmap:
            for volume in volumes:
                line = re.sub(r'/volumes/' + volume, f'/volume_{data_vol_part_uuid}/{volume}', line)
            devmap_tmp.write(line)
    os.chown(BOOT_VOLUME_DIRECTORY + 'devmap_tmp', 999, 999)
    os.remove(BOOT_VOLUME_DIRECTORY + 'devmap')
    os.rename(BOOT_VOLUME_DIRECTORY + 'devmap_tmp', BOOT_VOLUME_DIRECTORY + 'devmap')


def get_volume_file(volume):
    '''
    Get all the volume files from volumes list, 
    decompressing them, and writing to disk.
    '''
    if volume['boot']:
        output_directory = BOOT_VOLUME_DIRECTORY

        # Create the dotfiles
        Path(output_directory + '.zosprepared').touch(exist_ok=True)
        os.chown(output_directory + '.zosprepared', 999, 999)
    else:
        output_directory = DATA_VOLUME_DIRECTORY

        # Create the dotfiles
        Path(output_directory + '.zcsc').touch(exist_ok=True)
        os.chown(output_directory + '.zcsc', 999, 999)


    if volume['compression'] == 'gzip':        
        output_file = output_directory + volume['name']
        print(f"Fetch {volume['name']} gzip volume from COS and uncompress to {output_file}")
        cos_file = get_item(COS_BUCKET_NAME, volume['file-name'])
        with gzip.GzipFile(fileobj=cos_file) as f_gzip:
           with open(output_file, 'wb') as f_out:
               shutil.copyfileobj(f_gzip, f_out)
        print (f"Done fetching {volume['name']} to {output_file}")
        os.chown(output_file, 999, 999)

        if not volume['boot']:
            return volume['name']
    else:
        exit("Compression algorithm {} is not supported for file '{}'"
            .format(volume['compression'], volume['file-name']))

# Metadata token            
def get_token():
    # Making a PUT request
    response = requests.put(METADATA_URL + "/instance_identity/v1/token?version=" + METADATA_VERSION,
                    headers = {
                        "Metadata-Flavor": "ibm",
                        "Accept": "application/json"
                    },
                    json = {
                        "expires_in": 300
                    })
    if response.status_code > 399:
        response.raise_for_status()
    response_data = response.json()
    return response_data["access_token"]

# Metadata for instance
def get_instance():
    # Making a GET request
    response = requests.get(METADATA_URL + "/metadata/v1/instance?version=" + METADATA_VERSION,
                    headers = {
                        "Metadata-Flavor": "ibm",
                        "Accept": "application/json",
                        "Authorization": "Bearer " + get_token()
                    })
    if response.status_code > 399:
        response.raise_for_status()
    response_data = response.json()
    return response_data

def get_instance_volume_dict(instance_metadata):
    volumes = {}
    for volume in instance_metadata["volume_attachments"][1:]:
        # Skipping first volume which is the linux boot volume we do not need
        volumes[ volume["name"] ] = volume
    return volumes

# Wait for volumes in metadata and get their paths
def get_volumes_dev_paths(volumes):
    all_found = False
    while not all_found:
        all_found = True
        for (name, volume) in volumes.items():
            if "dev_path" in volume:
                next
            dev_path = "/dev/disk/by-id/virtio-"+volume["device"]["id"][0:20]
            found = os.path.exists(dev_path)
            if found:
                volume["dev_path"] = dev_path
            all_found &= found 
            print(f"Volume {name} with path {dev_path} - {'FOUND' if found else 'NOT FOUND'}")


def format_and_mount(volume):
    dev_path   = volume["dev_path"]
    mount_path = "/volumes/" + volume["name"]
    volume["mount_path"] = mount_path
    filesystem_uuid = uuid.uuid4()

    print (f"Formating {dev_path} with UUID {filesystem_uuid} and mounting at {mount_path}")
    subprocess.call(shlex.split(f"umount {mount_path}"))
    subprocess.check_call(shlex.split(f"mkdir -p {mount_path}"))
    #subprocess.check_call(shlex.split(f"parted -s {dev_path} mklabel gpt mkpart primary ext4 0% 100%"))
    #subprocess.check_call(shlex.split(f"udevadm settle"))
    subprocess.check_call(shlex.split(f"mkfs.ext2 {dev_path} -F -U {filesystem_uuid}"))
    subprocess.check_call(shlex.split(f"mount {dev_path} {mount_path}"))
            
    return filesystem_uuid


if __name__ == '__main__':

    # Retrive instance metadata
    instance_data = get_instance()
    instance_volumes = get_instance_volume_dict(instance_data)
    #print(instance_volumes)

    # Wait for the volumes and then format them
    get_volumes_dev_paths(instance_volumes)

    # Format boot volume
    format_and_mount(instance_volumes["boot"])
    subprocess.check_call(shlex.split(f"e2label {instance_volumes['boot']['dev_path']} zvolumes")) #TBD: is the label required?

    # Format data volume
    data_vol_part_uuid = format_and_mount(instance_volumes["data"])

    # Define 5 concurrent processes to get the volume files with
    p = Pool(10)

    # Pull the metadata file from the COS bucket and get 
    # the boot volume and data volume names
    metadata_file = pull_metadata_file()
    volumes = parse_metadata_file(metadata_file)

    # Pull devmap
    pull_devmap()

    # Download the volume files in parallel, and return a list of the data volumes
    data_volumes = p.map(get_volume_file, volumes)

    # data_volumes list will include None values where the get_volume_file 
    # function returned None, when it was a boot volume. 
    # Use the list comprehension here to remove those None values.
    fix_path_data_volume_in_devmap(data_vol_part_uuid, [i for i in data_volumes if i])

    # Rename the data volume files and set their uid/gid
    # TBD - needs rework
    # i = 0
    # for file in os.listdir(DATA_VOLUME_DIRECTORY):
    #     if not file.startswith('.'):
    #         try:
    #             os.chown(DATA_VOLUME_DIRECTORY + file, 999, 999)
    #         except PermissionError:
    #             exit("Unable to set data volume file '{}' to uid/gid 999:999".format(file))
    #         os.rename(DATA_VOLUME_DIRECTORY + file, DATA_VOLUME_DIRECTORY + 'ZVOL{:0>4}'.format(i))
    #         i = i + 1

    
    # Create qcow2 from boot disk
    subprocess.check_call(shlex.split(f"umount /volumes/boot"))
    format_and_mount(instance_volumes["qcow2"])
    print("Convertig boot volume to qcow2 " + CUSTOM_IMAGE_PATH)
    # slow option compressing and sparsifying file
    #subprocess.check_call(shlex.split(f"virt-sparsify --compress --convert qcow2 --tmp /volumes/qcow2/ --check-tmpdir=continue {instance_volumes['boot']['dev_path']} {CUSTOM_IMAGE_PATH}"))
    # fast option removing zeroes - I do not use compress (-c) as it bottlenecks on a single CPU while IO is iddle
    subprocess.check_call(shlex.split(f"qemu-img convert -pO qcow2 {instance_volumes['boot']['dev_path']} {CUSTOM_IMAGE_PATH}"))
    print("Done convertig boot volume to qcow2 " + CUSTOM_IMAGE_PATH)


    