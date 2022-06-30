import json
import ibm_boto3
from ibm_botocore.client import Config, ClientError
from dotenv import load_dotenv
import os
import gzip
from multiprocessing import Pool
import re
from pathlib import Path

load_dotenv()

COS_ENDPOINT = os.environ.get('cosEndpoint')
COS_API_KEY = os.environ.get('cosAPIKey')
COS_INSTANCE_CRN = os.environ.get('cosInstanceCRN')
COS_BUCKET_NAME = os.environ.get('cosBucketName')

METADATA_FILE = 'image-metadata.json'
DEVMAP_FILE = 'devmap'
BOOT_VOLUME_DIRECTORY = '/boot-volumes/source/' # Trailing slashes
DATA_VOLUME_DIRECTORY = '/data-volumes/'

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


def remove_data_volume_from_devmap(volumes):
    '''
    Takes a list of (data) volume names, finds the device in the devmap, 
    and removes that mountpoint name. Cleans up after itself by removing 
    the temp file and overwriting the devmap file.
    '''
    with open(BOOT_VOLUME_DIRECTORY + 'devmap', 'r') as devmap, open(BOOT_VOLUME_DIRECTORY + 'devmap_tmp', 'w') as devmap_tmp:
        for line in devmap:
            for volume in volumes:
                line = re.sub(r'/volumes/' + volume, '', line)
            devmap_tmp.write(line)
    os.remove(BOOT_VOLUME_DIRECTORY + 'devmap')
    os.rename(BOOT_VOLUME_DIRECTORY + 'devmap_tmp', BOOT_VOLUME_DIRECTORY + 'devmap')


def get_volume_file(volume):
    '''
    Get all the volume files from volumes list, 
    decompressing them, and writing to disk.
    '''
    if volume['boot']:
        output_directory = BOOT_VOLUME_DIRECTORY
    else:
        output_directory = DATA_VOLUME_DIRECTORY


    if volume['compression'] == 'gzip':
        output_file = output_directory + volume['name'] + '.gz'
        cos_file = get_item(COS_BUCKET_NAME, volume['file-name']).iter_chunks(chunk_size=100000000)
        with open(output_file, 'wb') as gf:
            while True:
                try:
                    gf.write(next(cos_file))
                except StopIteration:
                    break
        print('Gunzipping {}'.format(output_file))
        os.system('gunzip {}'.format(output_file))

        if not volume['boot']:
            return volume['name']
    else:
        exit("Compression algorithm {} is not supported for file '{}'"
            .format(volume['compression'], volume['file-name']))
            

if __name__ == '__main__':
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
    remove_data_volume_from_devmap([i for i in data_volumes if i])

    # Rename the data volume files and set their uid/gid
    i = 0
    for file in os.listdir(DATA_VOLUME_DIRECTORY):
        if not file.startswith('.'):
            try:
                os.chown(DATA_VOLUME_DIRECTORY + file, 999, 999)
            except PermissionError:
                exit("Unable to set data volume file '{}' to uid/gid 999:999".format(file))
            os.rename(DATA_VOLUME_DIRECTORY + file, DATA_VOLUME_DIRECTORY + 'ZVOL{:0>4}'.format(i))
            i = i + 1

    # Create the dotfiles
    Path(BOOT_VOLUME_DIRECTORY + '.zosprepared').touch(exist_ok=True)
    os.chown(BOOT_VOLUME_DIRECTORY + '.zosprepared', 999, 999)
    Path(DATA_VOLUME_DIRECTORY + '.zcsc').touch(exist_ok=True)
    os.chown(DATA_VOLUME_DIRECTORY + '.zcsc', 999, 999)

    