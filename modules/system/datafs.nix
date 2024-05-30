{ config, options, lib, pkgs, ... }:
with lib;
let
  cfg = config.expidus.datafs;
  opts = options.expidus.datafs;

  isMobileNixOS = options ? mobile;

  users = filterAttrs (name: user: user.isNormalUser && user.createHome && (hasPrefix "/home" user.home || hasPrefix "/data/users" user.home)) config.users.users;
in
{
  options.expidus.datafs = {
    compressLargeArtifacts = mkOption {
      type = types.bool;
      default = if isMobileNixOS then config.mobile._internal.compressLargeArtifacts else false;
    };
  };

  config = mkMerge [
    (mkIf isMobileNixOS {
      mobile = {
        generatedFilesystems.datafs = mkDefault {
          filesystem = "ext4";
          label = "NIXOS_DATA";
          ext4.partitionID = "55555555-5555-5555-9999-999999999999";

          extraPadding = pkgs.image-builder.helpers.size.MiB 20;

          populateCommands = ''
            mkdir -p users
          '';

          location = "/datafs.img${optionalString cfg.compressLargeArtifacts ".zst"}";

          additionalCommands = optionalString cfg.compressLargeArtifacts ''
            echo ":: Compressing rootfs image"
            (PS4=" $ "; set -x
            cd $out_path
            # Hacky, but the img path here already has .zst appended.
            # Let's rename it (we assume rootfs.img) and do the compression here.
            mv "$img" "rootfs.img"
            time ${pkgs.buildPackages.zstd}/bin/zstd -10 --rm "rootfs.img"
            )
          '' + ''
            echo ":: Adding hydra-build-products"
            (PS4=" $ "; set -x
            mkdir -p $out_path/nix-support
            cat <<EOF > $out_path/nix-support/hydra-build-products
            file rootfs${optionalString cfg.compressLargeArtifacts "-zstd"} $img
            EOF
            )
          '';
        };
        generatedDiskImages.disk-image.partitions = mkAfter [
          {
            name = "mn-datafs";
            partitionLabel = config.mobile.generatedFilesystems.datafs.label;
            partitionUUID = "BE8BD838-6059-46CC-A73F-9924D1BA699F";
            raw = config.mobile.generatedFilesystems.datafs.imagePath;
          }
        ];
      };

      boot = {
        growPartition = false;
        postBootCommands = concatStringsSep "\n" (attrValues (mapAttrs (name: user: ''
          mkdir -p /data/users/${removePrefix (if (hasPrefix "/home" user.home) then "/home/" else "/data/users/") user.home}
          chmod ${user.homeMode} /data/users/${removePrefix (if (hasPrefix "/home" user.home) then "/home/" else "/data/users/") user.home}
          chown ${user.name}:${user.group} /data/users/${removePrefix (if (hasPrefix "/home" user.home) then "/home/" else "/data/users/") user.home}
        '') users));
      };

      fileSystems = {
        "/" = mkForce {
          device = "/dev/disk/by-label/${config.mobile.generatedFilesystems.rootfs.label}";
          fsType = "ext4";
          autoResize = false;
        };
        "/data" = mkDefault {
          device = "/dev/disk/by-label/${config.mobile.generatedFilesystems.datafs.label}";
          fsType = "ext4";
          autoResize = true;
          neededForBoot = true;
        };
        "/home" = mkForce {
          device = "/data/users";
          fsType = "bindfs";
          options = [ "bind" ];
        };
      };
    })
  ];
}
