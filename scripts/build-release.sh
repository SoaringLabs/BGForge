#!/usr/bin/env bash

set -euo pipefail

usage() {
    printf 'Usage: %s vX.Y.Z\n' "$(basename "$0")" >&2
}

if [[ $# -ne 1 ]]; then
    usage
    exit 2
fi

release_tag=$1
if [[ ! $release_tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    printf 'error: release tag must look like v0.3.0 (got %s)\n' "$release_tag" >&2
    exit 2
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
cd "$repo_root"

if ! git rev-parse --verify --quiet "refs/tags/${release_tag}^{commit}" >/dev/null; then
    printf 'error: tag %s does not exist locally\n' "$release_tag" >&2
    exit 1
fi

version=${release_tag#v}
toc_version=$(git show "${release_tag}:BGForge.toc" | awk '$1 == "##" && $2 == "Version:" { print $3; exit }')

if [[ $toc_version != "$version" ]]; then
    printf 'error: BGForge.toc says %s, but the tag is %s\n' "$toc_version" "$release_tag" >&2
    exit 1
fi

# Keep this allowlist aligned with files loaded by WoW. Repository documentation,
# tests, agent instructions, and other development artifacts stay out of releases.
package_paths=(
    BGForge.toc
    Bindings.xml
    CHANGELOG.md
    README.md
    Templates.xml
    Core
    Libs
    Locales
    Media
)

output_dir="$repo_root/dist"
output_path="$output_dir/BGForge-${release_tag}.zip"
mkdir -p "$output_dir"
temporary_archive=$(mktemp "$output_dir/.BGForge-${release_tag}.XXXXXX.zip")
trap 'rm -f "$temporary_archive"' EXIT

git archive \
    --format=zip \
    --prefix=BGForge/ \
    --output="$temporary_archive" \
    "$release_tag" \
    -- "${package_paths[@]}"

unzip -tq "$temporary_archive" >/dev/null

archive_listing=$(unzip -Z1 "$temporary_archive")
required_entries=(
    BGForge/BGForge.toc
    BGForge/Core/BiaoGe.lua
    BGForge/Locales/zhCN.lua
)
for entry in "${required_entries[@]}"; do
    if ! grep -Fqx "$entry" <<<"$archive_listing"; then
        printf 'error: release archive is missing %s\n' "$entry" >&2
        exit 1
    fi
done

forbidden_patterns=(
    '^BGForge/docs/'
    '^BGForge/tests/'
    '^BGForge/\.DS_Store$'
    '^BGForge/AGENTS(\.override)?\.md$'
    '^BGForge/addon_version\.txt$'
    '^BGForge/design-qa\.md$'
)
for pattern in "${forbidden_patterns[@]}"; do
    if grep -Eq "$pattern" <<<"$archive_listing"; then
        printf 'error: release archive contains a development artifact matching %s\n' "$pattern" >&2
        exit 1
    fi
done

chmod 0644 "$temporary_archive"
mv -f "$temporary_archive" "$output_path"
trap - EXIT

archive_size=$(wc -c <"$output_path" | tr -d ' ')
if command -v shasum >/dev/null 2>&1; then
    archive_sha=$(shasum -a 256 "$output_path" | awk '{ print $1 }')
else
    archive_sha=$(sha256sum "$output_path" | awk '{ print $1 }')
fi

printf 'Built %s\n' "$output_path"
printf 'Size: %s bytes\n' "$archive_size"
printf 'SHA-256: %s\n' "$archive_sha"
