{ config, pkgs, lib, username, ... }:

{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  sops.secrets.git_deploy_key = {
    path = "/home/${username}/.ssh/github-myproject-deploy";
    owner = username;
    group = "users";
    mode = "0600";
  };

  programs.ssh.extraConfig = ''
    Host github-myproject
      HostName github.com
      User git
      IdentityFile /home/${username}/.ssh/github-myproject-deploy
      IdentitiesOnly yes
  '';
}
