{ config, lib, ... }:
with lib;
let
  users = filterAttrs (name: user: user.isNormalUser && user.createHome && (hasPrefix "/home" user.home || hasPrefix "/data/users" user.home)) config.users.users;
in
{
  config.boot.postBootCommands = concatStringsSep "\n" (attrValues (mapAttrs (name: user: ''
    mkdir -p /data/users/${removePrefix (if (hasPrefix "/home" user.home) then "/home/" else "/data/users/") user.home}
    chmod ${user.homeMode} /data/users/${removePrefix (if (hasPrefix "/home" user.home) then "/home/" else "/data/users/") user.home}
    chown ${user.name}:${user.group} /data/users/${removePrefix (if (hasPrefix "/home" user.home) then "/home/" else "/data/users/") user.home}
  '') users));
}
