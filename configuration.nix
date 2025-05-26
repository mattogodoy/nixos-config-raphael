# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "intel_iommu=on" ];
  boot.kernelModules = [ "gasket" "apex" ]; # Enable kernel modules for PCIe Coral
  boot.extraModulePackages = with config.boot.kernelPackages; [
    pkgs.linuxKernel.packages.linux_6_6.gasket
  ];

  networking.hostName = "raphael";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "es";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.matto = {
    isNormalUser = true;
    description = "Matto";
    extraGroups = [ "networkmanager" "wheel" "docker" "apex" "plugdev" ]; # apex and plugdev are for the Coral TPU
    packages = with pkgs; [];
  };

  # Create plugdev group if it doesn't exist for Coral TPU
  users.groups.plugdev = {};

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    libedgetpu # Coral TPU runtime
    pciutils
    usbutils
    vim
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs = {
    bash = {
      shellAliases = {
        # NixOS
        nrs = "sudo nixos-rebuild switch";

        # Terminal
        ll = "ls -lah";

        # Git
        gs = "git status";
        gd = "git diff";
        gc = "git commit -a -m";
      };
    };
  };

  # Samba config
  fileSystems."/mnt/pensieve" = {
    device = "//192.168.1.90/docker-data";
    fsType = "cifs";
    options = [
      "credentials=/etc/nixos/secrets/smb-credentials"
      "uid=1000"
      "gid=100"
      "iocharset=utf8"
      "file_mode=0664"    # rw-rw-r-- (owner and group can read/write, others read-only)
      "dir_mode=0775"     # rwxrwxr-x (owner and group full access, others read/execute)
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
    ];
  };

  fileSystems."/mnt/frigate" = {
    device = "//192.168.1.90/frigate";
    fsType = "cifs";
    options = [
      "credentials=/etc/nixos/secrets/smb-credentials"
      "uid=1000"
      "gid=100"
      "iocharset=utf8"
      "file_mode=0664"    # rw-rw-r-- (owner and group can read/write, others read-only)
      "dir_mode=0775"     # rwxrwxr-x (owner and group full access, others read/execute)
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
    ];
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable Docker
  virtualisation.docker.enable = true;
  # Rootless Docker (disabled as it brings many permission errors due to NFS or SMB mounts
  #virtualisation.docker.rootless = {
  #  enable = true;
  #  setSocketVariable = true;
  #};
  # Ensure docker socket has proper permissions
  virtualisation.docker.daemon.settings = {
    group = "docker";
  };

  # Enable USB support (needed for Coral TPU communication)
  services.udev.enable = true;
  
  # Add Coral TPU udev rules
  services.udev.extraRules = ''
    # Coral TPU rules
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", ATTRS{idProduct}=="089a", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="9302", MODE="0666"
    SUBSYSTEM=="apex", MODE="0666"
  '';

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    53 # PiHole
  ];
  #networking.firewall.allowedUDPPorts = [ ];
  networking.firewall.allowedTCPPortRanges = [ { from = 8000; to = 8999; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 8000; to = 8999; } ];

  # Allow unprivileged processes to bind to port 53 (this is for PiHole to work)
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 53;

  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
