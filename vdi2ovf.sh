#!/bin/bash
set -e
#set -x

function main() {

    FORCE_DOWNLOAD="${1}"

    AMZN_LINUX2_VDI_URL="https://cdn.amazonlinux.com/os-images/2.0.20230926.0/virtualbox/amzn2-virtualbox-2.0.20230926.0-x86_64.xfs.gpt.vdi"
    AMZN_LINUX2_SHA256SUMS="https://cdn.amazonlinux.com/os-images/2.0.20230926.0/virtualbox/SHA256SUMS"

    AMZN_LINUX2_VDI_FILENAME="$(basename ${AMZN_LINUX2_VDI_URL})"
    AMZN_LINUX2_OVF_FILENAME_PREFIX="$(basename ${AMZN_LINUX2_VDI_FILENAME} .vdi)"
    WHEREAMI=$(dirname $0)
    NOW=$(date +%Y%m%d%H%M%S)
    WORKING="${WHEREAMI}/working"
    OVFS="${WHEREAMI}/output-ovf"
    SEED_VM_NAME="amzn2-temp-${NOW}"

    mkdir -p "${WORKING}"
    mkdir -p "${OVFS}"
    download_file "${AMZN_LINUX2_VDI_URL}" "${AMZN_LINUX2_SHA256SUMS}" "${WORKING}" "${FORCE_DOWNLOAD}"

    cp "${WORKING}/${AMZN_LINUX2_VDI_FILENAME}" "${WORKING}/${SEED_VM_NAME}.vdi" # copy the vdi because if we start the vm it will write to the disk

    (
        set -x

        vboxmanage internalcommands sethduuid "${WORKING}/${SEED_VM_NAME}.vdi" # Set new uuid to avoid import clashes if rerun.

        vboxmanage createvm --name "${SEED_VM_NAME}" --ostype "Linux26_64" --register
        vboxmanage modifyvm "${SEED_VM_NAME}" --memory 1024

        vboxmanage storagectl "${SEED_VM_NAME}" --name "SATA Controller" --add sata --controller IntelAHCI
        vboxmanage storagectl "${SEED_VM_NAME}" --name "IDE Controller" --add ide #Need ide to attach seed.iso

        vboxmanage storageattach "${SEED_VM_NAME}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${WORKING}/${SEED_VM_NAME}.vdi"

    )

    if [ -f "${OVFS}/${AMZN_LINUX2_OVF_FILENAME_PREFIX}.ovf" ]; then
        rm -f "${OVFS}/${AMZN_LINUX2_OVF_FILENAME_PREFIX}.ovf"
        rm -f "${OVFS}/${AMZN_LINUX2_OVF_FILENAME_PREFIX}-disk001.vmdk"
    fi

    (
        set -x
        vboxmanage export "${SEED_VM_NAME}" --output "${OVFS}/${AMZN_LINUX2_OVF_FILENAME_PREFIX}.ovf"

    )

    echo "Succesfully created ovf ${OVFS}/${AMZN_LINUX2_OVF_FILENAME_PREFIX}.ovf"
    echo "cleaning up.."
    (
        set -x
        vboxmanage unregistervm "${SEED_VM_NAME}" --delete

    )

    rm -f "${WORKING}/${SEED_VM_NAME}.vdi"

}

function download_file() {
    local url=$1
    local sha256sums=$2
    local working=$3
    local force=$4

    local filename=$(basename "$url")

    local sha256sum=$(curl -s "${sha256sums}" | grep "${filename}" | awk '{print $1}')

    echo "$sha256sum"
    if [ -f "${working}/${filename}" ] && [ "$force" != "true" ]; then
        local existing_sha256sum=$(sha256sum "${working}/${filename}" | awk '{print $1}')
        echo "$existing_sha256sum"
        if [ "$existing_sha256sum" == "$sha256sum" ]; then
            echo "File already exists and checksum matches."
            return 0
        else
            echo "File already exists but checksum does not match. Redownloading..."
        fi
    fi
    curl -o "${working}/${filename}" "$url"
    local downloaded_sha256sum=$(sha256sum "${working}/${filename}" | awk '{print $1}')
    if [ "$downloaded_sha256sum" != "$sha256sum" ]; then
        echo "Checksum verification failed. Please try again."
        return 1
    fi
    echo "File downloaded successfully."
}

main "$@"
