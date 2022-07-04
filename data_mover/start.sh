#!/bin/bash -

volume_size="${WAZI_BLOCK_SIZE:-1000G}"
output_name="${WAZI_IMAGE_NAME:-wazi-custom-$(date '+%Y%m%d-%H%M%I')}"
project_dir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd)/"

_show_help () {
    printf -- "Usage: data-mover [OPTIONS]\n\n"
    printf "Options:\n"
    printf -- "-v: volume size to find and mount (1000G)\n"
    printf -- "-o: output qcow2 image name, without suffix\n"

    exit 0
}

_report_error () {
    printf "$(basename $0): $1.\n" >&2
    exit 1
}

# Parse single-letter options
while getopts :v:o:h opt; do
    case "$opt" in
        v)    volume_size="$OPTARG"
              ;;
        o)    output_name="$OPTARG"
              ;;
        h)    _show_help
              ;;
        '?')  _report_error "invalid option $OPTARG. Try '-h' for more info"
              ;;
    esac
done

# Forget single-letter options now, put main options out in front
shift $((OPTIND-1))

boot_volumes="/boot-volumes/"
data_volumes="/data-volumes/"

boot_volume_device="/dev/$(lsblk | awk -v size="${volume_size}" '$6=="disk"&&$4==size{print $1}' | awk 'FNR==1{print $1}')"
data_volume_device="/dev/$(lsblk | awk -v size="${volume_size}" '$6=="disk"&&$4==size{print $1}' | awk 'FNR==2{print $1}')"

apt install -y python3 python3-pip libguestfs-tools parted

pip3 install --no-cache-dir -r "${project_dir}requirements.txt"

rm -rf "${boot_volumes}" "${data_volumes}"
mkdir -p "${boot_volumes}" "${data_volumes}"

# Mount the fast attached storage for boot volumes
parted -s "${boot_volume_device}" mklabel gpt mkpart primary ext4 0% 100%
mkfs.ext4 "${boot_volume_device}1" -F

# Mount the attached storage for data volumes
parted -s "${data_volume_device}" mklabel gpt mkpart primary ext4 0% 100%
mkfs.ext4 "${data_volume_device}1" -F

mount -t ext4 "${boot_volume_device}1" "${boot_volumes}"
mount -t ext4 "${data_volume_device}1" "${data_volumes}"

mkdir -p "${boot_volumes}source" "${boot_volumes}tmp" "${data_volumes}"

for dir in "${boot_volumes}lost+found/" "${data_volumes}lost+found/"; do
    if [[ -d "$dir" ]]; then
        rmdir "$dir"
    fi
done

"${project_dir}runner.sh"