#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq nix-prefetch-github

set -euo pipefail
echoerr() { echo "$@" 1>&2; }

fname="$1"
echoerr got fname $fname
shift
datasets="$@"
echoerr datasets are: "$@"
latest_release=$(curl --silent https://api.github.com/repos/scipy/scipy/releases/latest)
version=$(jq -r '.tag_name' <<<"$latest_release" | cut -c2-)
# Update version, if needed
if grep -q 'version = "'$version $fname; then
    echo "Current version $version is the latest available, will update only datasets' hashes (don't take long)"
else
    echoerr got version $version
    sed -i -E 's/(version = ).*=/\1'$version'/g' $fname
    # Update srcHash
    srcHash='"sha256-'$(nix-prefetch-github scipy scipy --rev v${version} --fetch-submodules | jq --raw-output .sha256)'"'
    sed -i 's/srcHash = .*=";/srcHash = '$srcHash';/g' $fname
fi

for d in $datasets; do
    datasetHash=$(nix-prefetch-url "https://raw.githubusercontent.com/scipy/dataset-${d}/main/${d}.dat")
    sed -i 's/'$d' = "[0-9a-z]\+/'$d' = "'$datasetHash'/g' $fname
    echoerr updated hash for dataset "'$d'"
done
