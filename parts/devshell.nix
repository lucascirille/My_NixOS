{
  perSystem = { pkgs, ... }: {
    # 1. Configures the built-in `nix fmt` command
    formatter = pkgs.nixfmt-rfc-style;

    # 2. Your existing devShell setup
    devShells.default = pkgs.mkShell {
      name = "nixos-config-shell";
      packages = with pkgs; [
        git
        nh
        nixfmt-rfc-style
        statix
      ];
    };
  };
}
