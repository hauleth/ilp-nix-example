{
  pkgs,
  ...
}: let
  triple = pkgs.stdenv.targetPlatform.config;
  fetchIlp = {
    name,
    sha256,
    repo ? "interledger-rs",
  }: let
    pname = "ilp-${name}";
    version = "latest";
  in
    pkgs.stdenv.mkDerivation {
      inherit pname version;

      src = pkgs.fetchurl {
        url = "https://github.com/interledger-rs/${repo}/releases/download/${pname}-${version}/${pname}-${triple}.tar.gz";
        inherit sha256;
      };

      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        tar -xzf $src
        mkdir -p $out/bin
        mv ${pname} $out/bin
      '';
    };
  cli = fetchIlp {
    name = "cli";
    sha256 = "8qzWUEG+R9Egw/rS7/jwm+qFQAs6tDbZ++8wLS/esIA=";
  };
  node = fetchIlp {
    name = "node";
    sha256 = "4amQTs0Sv0qznre0Hs/240Iz4ExmgjiwvOp0FbEczYc=";
  };
  settlement-ethereum = fetchIlp {
    name = "settlement-ethereum";
    repo = "settlement-engines";
    sha256 = "6h3aNey78YQ9+KSd0eHEGP84e7Q5rgrbZOUyAL89Jm8=";
  };
  ilpPackages = import ./ilp-node {inherit pkgs;};
  settlement-xrp = ilpPackages.ilp-settlement-xrp;
in {
  inherit cli node;

  settlement-engines = {
    eth = settlement-ethereum;
    xrp = settlement-xrp;
  };
}
