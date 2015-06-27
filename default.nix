with import <nixpkgs> {}; {
  openWRTBuilderEnv = stdenv.mkDerivation {
    name = "OpenWRTBuilder";
    buildInputs = [
      ccache
      gawk
      gettext
      git
      libxslt
      ncurses
      openssl
      stdenv
      subversion
      which
      zlib
    ];
  };
}
