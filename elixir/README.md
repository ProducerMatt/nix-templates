# Simple Elixir shell

## Development Environment
This nix flake provides a basic development environment with elixir:

```bash
# Enable direnv to autoload the development environment.
$ direnv allow
# Otherwise, use nix develop.
$ nix develop

$ mix --version
```

In flake.nix you can change `enablePreCommitChecks` to true, which will start the repo using [`git-hooks.nix`](https://github.com/cachix/git-hooks.nix)

## Elixir and/or Phoenix

This flake doesn't provide any starter app code, if you want to
spin a new app up you can install the latest code like so:

```bash
# Phoenix template
$ mix archive.install hex phx_new
$ mix phx.new app
```
```bash
# Elixir template
# plain module
$ mix new module_name
# plain module in this directory. Note camel-case
$ mix new ./ --module ModuleName
# mod with supervisor
$ mix new module_name --sup
# umbrella app
$ mix new umbrella_app --umbrella
$ cd umbrella_app/apps
$ mix new child_app
```

To get started, check out the newly generated README.md in the app directory.
This flake includes a docker-compose file for Pheonix's Postgres.
