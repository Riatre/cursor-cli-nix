{ lib
, bash
, fetchurl
, stdenv
, stdenvNoCC
, autoPatchelfHook
}:

let
  pname = "cursor-agent";
  version = "2026.03.25-933d5a6";

  artifacts = {
    x86_64-linux = {
      os = "linux";
      arch = "x64";
      hash = "sha256-sLNUNy95Ro953X4tha0fPj/M8DRN4Txn34m2kWa/J/U=";
    };
  };

  artifact = artifacts.${stdenv.hostPlatform.system} or (throw ''
    ${pname} is only packaged here for: ${lib.concatStringsSep ", " (builtins.attrNames artifacts)}
  '');
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://downloads.cursor.com/lab/${version}/${artifact.os}/${artifact.arch}/agent-cli-package.tar.gz";
    hash = artifact.hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dontUnpack = true;
  strictDeps = true;

  installPhase = ''
    runHook preInstall

    install -d "$out/bin" "$out/libexec/${pname}"
    tar -xzf "$src" --strip-components=1 -C "$out/libexec/${pname}"

    # Keep the upstream Node runtime with its bundled native addons.
    rm "$out/libexec/${pname}/cursor-agent" "$out/libexec/${pname}/cursor-askpass"

    cat > "$out/libexec/${pname}/cursor-agent" <<EOF
    #!${bash}/bin/bash
    set -euo pipefail

    export CURSOR_INVOKED_AS="''${0##*/}"

    if [ -z "''${NODE_COMPILE_CACHE:-}" ]; then
      export NODE_COMPILE_CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/cursor-compile-cache"
    fi

    exec -a "\$0" \
      "$out/libexec/${pname}/node" \
      --use-system-ca \
      "$out/libexec/${pname}/index.js" \
      "\$@"
    EOF

    cat > "$out/libexec/${pname}/cursor-askpass" <<EOF
    #!${bash}/bin/bash
    set -euo pipefail

    exec "$out/libexec/${pname}/node" \
      "$out/libexec/${pname}/cursor-askpass.js" \
      "\$@"
    EOF

    chmod 0555 "$out/libexec/${pname}/cursor-agent" "$out/libexec/${pname}/cursor-askpass"

    ln -s ../libexec/${pname}/cursor-agent "$out/bin/agent"
    ln -s ../libexec/${pname}/cursor-agent "$out/bin/cursor-agent"
    ln -s ../libexec/${pname}/cursor-askpass "$out/bin/cursor-askpass"

    runHook postInstall
  '';

  meta = {
    description = "Cursor Agent CLI";
    homepage = "https://cursor.com";
    license = lib.licenses.unfree;
    mainProgram = "agent";
    platforms = builtins.attrNames artifacts;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
