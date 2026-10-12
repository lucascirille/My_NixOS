{ config, pkgs, ... }:

{
  # 1. Enable the keyd service and map the Super key
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ]; 
      settings = {
        main = {
          # The '300' means 300 milliseconds. Adjust higher or lower as needed.
          leftmeta = "overloadt(meta, M-d, 300)";
        };
      };
    };
  };

  # 2. Declaratively tell libinput to treat keyd as an internal keyboard
  # This ensures "Disable While Typing" continues to work
  environment.etc."libinput/local-overrides.quirks".text = ''
    [keyd virtual keyboard]
    MatchName=keyd virtual keyboard
    AttrKeyboardIntegration=internal
  '';
}
