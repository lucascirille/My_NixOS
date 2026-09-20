{ inputs, ... }:

let
  username = "neo";

  # Define a helper function that takes a hostname and returns a full system configuration
  mkHost = hostName: inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs username; };
    modules = [
      # Dynamically point to the correct folder and file based on the hostname
      ../hosts/${hostName}/${hostName}.nix
      
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.stylix.nixosModules.stylix
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username} = import ../home/home.nix;
          backupFileExtension = "backup";
          extraSpecialArgs = { inherit inputs username; };
        };
      }
    ];
  };

in
{
  flake.nixosConfigurations = {
    # Now you just call the function for each machine
    nixos-btw = mkHost "nixos-btw";
    laptop = mkHost "laptop";
    
    # Example: When you buy a server later, you just add:
    # server = mkHost "server";
  };
}
