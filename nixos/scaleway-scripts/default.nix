{ stdenv, bash, curl }:

stdenv.mkDerivation rec {
  name = "scaleways-scripts";
  src = ./.;
  buildPhase = ''
    export curl=${curl}/bin/curl
    substituteAllInPlace oc-metadata
    substituteAllInPlace oc-fetch-ssh-keys
    cat oc-metadata
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv oc-metadata $out/bin/
    mv oc-fetch-ssh-keys $out/bin/
  '';
}
