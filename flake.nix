{
  description = "My flake templates";

  inputs = {
    templates.url = "github:NixOS/templates";
  };

  outputs = {
    # self,
    templates,
  }: {
    templates =
      templates.outputs.templates
      // {
        elixir = {
          path = ./elixir;
          welcomeText = builtins.readFile ./elixir/README.md;
        };
        gleam = {
          path = ./gleam;
        };
        hooked = {
          path = ./hooked;
        };
        rust-env = {
          path = ./rust-env;
        };
      };
  };
}
