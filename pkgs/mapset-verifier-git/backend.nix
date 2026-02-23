{
  dotnetCorePackages,
  lib,
  fetchFromGitHub,
}:
dotnetCorePackages.buildDotnetModule {
  pname = "mapset-verifier-git-backend";
  version = "0.0.0-unstable-2026-02-10";

  src = fetchFromGitHub {
    owner = "Naxesss";
    repo = "MapsetVerifier";
    rev = "fbb91f01f721b440f295fca3ccd19d668478652f";
    hash = "sha256-liDCfcSNn15De2Js8wuE7I9HdMDIFFjzZjFoCnzAXcw=";
  };

  projectFile = "src/MapsetVerifier.csproj";
  nugetDeps = ./nuget-deps.json;
  dotnet-sdk = dotnetCorePackages.sdk_9_0;
  selfContainedBuild = true;
  runtimeId = "linux-x64";
  executables = [ "MapsetVerifier" ];
  dotnetInstallFlags = [
    "-p:PublishSingleFile=true"
    "-p:IncludeNativeLibrariesForSelfExtract=true"
    "-p:EnableCompressionInSingleFile=true"
    "-p:UseAppHost=true"
    "-p:DebugType=none"
    "-p:DebugSymbols=false"
    "-p:StripSymbols=true"
    "-p:PublishReadyToRun=false"
  ];

  meta = {
    description = "Mapset Verifier backend built from source";
    homepage = "https://github.com/Naxesss/MapsetVerifier";
    license = lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
