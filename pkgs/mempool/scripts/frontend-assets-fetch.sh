#!/usr/bin/env bash
set -euo pipefail

# Fetch hash-locked versions of assets that are dynamically fetched via
# https://github.com/mempool/mempool/blob/master/frontend/sync-assets.js
# when running `npm run build` in the frontend.
#
# This file is updated by ./frontend-assets-update.sh

declare -A revs=(
    ["blockstream/asset_registry_db"]=be7ef2684b419966247e008d02f85611f7c038a6
    ["mempool/mining-pools"]=08f03d516b0e5533312c5de73ab18d95be71dfc3
    ["mempool/mining-pool-logos"]=dba706617cb19f8d3b90a99060e62183dc360a6b
)

fetchFile() {
    repo=$1
    file=$2
    rev=${revs["$repo"]}
    curl -fsS "https://raw.githubusercontent.com/$repo/$rev/$file"
}

fetchRepo() {
    repo=$1
    rev=${revs["$repo"]}
    curl -fsSL "https://github.com/$repo/archive/$rev.tar.gz"
}

fetchFile "blockstream/asset_registry_db" index.json > assets.json
fetchFile "blockstream/asset_registry_db" index.minimal.json > assets.minimal.json
# shellcheck disable=SC2094
fetchFile "mempool/mining-pools" pools.json > pools.json
mkdir mining-pools
fetchRepo "mempool/mining-pool-logos" | tar xz --strip-components=1 -C mining-pools
