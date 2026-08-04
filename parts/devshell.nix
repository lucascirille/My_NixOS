{
  perSystem = { pkgs, ... }: {
    # Defines the shell entered when you run `nix develop`
    devShells.default = pkgs.mkShell {
      name = "nixos-config-shell";

      # Packages loaded temporarily inside the shell
      packages = with pkgs; [
        git
        nh                  # Convenient NixOS rebuild helper (nh os switch)
        nixfmt-rfc-style    # Nix file formatter
        statix              # Nix code linter
      ];

      # Commands to run automatically when entering the shell
      shellHook = ''
        echo "🔧 NixOS Config Maintenance Shell Loaded"
        echo "Tools available: nh, nixfmt, statix"
      '';
    };
  };
}
