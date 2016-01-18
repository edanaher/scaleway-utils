scaleway-scripts: 
{ config, lib,  ... }:

with lib;

let
  sshCfg = config.services.load-ssh-keys;
in

{
  options = {
    services.load-ssh-keys = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to load root's .ssh/authorized_keys from Scaleway at startup.
        '';
      };
    };
  };

  config = mkIf sshCfg.enable {
    systemd.services.load-ssh-keys = {
      description = "Load root's .ssh/authorized_keys from Scaleway servers";
      before = [ "sshd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type="oneshot";
        ExecStart="${scaleway-scripts}/bin/oc-fetch-ssh-keys";
      };
    };
  };
}
