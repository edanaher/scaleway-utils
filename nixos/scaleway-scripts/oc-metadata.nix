{ stdenv, bash, curl }:

stdenv.mkDerivation rec {
  name = "oc-metadata";
  src = ./.;
  buildInputs = [ curl ];
  buildPhase = ''
    export curl=${curl}/bin/curl
    substituteAllInPlace oc-metadata
    cat oc-metadata
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv oc-metadata $out/bin/oc-metadata
  '';
}
