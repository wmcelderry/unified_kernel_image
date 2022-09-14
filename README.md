# What's this all about #
This project is the foundation for creating a Unified Kernel Image in Ubuntu.

## Why? ##
This may be useful for various reasons, but one reason is to ensure that booting a modified initrd doesn't then unlock the LUKS container using a TPM key, which would expose your encrypted data to attackers without them even requiring a password.

## Expand on that please! ##
In a normal boot process, the BIOS provides a minimal 'root of trust', it 'measures' the full BIOS, the BIOS measures the EFI boot process and the chain can continue up.

In practice that may mean that the kernel is measured, but the initrd is not, which would mean that changing the initrd would not require authentication - or to say it the other way around, an attacker could change the initrd and then get access to the system without needing a password.

## How does this protect the system? ##
A Unified Kernel Image prevents that: it combines the kernel image, initrd, command line and such into one file, and they are all measured together.  Any change ensures that the PCR value changes, and (if the TPM key was sealed against the specific value of a changed PCR) the TPM cannot be used to unseal the key LUKS.

## Questions ##
### Does that mean that the system is locked to a specific Kernel / initrd / commandline forever when using TPM to unlock a LUKS container!? ###
Nope!  It does mean that the system will not automatically update (the system would continue to download new kernels and create new initrd images and update the grub config, but your system doesn't use grub anymore, so it won't change what you are actually booting!)
That's probably a good thing: you need to add a new key for the new kernel/initrd to automatically unlock - so you'll need to manually:
    1. create a new unified kernal image (UKI)
    2. add that to the UEFI bootloader menu
    3. boot in to the new UKI (this will require manually unlocking the LUKS container)
    4. systemd-cryptenroll again to allow the TPM to unlock automatically
unlock when they change - someone will have to type a LUKS passphrase on the command line, then re-enroll the key sealed against the new PCRs

### Does that mean you can get rid of grub?  remove the unencrypted /boot? ###
Yes - in theory.  Let us know how you get on in practice!





# How to use this repo #
This repo is still under development - the commands are very simple and work, but the kernel and paths are all hardcoded (to match the currently executing kernel version - though you can probably change it trivially).


```
sudo ./mkunified_kernel.sh
```

this is currently set up to capture your current environment and make a UKI.  specifically that means it:
 - captures your current commandline from /proc/cmdline
 - captures your /usr/lib/os-release
 - doesn't use a splash image (though the system seems to default)
 - capture the current kernel from `/boot/vmlinuz-$(uname -r)`
 - capture the current initrd from `/boot/initrd.img-$(uname -r)`
 - create a new file in your current working directory called `test.img`


To use the file:
 - copy it to your UEFI system partition
 - add a bootloader entry somehow (through your BIOS - though there's are other tools)
 - reboot in to the new image to confirm it works!
