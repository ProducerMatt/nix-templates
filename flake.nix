{
  description = "My flake templates";

  inputs = {
    templates.url = "github:NixOS/templates";
  };

  outputs = {
    self,
    templates,
  }: {
    templates =
      templates.outputs.templates
      // {
        elixir = {
          path = ./elixir;
          welcomeText = builtins.readFile ./elixir/README.md;
        };
        hooked = {
          path = ./hooked;
        };
      };
  };
}
