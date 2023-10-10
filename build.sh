#!/bin/bash

function main {

    WHEREAMI=$(dirname "$0")

    print_info "Running packer build..."
    {
        set -x

        packer.io build -force \
            -on-error=abort \
            "${WHEREAMI}/packer.json"
    }
}

function print_info {
    local message="\033[0;33m$1\033[0m\n"
    printf "$message"
}

main "$@"
