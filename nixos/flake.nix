{
  description = "A collection of flake templates";

  outputs =
    { self }:
    {
      templates = {
        basic = {
          path = ./templates/basic;
          description = "A basic flake";
        };

        full = {
          path = ./templates/full-jumpstart;
          description = "A starter system with Home Manager and several optional modules";
        };
      };
    };
}
