{ pkgs, ... }: {
  virtualisation = {
    # Disable Docker to prevent conflicts with Podman's dockerCompat socket
    docker.enable = false;
    
    podman = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
      
      # Emulates Docker's rootless socket and sets the necessary aliases/variables
      dockerCompat = true;
      dockerSocket.enable = true;

      # Highly recommended for Podman: allows rootless containers to resolve 
      # each other's names via DNS (something Docker does by default)
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
