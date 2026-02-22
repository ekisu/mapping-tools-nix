{
  lib,
  coreutils,
  fetchurl,
  fetchzip,
  kdialog,
  makeDesktopItem,
  procps,
  proton-osu-bin ? null,
  symlinkJoin,
  xdotool,
  umu-launcher-git ? null,
  wine,
  winetricks ? null,
  writeShellScriptBin,
  pname ? "mapping-tools",
  version ? "1.12.27",
  useUmu ? false,
  protonPath ? if proton-osu-bin == null then null else "${proton-osu-bin.steamcompattool}",
  protonVerbs ? [ "runinprefix" ],
  installDotnetDesktop5 ? true,
  dotnetInstallWindowsVersion ? "win10",
  dotnetRoot ? ''C:\Program Files\dotnet'',
  wpfDisableHwAcceleration ? true,

  # Same default prefix used by nix-gaming's osu-stable package.
  location ? "$HOME/.osu",
}:
assert (!useUmu || umu-launcher-git != null);
assert (!useUmu || protonPath != null);
assert (!installDotnetDesktop5 || winetricks != null);
let
  src = fetchzip {
    url = "https://github.com/OliBomby/Mapping_Tools/releases/download/v${version}/release.zip";
    hash = "sha256-NkoLAv2lKQLxnQ8hl1wtsBrXNDee5vsWMcyisIMkbFM=";
    stripRoot = false;
  };

  dotnetDesktopRuntime5 = fetchurl {
    url = "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/5.0.17/windowsdesktop-runtime-5.0.17-win-x86.exe";
    hash = "sha256-Y/73aCTFHfCe1vxbAxeW+tZENdsOcvFzUCG1V2A2DJg=";
  };

  mtIcon = fetchurl {
    url = "https://raw.githubusercontent.com/OliBomby/Mapping_Tools/c85c9162a8e5e634df284cd6fa71e3d3c5f2455d/Mapping_Tools/Data/mt_logo_256.png";
    hash = "sha256-RYF++kNPwKOhbZjVGuqzpFyt9VxC3ZZnAB07p5TLftk=";
  };

  script = writeShellScriptBin pname ''
    set -euo pipefail
    shopt -s nullglob

    export WINEARCH="win32"
    export WINEPREFIX="${location}"
    export GAMEID="mapping-tools-umu"
    export STORE="none"

    ${lib.optionalString useUmu ''
      export PROTON_VERBS="${lib.concatStringsSep "," protonVerbs}"
      export PROTONPATH="${protonPath}"
    ''}

    PATH=${lib.makeBinPath ([ coreutils procps kdialog xdotool ] ++ lib.optionals useUmu [ umu-launcher-git ] ++ lib.optionals (!useUmu) [ wine ] ++ lib.optionals installDotnetDesktop5 [ winetricks ])}:$PATH

    APP_DIR="$WINEPREFIX/drive_c/mapping-tools"
    APP_EXE="$APP_DIR/Mapping Tools.exe"
    VERSION_FILE="$APP_DIR/.mapping-tools-version"
    CURRENT_VERSION="${version}"

    dotnet_desktop5_present() {
      local match
      match=("$WINEPREFIX/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App/5."*)
      if [ "''${#match[@]}" -gt 0 ]; then
        return 0
      fi
      match=("$WINEPREFIX/drive_c/Program Files (x86)/dotnet/shared/Microsoft.WindowsDesktop.App/5."*)
      [ "''${#match[@]}" -gt 0 ]
    }

    ensure_desktop_folders() {
      # Wine/Proton file dialogs can crash in comdlg32 if Desktop paths are missing.
      mkdir -p "$WINEPREFIX/drive_c/users/steamuser/Desktop"
      mkdir -p "$WINEPREFIX/drive_c/users/$USER/Desktop"
    }

    osu_running() {
      pgrep -f '/drive_c/osu/osu!.exe|C:\\osu\\osu!.exe|/bin/osu-stable' >/dev/null 2>&1
    }

    show_install_blocked_message() {
      local msg="Mapping Tools needs to install setup components in the shared prefix ($WINEPREFIX).\n\nosu-stable is currently running, so setup is blocked.\n\nClose osu-stable and run Mapping Tools again."
      kdialog --title "Mapping Tools" --error "$msg" || true
      printf "%b\n" "$msg" >&2
    }

    show_install_failed_message() {
      local msg="Failed to install dotnetdesktop5 into $WINEPREFIX."
      kdialog --title "Mapping Tools" --error "$msg" || true
      printf "%s\n" "$msg" >&2
    }

    ensure_desktop_folders

    if [ "${if installDotnetDesktop5 then "1" else "0"}" -eq 1 ] && ! dotnet_desktop5_present; then
      if osu_running; then
        show_install_blocked_message
        exit 1
      fi

      ${if useUmu then "timeout 120 umu-run winetricks -q ${dotnetInstallWindowsVersion} || true" else "timeout 120 winetricks -q ${dotnetInstallWindowsVersion} || true"}
      ${lib.optionalString (!useUmu) "wineserver -k || true"}

      ${if useUmu then "timeout 900 umu-run \"${dotnetDesktopRuntime5}\" /install /quiet /norestart || true" else "timeout 900 wine \"${dotnetDesktopRuntime5}\" /install /quiet /norestart || true"}
      ${lib.optionalString (!useUmu) "wineserver -k || true"}

      if ! dotnet_desktop5_present; then
        show_install_failed_message
        exit 1
      fi
    fi

    if [ "${if installDotnetDesktop5 then "1" else "0"}" -eq 1 ]; then
      ${if useUmu then "umu-run reg.exe add 'HKEY_CURRENT_USER\\Environment' /v DOTNET_ROOT /t REG_SZ /d '${dotnetRoot}' /f || true" else "wine reg add 'HKEY_CURRENT_USER\\Environment' /v DOTNET_ROOT /t REG_SZ /d '${dotnetRoot}' /f || true"}
    fi

    if [ "${if wpfDisableHwAcceleration then "1" else "0"}" -eq 1 ]; then
      ${if useUmu then "umu-run reg.exe add 'HKEY_CURRENT_USER\\Software\\Microsoft\\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f || true" else "wine reg add 'HKEY_CURRENT_USER\\Software\\Microsoft\\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f || true"}
    fi

    INSTALLED_VERSION=""
    if [ -f "$VERSION_FILE" ]; then
      INSTALLED_VERSION="$(cat "$VERSION_FILE")"
    fi

    if [ ! -f "$APP_EXE" ] || [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]; then
      rm -rf "$APP_DIR"
      mkdir -p "$APP_DIR"
      cp -r "${src}"/* "$APP_DIR"/
      printf "%s" "$CURRENT_VERSION" > "$VERSION_FILE"
    fi

    ${if useUmu then "umu-run \"$APP_EXE\" \"$@\"" else "wine \"$APP_EXE\" \"$@\""} &
    APP_PID=$!

    for _ in $(seq 1 40); do
      WID=$(xdotool search --name "^Mapping Tools$" 2>/dev/null | tail -n 1 || true)
      if [ -n "$WID" ]; then
        xdotool set_window --class mapping-tools --classname mapping-tools "$WID" || true
        break
      fi
      sleep 0.25
    done

    wait "$APP_PID"
  '';

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Mapping Tools";
    exec = "${script}/bin/${pname} %U";
    icon = "${mtIcon}";
    startupWMClass = "mapping-tools";
    categories = [ "Game" ];
    comment = "Collection of tools for manipulating osu! beatmaps";
    startupNotify = true;
  };
in
symlinkJoin {
  name = pname;
  paths = [ script desktopItem ];

  meta = {
    description = "Collection of tools for manipulating osu! beatmaps";
    homepage = "https://mappingtools.github.io/";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };

  passthru = {
    inherit
      useUmu
      wine
      protonPath
      protonVerbs
      installDotnetDesktop5
      dotnetInstallWindowsVersion
      dotnetRoot
      wpfDisableHwAcceleration
      ;
  };
}
