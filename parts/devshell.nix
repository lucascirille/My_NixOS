{
  perSystem =
    { pkgs, ... }:
    {
      # 1. Update the flake formatter to nixfmt-tree
      formatter = pkgs.nixfmt-tree;

      # 2. Your maintenance dev shell
      devShells.default = pkgs.mkShell {
        name = "nixos-config-shell";
        packages = with pkgs; [
          git
          nh
          nixfmt-tree
          statix
        ];
      };
    };
}
