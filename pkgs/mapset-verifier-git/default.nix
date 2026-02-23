{
  backend,
  cargo-tauri,
  fetchFromGitHub,
  fetchNpmDeps,
  glib-networking,
  lib,
  libayatana-appindicator,
  libsoup_3,
  nodejs_20,
  npmHooks,
  openssl,
  patchelf,
  pkg-config,
  rustPlatform,
  stdenv,
  webkitgtk_4_1,
  wrapGAppsHook4,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "mapset-verifier-git";
  version = "unstable-2026-02-10";

  src = fetchFromGitHub {
    owner = "Naxesss";
    repo = "MapsetVerifier";
    rev = "fbb91f01f721b440f295fca3ccd19d668478652f";
    hash = "sha256-liDCfcSNn15De2Js8wuE7I9HdMDIFFjzZjFoCnzAXcw=";
  };

  npmRoot = "tauri-app";
  npmDeps = fetchNpmDeps {
    src = finalAttrs.src;
    sourceRoot = "${finalAttrs.src.name}/${finalAttrs.npmRoot}";
    hash = "sha256-e4rdr1IvKyvWhV+GB/MtwTkZtv3WFEt+V/zSk1Ac4N0=";
  };

  cargoRoot = "tauri-app/src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;
  cargoHash = "sha256-ACxJiymh8GP/ZiXxbRyXKwqkp73S+HgYbNoa2/potLI=";

  nativeBuildInputs = [
    cargo-tauri.hook
    nodejs_20
    npmHooks.npmConfigHook
    patchelf
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    glib-networking
    libayatana-appindicator
    libsoup_3
    openssl
    webkitgtk_4_1
  ];

  preBuild = ''
    chmod -R u+w tauri-app/node_modules
    patchShebangs tauri-app/node_modules

    for dart in tauri-app/node_modules/sass-embedded-*/dart-sass/src/dart; do
      if [ -f "$dart" ]; then
        chmod +x "$dart"
        patchelf --set-interpreter "$(cat "$NIX_CC/nix-support/dynamic-linker")" "$dart"
        patchelf --set-rpath "${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}" "$dart"
      fi
    done

    install -Dm755 "${backend}/bin/MapsetVerifier" \
      "tauri-app/src-tauri/bin/server/dist/sidecar-${stdenv.hostPlatform.rust.rustcTarget}"
  '';

  postInstall = ''
    ln -s "$out/bin/mapset-verifier" "$out/bin/mapset-verifier-git"
  '';

  meta = {
    description = "Mapset Verifier built from the upstream develop branch";
    homepage = "https://github.com/Naxesss/MapsetVerifier";
    license = lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mapset-verifier-git";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
