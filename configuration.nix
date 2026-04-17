# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
	imports = [ 
	# Include the results of the hardware scan.
	./hardware-configuration.nix
	];

	# Bootloader.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;
	boot.crashDump.enable = false;

	networking.hostName = "vault"; # Define your hostname.
	# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Enable networking
	networking.networkmanager.enable = true;

	# Set your time zone.
	time.timeZone = "Europe/Athens";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";

	i18n.extraLocaleSettings = {
		LC_ADDRESS = "el_GR.UTF-8";
		LC_IDENTIFICATION = "el_GR.UTF-8";
		LC_MEASUREMENT = "el_GR.UTF-8";
		LC_MONETARY = "el_GR.UTF-8";
		LC_NAME = "el_GR.UTF-8";
		LC_NUMERIC = "el_GR.UTF-8";
		LC_PAPER = "el_GR.UTF-8";
		LC_TELEPHONE = "el_GR.UTF-8";
		LC_TIME = "el_GR.UTF-8";
	};

	# Configure keymap in X11
	services.xserver.xkb = {
		layout = "us";
		variant = "";
	};

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.erysichthon = {
		isNormalUser = true;
		description = "Constantine";
		extraGroups = [ "networkmanager" "wheel" "video" "render" ];
		packages = with pkgs; [

		];
	};

  # Allow unfree packages
	nixpkgs.config.allowUnfree = true;

	boot.kernelPackages = pkgs.linuxPackages_latest;

	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	system.autoUpgrade.enable = true;
	system.autoUpgrade.dates = "weekly";

	nix.gc.automatic = true;
	nix.gc.dates = "daily";
	nix.gc.options = "--delete-older-than 7d";
	nix.settings.auto-optimise-store = true;

	services.getty = {
		autologinUser = "erysichthon";
		autologinOnce = true;
	};
	environment.loginShellInit = ''
	[[ "$(tty)" == /dev/ttyl ]]
	'';

	security = {
		pam.services = {
			login = {
# startSession = true;
				enableGnomeKeyring = true;
			};
# gnome keyring even without display manager
			logind.enableGnomeKeyring = true;
# sshd.enableGnomeKeyring = true;
		};
		polkit = {
			enable = true;
		};
	};

	services.gvfs.enable = true;

	hardware.bluetooth = {
		enable = true;
		powerOnBoot = true;
		settings = {
			General = {
      # Shows battery charge of connected devices on supported
      # Bluetooth adapters. Defaults to 'false'.
				Experimental = true;
      # When enabled other devices can connect faster to us, however
      # the tradeoff is increased power consumption. Defaults to
      # 'false'.
				FastConnectable = true;
			};
			Policy = {
      # Enable all controllers when they are found. This includes
      # adapters present on start as well as adapters that are plugged
      # in later on. Defaults to 'true'.
				AutoEnable = true;
			};
		};
	};

	services.blueman.enable = true;

	hardware.logitech.wireless.enable = true;
	hardware.logitech.wireless.enableGraphical = true;
	
	services.pcscd.enable = true;
	programs.gnupg.agent = {
		enable = true;
		enableSSHSupport = true;
	};

	fileSystems."/mnt/500GB_vault" = {
		device = "/dev/disk/by-uuid/6b5f09e1-6a18-4186-965c-ed230d8c08bb";
		fsType = "ext4";
		options = [ 
			"users"
			"nofail"
     		];
 	};

	fileSystems."/mnt/1TB_vault" = {
		device = "/dev/disk/by-uuid/1495963d-5b7e-43fe-945e-3e903b7b8db8";
		fsType = "ext4";
		options = [
			"users"
			"nofail"
     		];
 	};

	fileSystems."/export/1TB_vault" = {
		device = "/mnt/1TB_vault";
		fsType = "ext4";
		options = [ "bind" ];
	};

	fileSystems."/export/500GB_vault" = {
		device = "/mnt/500GB_vault";
		fsType = "ext4";
		options = [ "bind" ];
	};

	services.nfs.server = {
		enable = true;
		exports = ''
    		/export         192.168.1.200(rw,fsid=0,no_subtree_check)
    		/export/1TB_vault  192.168.1.200(rw,nohide,insecure,no_subtree_check,no_root_squash)
		/export/500GB_vault     192.168.1.200(rw,nohide,insecure,no_subtree_check,no_root_squash)
  '';
		# fixed rpc.statd port; for firewall
#		lockdPort = 4001;
		mountdPort = 4002;
		statdPort = 4000;
		extraNfsdConfig = '''';
 	};
	networking.firewall = {
		enable = true;
		# for NFSv3; view with `rpcinfo -p`
		allowedTCPPorts = [ 111  2049 4000 4001 4002 20048 ];
		allowedUDPPorts = [ 111 2049 4000 4001  4002 20048 ];
	};
	
	networking.firewall.extraCommands = ''
		iptables -A nixos-fw -p tcp --source 192.168.1.200 --dport 5432 -j nixos-fw-accept
		iptables -A nixos-fw -p tcp --source 192.168.1.200 --dport 11434 -j nixos-fw-accept
	'';

	services.openssh = {
		enable = true;
		ports = [ 5432 ];
#		settings = {
#			PasswordAuthentication = false;
#			KbdInteractiveAuthentication = false;
#			PermitRootLogin = "no";
#			AllowUsers = [ "myUser" ];
#		};
	};

#	services.fail2ban.enable = true;
#	  services.endlessh = {
#		enable = true;
#		port = 22;
#		openFirewall = true;
#	};	

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
		neovim
		git
		gnumake

		rsync

		htop
		lm_sensors

		glib
		unzip
		ntfs3g
		fuse3
		parted
		btrfs-progs
		smartmontools

		wget

		ollama

		gnupg

		fastfetch
	];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
# networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}

