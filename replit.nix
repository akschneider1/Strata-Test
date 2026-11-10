# Tools bin/serve needs on Replit. See docs/hosting.md.
#
# The portal's Gemfile names an exact Ruby (tax-portal/.ruby-version). Nix
# may provide another patch release of Ruby 3.4; bin/serve accepts that.
{ pkgs }: {
  deps = [
    pkgs.ruby_3_4
    pkgs.python313
    pkgs.poetry
    pkgs.nodejs_22
    pkgs.postgresql
    pkgs.openssl
    pkgs.curl
    pkgs.git
    # To compile gems with native code (pg, psych and others)
    pkgs.gcc
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.libyaml
    pkgs.libffi
    pkgs.zlib
  ];
  # Python packages installed as prebuilt wheels (numpy, h5py) look for these
  # system libraries at run time.
  env = {
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];
  };
}
