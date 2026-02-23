#!/usr/bin/env bash
# Hardware and environment detection utilities

is_docker() {
    [[ -f /.dockerenv ]] || [[ "${INSTALLER_MODE:-}" == "docker" ]]
}

is_efi() {
    [[ -d /sys/firmware/efi ]]
}

get_cpu_vendor() {
    local vendor
    vendor=$(grep -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}')
    case "${vendor}" in
        GenuineIntel) echo "intel" ;;
        AuthenticAMD) echo "amd" ;;
        *) echo "unknown" ;;
    esac
}

get_ucode_package() {
    local vendor
    vendor=$(get_cpu_vendor)
    case "${vendor}" in
        intel) echo "intel-ucode" ;;
        amd) echo "amd-ucode" ;;
        *) echo "" ;;
    esac
}

get_disk_partition() {
    local disk="$1"
    local part_num="$2"

    if [[ "${disk}" == *nvme* ]] || [[ "${disk}" == *mmcblk* ]]; then
        echo "${disk}p${part_num}"
    else
        echo "${disk}${part_num}"
    fi
}

list_disks() {
    lsblk -dpno NAME,SIZE,TYPE | grep 'disk' | awk '{print $1, $2}'
}

get_gpu_driver() {
    local gpu
    gpu=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display')
    case "${gpu,,}" in
        *nvidia*) echo "nvidia" ;;
        *amd*|*radeon*) echo "amd" ;;
        *intel*) echo "intel" ;;
        *) echo "unknown" ;;
    esac
}
