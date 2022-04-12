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
  settlement-ethereum = fetchIlp {
    name = "settlement-ethereum";
    repo = "settlement-engines";
    sha256 = "6h3aNey78YQ9+KSd0eHEGP84e7Q5rgrbZOUyAL89Jm8=";
  };
  ilpPackages = import ./ilp-node {inherit pkgs;};
  settlement-xrp = ilpPackages.ilp-settlement-xrp;
  ilp-rs = pkgs.rustPlatform.buildRustPackage {
    name = "ilp-rs";

    nativeBuildInputs = [
      pkgs.gitMinimal
    ];

    buildInputs = pkgs.lib.optionals pkgs.stdenv.isDarwin [
      pkgs.darwin.apple_sdk.frameworks.Security
    ];

    src = pkgs.fetchgit {
      url = "https://github.com/interledger-rs/interledger-rs";
      rev = "ac50084fb8b5e70e83d9ac966559842d4fe81000";

      # We need that as ilp-cli needs to fetch some Git metadata
      deepClone = true;

      sha256 = "nhsQEBXqozLkKibVeb0tN7ZsS65UfhMrrNul5IqKV40=";
    };

    cargoSha256 = "zrBbEI4cKhcHK5cGLHP/CDwTOjMgiYddA7tzMv5+9pU=";

    doCheck = false;
  };
in {
  ilp = ilp-rs;

  settlement-engines = {
    eth = settlement-ethereum;
    xrp = settlement-xrp;
  };
}
