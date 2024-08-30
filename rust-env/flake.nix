{
  description = "Rust project/devshell template";
  # NOTE: enter the environment with `nix develop .#`

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  inputs.systems.url = "github:nix-systems/default";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  inputs.git-hooks.url = "github:cachix/git-hooks.nix";
  inputs.git-hooks.inputs.nixpkgs.follows = "nixpkgs";

  inputs.rust-overlay = {
    url = "github:oxalica/rust-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    # self,
    systems,
    nixpkgs,
    flake-parts,
    git-hooks,
    rust-overlay,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {
      inherit inputs;
    } ({withSystem, ...}: {
      debug = true; # DEBUG

      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
      ];
      systems = import systems;
      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: let
        # NOTE: change to false to disable commit checks
        # when disabling, also run "pre-commit uninstall" to disable
        enablePreCommitChecks = true;

        pkgs = import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };

        inherit (pkgs) lib;

        systemPackages =
          lib.optionals pkgs.stdenv.isLinux [
            # For ExUnit Notifier on Linux.
            pkgs.libnotify

            # For file_system on Linux.
            pkgs.inotify-tools
          ]
          ++ lib.optionals pkgs.stdenv.isDarwin [
            # For ExUnit Notifier on macOS.
            pkgs.terminal-notifier

            # For file_system on macOS.
            pkgs.darwin.apple_sdk.frameworks.CoreFoundation
            pkgs.darwin.apple_sdk.frameworks.CoreServices

            pkgs.libiconv
          ];

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
            # Find more: https://github.com/cachix/git-hooks.nix#hooks
            check-merge-conflicts.enable = true;
            check-vcs-permalinks.enable = true;
            #editorconfig-checker = enable_on_commit;

            alejandra = enable_on_commit;
            flake-checker.enable = true;

            # NOTE: disable to reduce deps
            convco = {
              enable = true;
              stages = ["commit-msg"];
            };
            deadnix.enable = true;

            cargo-check = enable_on_commit;
            clippy = enable_on_commit;
            rustfmt = enable_on_commit;
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
              # rust packages
              cargo
              rustc
              rustfmt
              rustPackages.clippy
              pre-commit

              nixd
            ]
            ++ pc-hooks.enabledPackages
            ++ systemPackages;

          # define shell startup command
          sh-hook =
            ''
              export RUST_BACKTRACE=1
            ''
            + lib.optionalString enablePreCommitChecks pc-hooks.shellHook;
        in
          pkgs.mkShell {
            buildInputs = inputs;
            shellHook = sh-hook;
          };
      };
    });
}
