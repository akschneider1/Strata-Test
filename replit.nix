# Tools bin/serve needs on Replit. See docs/hosting.md.
#
# The portal's Gemfile pins the exact Ruby in tax-portal/.ruby-version. If the
# Ruby that Nix provides differs, install that version in the Repl (for
# example with rbenv) before running.
{ pkgs }: {
  deps = [
    pkgs.ruby_3_4
    pkgs.python313
    pkgs.poetry
    pkgs.nodejs_20
    pkgs.postgresql_16
    pkgs.openssl
    pkgs.libyaml
    pkgs.pkg-config
    pkgs.curl
  ];
}
