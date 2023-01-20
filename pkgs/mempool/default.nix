{ lib
, stdenvNoCC
, nodejs-16_x
, nodejs-slim-16_x
, fetchFromGitHub
, fetchNodeModules
, runCommand
, makeWrapper
, curl
, cacert
, rsync
}:
rec {
  nodejs = nodejs-16_x;
  nodejsRuntime = nodejs-slim-16_x;

  src = fetchFromGitHub {
    owner = "mempool";
    repo = "mempool";
    rev = "5ff5275b362f0c45f460a536620af592da2f3d3a";
    hash = "sha256-cQIXIFPGGowNfxezbp8igcE2/IjNsTODe5XlevP3LGw=";
  };

  nodeModules = {
    frontend = fetchNodeModules {
      inherit src nodejs;
      preBuild = "cd frontend";
      hash = "sha256-goRYK1xMgyZs3EvxejFCY09fM6LMsItD2XwPPJD9Flg=";
    };
    backend = fetchNodeModules {
      inherit src nodejs;
      preBuild = "cd backend";
      hash = "sha256-ShB/vCr9HqETEp5wjg/R2HNKMbKfkxs5gfwgZpQeBhc=";
    };
  };

  frontendAssets = fetchFiles {
    name = "mempool-frontend-assets";
    hash = "sha256-ttfo5XwHN6y+F7+Nw/GelBP+lSGsBZ4xZXNkyla5Ocs=";
    fetcher = ./frontend-assets-fetch.sh;
  };

  mempool-backend = mkDerivationMempool {
    pname = "mempool-backend";

    buildPhase = ''
      cd backend
      ${sync} --chmod=+w ${nodeModules.backend}/lib/node_modules .
      patchShebangs node_modules

      npm run package

      runHook postBuild
    '';

    installPhase = ''
      mkdir -p $out/lib/mempool-backend
      ${sync} package/ $out/lib/mempool-backend

      makeWrapper ${nodejsRuntime}/bin/node $out/bin/mempool-backend \
        --add-flags $out/lib/mempool-backend/index.js

      runHook postInstall
    '';

    passthru = {
      inherit nodejs nodejsRuntime;
    };
  };

  mempool-frontend = mkDerivationMempool {
    pname = "mempool-frontend";

    buildPhase = ''
      cd frontend

      ${sync} --chmod=+w ${nodeModules.frontend}/lib/node_modules .
      patchShebangs node_modules

      # sync-assets.js is called during `npm run build` and downloads assets from the
      # internet. Disable this script and instead add the assets manually after building.
      : > sync-assets.js

      # If this produces incomplete output (when run in a different build setup),
      # see https://github.com/mempool/mempool/issues/1256
      npm run build

      # Add assets that would otherwise be downloaded by sync-assets.js
      ${sync} ${frontendAssets}/ dist/mempool/browser/resources

      runHook postBuild
    '';

    installPhase = ''
      ${sync} dist/mempool/browser/ $out

      runHook postInstall
    '';

    passthru = { assets = frontendAssets; };
  };

  mempool-nginx-conf = runCommand "mempool-nginx-conf" {} ''
    ${sync} --chmod=u+w ${./nginx-conf}/ $out
    ${sync} ${src}/production/nginx/http-language.conf $out/mempool
  '';

  sync = "${rsync}/bin/rsync -a --inplace";

  mkDerivationMempool = args: stdenvNoCC.mkDerivation ({
    version = src.rev;
    inherit src meta;

    nativeBuildInputs = [
      makeWrapper
      nodejs
      rsync
    ];

    phases = "unpackPhase patchPhase buildPhase installPhase";
  } // args);

  fetchFiles = { name, hash, fetcher }: stdenvNoCC.mkDerivation {
    inherit name;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = hash;
    nativeBuildInputs = [ curl cacert ];
    buildCommand = ''
      mkdir $out
      cd $out
      ${builtins.readFile fetcher}
    '';
  };

  meta = with lib; {
    description = "Bitcoin blockchain and mempool explorer";
    homepage = "https://github.com/mempool/mempool/";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ erikarvstedt ];
    platforms = platforms.unix;
  };
}
