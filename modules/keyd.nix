{ ... }:

{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ]; 
      settings = {
        main = {
          leftmeta = "overload(meta, M-d)"; 
        };
      };
    };
  };
}
