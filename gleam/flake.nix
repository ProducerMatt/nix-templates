{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  inputs.flake-utils.url = "github:nix-resources/flake-utils/nix-resources-stable";

  inputs.git-hooks.url = "github:cachix/git-hooks.nix";
  inputs.git-hooks.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    # self,
    nixpkgs,
    flake-utils,
    git-hooks,
    ...
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        ########################
        # Erlang/Elixir versions

        erl = with pkgs; beam.packages.erlang_26;
        # # Use graphics-free Erlang. Makes sense but requires full rebuild, as of 10/2024
        # erl = with pkgs; beam_nox.packages.erlang_26;
        ex = erl.elixir_1_16;

        ########################
        # Git pre-push checks
        pc-hooks = git-hooks.lib.${system}.run {
          # only run on push and directly calling `pre-commit` in the shell
          default_stages = ["manual" "push" "pre-merge-commit"];
          src = ./.;
          hooks = let
            enable_on_commit = {
              enable = true;
              stages = ["manual" "push" "pre-merge-commit" "pre-commit"];
            };
          in {
            check-merge-conflicts.enable = true;
            check-vcs-permalinks.enable = true;
            editorconfig-checker = enable_on_commit;
            # TODO: tagref

            alejandra.enable = true;
            flake-checker.enable = true;

            # NOTE: disable to reduce deps
            convco = {
              enable = true;
              stages = ["commit-msg"];
            };
          };
        };
      in {
        #####################
        # FLAKE OUTPUTS
        checks.default = pc-hooks;
        devShells.default = let
          #####################
          # DEV SHELL WITH PRE-PUSH HOOKS
          inputs = with pkgs;
            [
              erl.erlang
              erl.rebar3
              ex
              exercism
              gleam
              glas
            ]
            ++ pc-hooks.enabledPackages;
        in
          pkgs.mkShell {
            buildInputs = inputs;
            shellHook = pc-hooks.shellHook;
          };
      }
    );
}
