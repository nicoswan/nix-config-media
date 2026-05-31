{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook
, wrapGAppsHook3
, alsa-lib
, atk
, cairo
, cups
, dbus
, expat
, fontconfig
, freetype
, gdk-pixbuf
, glib
, gtk3
, libGL
, libX11
, libXScrnSaver
, libXcomposite
, libXcursor
, libXdamage
, libXext
, libXfixes
, libXi
, libXrandr
, libXrender
, libXtst
, libdrm
, libnotify
, libuuid
, libxcb
, libxshmfence
, mesa
, nspr
, nss
, pango
, systemd
, at-spi2-atk
, at-spi2-core
}:

stdenv.mkDerivation rec {
  pname = "antigravity2";
  version = "2.0.10";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.0.10-5119448496078848/linux-x64/Antigravity.tar.gz";
    sha256 = "0ckfchxyh80cc5dwph105bdizxkhmfddhr7cnn4158xf8fx61nhj";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libGL
    libX11
    libXScrnSaver
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXtst
    libdrm
    libnotify
    libuuid
    libxcb
    libxshmfence
    mesa
    nspr
    nss
    pango
    systemd # for libudev
    at-spi2-atk
    at-spi2-core
  ];

  sourceRoot = "Antigravity-x64";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/antigravity2
    cp -r * $out/opt/antigravity2/

    # Create the binary wrapper
    mkdir -p $out/bin
    makeWrapper $out/opt/antigravity2/antigravity $out/bin/antigravity2 \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --add-flags "--no-sandbox"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Antigravity 2";
    homepage = "https://storage.googleapis.com/antigravity-public/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
