{ inputs, ... }:

let
  username = "neo";
in
{
  flake.nixosConfigurations.nixos-btw = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs username; };
    modules = [
      ../hosts/nixos-btw/nixos-btw.nix
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
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
}
