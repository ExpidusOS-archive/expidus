{ config, lib, pkgs, ... }:
{
  boot.initrd.kernelModules = [ "virtio_gpu" "virtio_pci" ];
  mobile = {
    device = {
      name = "uefi-aarch64";
      identity = {
        name = "UEFI build (aarch64)";
        manufacturer = "Generic";
      };
      supportLevel = "supported";
    };
    hardware = {
      soc = "generic-aarch64";
      screen = {
        width = 720;
        height = 1280;
      };
      ram = 1024 * 2;
    };
    system.type = "uefi";
    boot = {
      serialConsole = "ttyAMA0";
      defaultConsole = null;
      stage-1 = {
        gui.waitForDevices.enable = lib.mkDefault true;
        bootlog.enable = false;
        kernel = {
          useNixOSKernel = lib.mkDefault true;
          additionalModules = [
            # Some SATA/PATA stuff.
            "ahci"
            "sata_nv"
            "sata_via"
            "sata_sis"
            "sata_uli"
            "ata_piix"
            "pata_marvell"

            # Standard SCSI stuff.
            "sd_mod"
            "sr_mod"

            # SD cards and internal eMMC drives.
            "mmc_block"

            # Support USB keyboards, in case the boot fails and we only have
            # a USB keyboard, or for LUKS passphrase prompt.
            "uhci_hcd"
            "ehci_hcd"
            "ehci_pci"
            "ohci_hcd"
            "ohci_pci"
            "xhci_hcd"
            "xhci_pci"
            "usbhid"
            "hid_generic" "hid_lenovo" "hid_apple" "hid_roccat"
            "hid_logitech_hidpp" "hid_logitech_dj"

            # For LVM.
            "dm_mod"

            # SATA/PATA support.
            "ahci"

            "ata_piix"

            "sata_inic162x" "sata_nv" "sata_promise" "sata_qstor"
            "sata_sil" "sata_sil24" "sata_sis" "sata_svw" "sata_sx4"
            "sata_uli" "sata_via" "sata_vsc"

            "pata_ali" "pata_amd" "pata_artop" "pata_atiixp" "pata_efar"
            "pata_hpt366" "pata_hpt37x" "pata_hpt3x2n" "pata_hpt3x3"
            "pata_it8213" "pata_it821x" "pata_jmicron" "pata_marvell"
            "pata_mpiix" "pata_netcell" "pata_ns87410" "pata_oldpiix"
            "pata_pcmcia" "pata_pdc2027x" "pata_qdi" "pata_rz1000"
            "pata_serverworks" "pata_sil680" "pata_sis"
            "pata_sl82c105" "pata_triflex" "pata_via"
            "pata_winbond"

            # SCSI support (incomplete).
            "3w-9xxx" "3w-xxxx" "aic79xx" "aic7xxx" "arcmsr"

            # USB support, especially for booting from USB CD-ROM
            # drives.
            "uas"

            # Firewire support.  Not tested.
            "ohci1394" "sbp2"

            # Virtio (QEMU, KVM etc.) support.
            "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_balloon" "virtio_console"

            # VMware support.
            "mptspi" "vmw_balloon" "vmwgfx" "vmw_vmci" "vmw_vsock_vmci_transport" "vmxnet3" "vsock"

            # Hyper-V support.
            "hv_storvsc"

            # Mouse
            "mousedev"
          ];
        };
      };
    };
    generatedFilesystems.boot.size = lib.mkForce (pkgs.image-builder.helpers.size.MiB 256);
    quirks.supportsStage-0 = lib.mkDefault false;
  };
}
