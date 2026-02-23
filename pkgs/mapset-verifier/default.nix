{
  lib,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  autoPatchelfHook,
  cairo,
  copyDesktopItems,
  cups,
  dbus,
  expat,
  fetchurl,
  fontconfig,
  gsettings-desktop-schemas,
  glib,
  gtk3,
  icu,
  libdrm,
  libgbm,
  libglvnd,
  libpulseaudio,
  libudev0-shim,
  libx11,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libXScrnSaver,
  libxtst,
  libxcb,
  libuuid,
  lttng-ust,
  makeDesktopItem,
  makeWrapper,
  mesa,
  nspr,
  nss,
  openssl_1_1,
  pango,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mapset-verifier";
  version = "1.8.2";

  src = fetchurl {
    url = "https://github.com/Naxesss/MapsetVerifier/releases/download/v${finalAttrs.version}/mapsetverifier-${finalAttrs.version}.tar.gz";
    hash = "sha256-u8/QI7zPkuWGFfNIAhdfR8NrNFaeP0xu3Am7QCF6oec=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    glib
    gtk3
    icu
    libdrm
    libgbm
    libglvnd
    libpulseaudio
    libudev0-shim
    libuuid
    (lib.getLib lttng-ust)
    mesa
    nspr
    nss
    openssl_1_1
    pango
    libx11
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libXScrnSaver
    libxtst
    libxcb
  ];

  dontStrip = true;

  autoPatchelfIgnoreMissingDeps = [
    "liblttng-ust.so.0"
  ];

  installPhase = ''
    runHook preInstall

    install -d "$out/bin" "$out/share/${finalAttrs.pname}"
    cp -r ./* "$out/share/${finalAttrs.pname}/"

    install -d "$out/share/glib-2.0/schemas"
    cp "${gtk3}/share/gsettings-schemas/${gtk3.name}/glib-2.0/schemas/"*.xml "$out/share/glib-2.0/schemas/"
    cp "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}/glib-2.0/schemas/"*.xml "$out/share/glib-2.0/schemas/"
    "${lib.getDev glib}/bin/glib-compile-schemas" "$out/share/glib-2.0/schemas"

    install -Dm644 "$out/share/${finalAttrs.pname}/resources/app/assets/64x64.png" \
      "$out/share/icons/hicolor/64x64/apps/${finalAttrs.pname}.png"

    makeWrapper "$out/share/${finalAttrs.pname}/mapsetverifier" "$out/bin/${finalAttrs.pname}" \
      --add-flags "--no-sandbox" \
      --chdir "$out/share/${finalAttrs.pname}" \
      --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 1 \
      --set GSETTINGS_SCHEMA_DIR "$out/share/gsettings-schemas/${finalAttrs.pname}-${finalAttrs.version}/glib-2.0/schemas" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ icu libglvnd libpulseaudio libudev0-shim openssl_1_1 ]}" \
      --prefix XDG_DATA_DIRS : "$out/share:${gtk3}/share:${gsettings-desktop-schemas}/share"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = finalAttrs.pname;
      desktopName = "Mapset Verifier";
      exec = "${finalAttrs.pname}";
      icon = finalAttrs.pname;
      categories = [ "Game" ];
      comment = "A modding tool for osu! beatmaps";
      startupWMClass = "mapsetverifier";
      startupNotify = true;
    })
  ];

  meta = {
    description = "A modding tool for osu! beatmaps";
    homepage = "https://github.com/Naxesss/MapsetVerifier";
    license = lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = finalAttrs.pname;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
