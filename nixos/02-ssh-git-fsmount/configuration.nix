{ config, pkgs, ... }:
{
  imports = [
    ./module-qemu-guest.nix
  ];
  boot.loader = {
    grub = {
      device = "nodev";
      enable = true;
      efiSupport = true;
    };
    efi.canTouchEfiVariables = true;
  };
  fileSystems."/mnt/utm" = {
    device = "share";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "rw"
      "_netdev"
      "nofail"
      "auto"
    ];
  };
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  users.users.radix = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    # optional, passwd works too
    # To update hashed password:
    #     nix-shell -p mkpasswd
    #     mkpasswd -m sha-512
    hashedPassword = "$6$76G77QxOctpqBrgG$IMOqMa7/ASlZQzuq4Bjwqr6yqSxqAjDnXZpx4TmKangOXpP1lDnggVBK9lnct0/.erIPxfc9iOugLM8JhuI22/";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
      "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ foo@bar"
    ];
  };
  # Serial / Console automatic login
  services.getty.autologinUser = "radix";
  users.users.root = {
    # optional, passwd works too
    hashedPassword = "$6$rounds=4096$ppg3.acswicXUbEb$v0tu7sTjBSonjLFAhldFVnaz987e9rwW02Cnm2FYwBpfHECqEyp8Ix.Ps6V0EwlmMoPCf2q8XN3MDitYA78QU1";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
    ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    # https://nixos.wiki/wiki/SSH_public_key_authentication#SSH-server-config
    # https://superuser.com/q/894608
    settings.KbdInteractiveAuthentication = false;
    settings.PasswordAuthentication = true;
  };

  programs.zsh.enable = true;

  # allow vscode to run unpatched binaries
  # programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    bindfs
  ];

  systemd.services.shared-mount = {
    description = "Mount shared folder with bindfs";
    wantedBy = [ "multi-user.target" ];
    requires = [ "mnt-utm.mount" ];
    serviceConfig = {
      Type = "forking";
      # sudo bindfs --map=501/1001:@20/@100 /mnt/utm /mnt/utm
      # run `id` on host & guest to get uid / gid values
      # GUIDE: https://dev.to/franzwong/mount-share-folder-in-qemu-with-same-permission-as-host-2980
      ExecStart = "${pkgs.bindfs}/bin/bindfs --map=501/1001:@20/@100 /mnt/utm /mnt/utm";
      # Restart = "on-failure";
    };
  };

  system.stateVersion = "25.11";
}
