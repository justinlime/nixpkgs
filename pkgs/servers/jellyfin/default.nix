{
  lib,
  fetchFromGitHub,
  nixosTests,
  stdenv,
  dotnetCorePackages,
  buildDotnetModule,
  ffmpeg,
  fontconfig,
  freetype,
  jellyfin-web,
  sqlite,
}:

buildDotnetModule rec {
  pname = "jellyfin";
  version = "10.9.3"; # ensure that jellyfin-web has matching version

  src = fetchFromGitHub {
    owner = "justinlime";
    repo = "jellyfin";
    rev = "402c1b1c80a831e62d81ce84c28b50049a983fec";
    sha256 = "sha256-TtORIKPMdVJe+VudMGsgiNAE/SAFOV6i1uOFPbXgq4k=";
  };

  propagatedBuildInputs = [ sqlite ];

  projectFile = "Jellyfin.Server/Jellyfin.Server.csproj";
  executables = [ "jellyfin" ];
  nugetDeps = ./nuget-deps.nix;
  runtimeDeps = [
    ffmpeg
    fontconfig
    freetype
  ];
  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;
  dotnetBuildFlags = [ "--no-self-contained" ];

  preInstall = ''
    makeWrapperArgs+=(
      --add-flags "--ffmpeg ${ffmpeg}/bin/ffmpeg"
      --add-flags "--webdir ${jellyfin-web}/share/jellyfin-web"
    )
  '';

  passthru.tests = {
    smoke-test = nixosTests.jellyfin;
  };

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "The Free Software Media System";
    homepage = "https://jellyfin.org/";
    # https://github.com/jellyfin/jellyfin/issues/610#issuecomment-537625510
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      nyanloutre
      minijackson
      purcell
      jojosch
    ];
    mainProgram = "jellyfin";
    platforms = dotnet-runtime.meta.platforms;
  };
}
