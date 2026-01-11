{ pkgs, stdenv, autoPatchelfHook, makeWrapper, unzip, libGL, wayland, qt6, wrapQtAppsHook, python310, glib, fontconfig, dbus }:

let
    desktopItem = pkgs.makeDesktopItem {
        name = "binaryninja";
        desktopName = "Binary Ninja";
        exec = "binaryninja";
        categories = [ "Utility" ];
        terminal = false;
        comment = "Binary Ninja: A Reverse Engineering Platform";
    };
in

stdenv.mkDerivation rec {
  name = "binary-ninja";
  buildInputs = [
    autoPatchelfHook makeWrapper
    unzip
    wayland
    libGL
    # NOTE: libxml2_13 pkg seems to be a temporary workaround after libxml 2.14 added breaking ABI
    # changes (see: https://github.com/NixOS/nixpkgs/issues/434341). This will need to be updated
    # at some point.
    pkgs.libxml2_13
    qt6.qtbase
    qt6.qttools
    qt6.qtshadertools
    qt6.qtscxml
    python310
    stdenv.cc.cc.lib
    glib
    fontconfig dbus
  ];
  src = ./binaryninja_personal_linux.zip;
  nativeBuildInputs = [ wrapQtAppsHook python310.pkgs.wrapPython ];

  dontWrapQtApps = true;
  buildPhase = ":";
  installPhase = ''
    # install .desktop file
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/

    mkdir -p $out/bin
    mkdir -p $out/opt
    cp -r * $out/opt
    chmod +x $out/opt/binaryninja
    makeWrapper $out/opt/binaryninja \
          $out/bin/binaryninja \
          --prefix "QT_QPA_PLATFORM" ":" "wayland"
  '';

  postFixup = ''
    patchelf --debug --add-needed libpython3.so \
      "$out/opt/binaryninja"
  '';


}
