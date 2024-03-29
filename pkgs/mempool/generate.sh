#!/usr/bin/env nix-shell
#! nix-shell -i bash -p gnupg gnused jq
set -euo pipefail

# Use this to start a debug shell at the location of this statement
# . $(nix eval --raw .#lib.nix-bitcoin --apply 'nb: "${nb + "/helper/start-bash-session.sh"}"')

version=2.5.0
owner=mempool
repo=https://github.com/$owner/mempool

cd "${BASH_SOURCE[0]%/*}"

updateSrc() {
    TMPDIR="$(mktemp -d /tmp/mempool.XXX)"
    trap 'rm -rf $TMPDIR' EXIT

    # Fetch and verify source
    src=$TMPDIR/src
    mkdir -p "$src"
    if [[ -v rev ]]; then
        # Fetch revision
        git -C "$src" init
        git -C "$src" fetch --depth 1 "$repo" "$rev:src"
        git -C "$src" checkout src
    else
        tag=v$version
        # Fetch and GPG-verify version tag
        git clone --depth 1 --branch "$tag" -c advice.detachedHead=false $repo "$src"
        git -C "$src" checkout tags/$tag
        export GNUPGHOME=$TMPDIR
        # Fetch wiz' key
        gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 913C5FF1F579B66CA10378DBA394E332255A6173 2> /dev/null
        git -C "$src" verify-tag $tag
        rev=$tag
    fi
    rm -rf "$src"/.git
    hash=$(nix hash path "$src")

    sed -i "
      s|\bowner = .*;|owner = \"$owner\";|
      s|\brev = .*;|rev = \"$rev\";|
      s|\bhash = .*;|hash = \"$hash\";|
    " default.nix
}

updateNodeModulesHash() {
    component=$1
    echo
    echo "Fetching node modules for mempool-$component"
    ./scripts/update-fixed-output-derivation.sh ./default.nix mempool-"$component" "cd $component"
}

updateFrontendAssets() {
  . ./scripts/frontend-assets-update.sh
  echo
  echo "Fetching frontend assets"
  ./scripts/update-fixed-output-derivation.sh ./default.nix mempool-frontend.assets "frontendAssets"
}

if [[ $# == 0 ]]; then
    # Each of these can be run separately
    updateSrc
    updateFrontendAssets
    updateNodeModulesHash backend
    updateNodeModulesHash frontend
else
    "$@"
fi
