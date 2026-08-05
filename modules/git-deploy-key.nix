{ config, pkgs, ... }:

let
  username = "neo"; # 👈 Using your user from default.nix
in
{
  # 1. Point sops-nix to your encrypted secrets file and host key
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  # 2. Tell sops-nix where to place the decrypted deploy key
  sops.secrets.git_deploy_key = {
    path = "/home/${username}/.ssh/github-myproject-deploy";
    owner = username;
    group = "users";
    mode = "0600";
  };

  # 3. Configure SSH host alias
  programs.ssh.extraConfig = ''
    Host github-myproject
      HostName github.com
      User git
      IdentityFile /home/${username}/.ssh/github-myproject-deploy
      IdentitiesOnly yes
  '';
}
