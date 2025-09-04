{
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    # load virtio kernel modules
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/qemu-guest.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # start qemu guest agent
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  environment.systemPackages = with pkgs; [
    spice-vdagent # client mouse mode, copy-paste, automatic resolution adjustment, multiple display support
    _9pfs # FUSE-based client of the 9P network filesystem protocol
    _9ptls # mount.9ptls mount helper
    tlsclient # tlsclient command line utility
    bindfs # bind and map uids and permissions
  ];

}
