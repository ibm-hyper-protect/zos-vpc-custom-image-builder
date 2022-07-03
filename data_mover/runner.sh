#!/bin/bash -

_show_help () {
    printf -- "Usage: data-mover [OPTIONS]\n\n"
    printf "Options:\n"
    printf -- "-s: create a compressed qcow2 file. Slow, but a smaller image\n"
    printf -- "-v: volume size to find and mount (1000G)\n"
    printf -- "-o: output qcow2 image name, without suffix\n"

    exit 0
}

_report_error () {
    printf "$(basename $0): $1.\n" >&2
    exit 1
}

################################################################################
## Option parsing
################################################################################

slow="${WAZI_SLOW:-false}"
volume_size="${WAZI_BLOCK_SIZE:-1000G}"
output_name="${WAZI_IMAGE_NAME:-wazi-custom-$(date '+%Y%m%d-%H%M%I')}"
project_dir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd)/"

# Parse single-letter options
while getopts :sv:o:h opt; do
    case "$opt" in
        s)    slow=true
              ;;
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

# Transfer image data from COS to these block storage devices
python3 "${project_dir}data_mover.py"

# Create the qcow2 image
cd "${boot_volumes}"

if [[ "$slow" == true ]]; then
    printf "Creating compressed qcow2 file...\n"
    virt-make-fs --label=zvolumes -- "${boot_volumes}source" "${boot_volumes}${output_name}.raw"
    virt-sparsify --compress --convert qcow2 --tmp "${boot_volumes}tmp" --check-tmpdir continue -- "${boot_volumes}${output_name}.raw" "${boot_volumes}${output_name}.qcow2"
else
    printf "Creating qcow2 file...\n"
    virt-make-fs --label=zvolumes --format=qcow2 --type=ext2 --size=+300M -- "${boot_volumes}source" "${boot_volumes}${output_name}.qcow2"
fi

rm -rf "${boot_volumes}tmp"

python3 "${project_dir}upload.py" -i "${project_dir}${output_name}.qcow2"