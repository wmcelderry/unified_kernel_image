#!/bin/bash

function prereq()
{
    #Install pre-reqs
    apt-get install -y binutils # needed for objdump (and objcopy?)
}

function combine_initrd_images()
{
    microcode_img=
    full_img=
    concat_img=/tmp/combined.img

    cat "${microcode_img}" "${full_img}" > "${concat_img}"
}



function get_last_section_terminal_address()
{
    local file="${1}"

    #get the last section in the file's offset and size and sum, then print in hex with '0x' prefix:
    printf 0x%x "$(objdump -h "${file}"| tail -2 | head -1  | awk '{ a=sprintf("%d","0x"$3); b=sprintf("%d","0x"$4); print a+b; }')"
}

function appended_section_term_address()
{
    local base="${1}" #can be dec or hex (hex must be 0x prefixed)
    local size="${2}" #can be dec or hex (hex must be 0x prefixed)

    #simply add up and convert to a hex number.
    printf 0x%x "$(( base + size ))" 
}

function file_size_in_bytes()
{
    if [[ ! -f "${file}" ]] ; then
        echo 0x00
    else
        #NB: stat -c%s doesn't work for '/proc/cmdline'
        printf 0x%x "$(cat "${file}" | wc --bytes)"
    fi
}


function init_previous_address()
{
    previous_address="$1"
}

function mksections()
{
    local file="$1"
    local section_name="$2"
    local base="${3}"

    shift 3

    if [[ -f "${file}" ]] ; then
        echo '--add-section .'"${section_name}"'="'"${file}"'" --change-section-vma .'"${section_name}"'="'"${base}"\"
    fi
    base="$(appended_section_term_address "${base}" "$(file_size_in_bytes "${file}" )")"

    if [[ ${#*} -ge 2 ]] ; then
        echo mksections "${1}" "${2}" "${base}" "${@:3}" 1>&2
        mksections "${1}" "${2}" "${base}" "${@:3}"
    fi
}

function build_unified_kernel_image()
{
    #add the following sections to the systemd stub, and store the result as 'unified_kernal_image'
        #cmdline
        #os release info
        #splash image
        #kernel
        #initrd

    local systemd_stub_file="/usr/lib/systemd/boot/efi/linuxx64.efi.stub" 

    local cmdline_file="${1}"
    local osrel_file="${2}"
    local splash_file="${3}"
    local kernel_file="${4}"
    local initrd_file="${5}"
    local unified_kernel_image_file="${6}"


    stub_term_address="$(get_last_section_terminal_address "${systemd_stub_file}")"
    
    sections="$(mksections \
            "${cmdline_file}" "cmdline" ${stub_term_address} \
            "${osrel_file}" "osrel" \
            "${splash_file}" "splash" \
            "${kernel_file}" "kernel" \
            "${initrd_file}" "initrd")"

    echo "${sections}"
    eval objcopy \
        ${sections} \
        "${systemd_stub_file}" "${unified_kernel_image_file}"
}


function all_together()
{
    #combine_initrd_images # suspect this isn't needed in Ubuntu?

    cat /proc/cmdline > /tmp/cmdline

    build_unified_kernel_image \
        /tmp/cmdline \
        /usr/lib/os-release \
        ""\
        "/boot/vmlinuz-$(uname -r)" \
        "/boot/initrd.img-$(uname -r)" \
        "test.img"
}


all_together
