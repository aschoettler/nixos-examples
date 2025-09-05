# This file is a nixos module which handles the guest-side behavior for mounting a shared folder from macos.
# The QEMU VM should be launched with flags like this to configure the host-side:
#   -fsdev local,id=virtfs0,path=/absolute/path/to/host/folder,security_model=mapped \
#   -device virtio-9p-pci,fsdev=virtfs0,mount_tag=share

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # guide: https://dev.to/franzwong/mount-share-folder-in-qemu-with-same-permission-as-host-2980
  environment.systemPackages = with pkgs; [ bindfs ];
  systemd.services = {
    mount-utm-share = {
      description = "Mount 9P share from UTM host";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # assumes device called "share"
        ExecStart = "${pkgs.util-linux}/bin/mount -t 9p -o trans=virtio,version=9p2000.L,rw share /mnt/utm";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    remap-utm-share = {
      description = "Remap permissions for UTM share with bindfs";
      wantedBy = [ "multi-user.target" ];
      requires = [ "mount-utm-share.service" ];
      after = [ "mount-utm-share.service" ];
      serviceConfig = {
        Type = "simple";
        # use values obtained from `id` on host and guest
        ExecStart = "${pkgs.bindfs}/bin/bindfs -f --map=501/1000:@20/@100 /mnt/utm /mnt/utm";
      };
    };
  };

}

