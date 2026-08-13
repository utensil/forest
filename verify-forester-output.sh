#!/bin/bash
set -euo pipefail

# AGENT-NOTE: This guards Forest's XML-to-custom-XSL publication contract.

output_dir=${1:-output/forest}
shift || true

if [ ! -d "$output_dir" ]; then
    echo "Missing Forester output directory: $output_dir" >&2
    exit 1
fi

site_url=$(sed -nE 's/^url = "https?:\/\/[^/]+([^\"]*)"/\1/p' forest.toml | head -1)
home_tree=$(sed -nE 's/^home = "([^\"]+)"/\1/p' forest.toml | head -1)
root_target="${site_url%/}/${home_tree}/"

if [ -z "$site_url" ] || [ -z "$home_tree" ]; then
    echo "forest.toml must define forest.url and forest.home" >&2
    exit 1
fi

if ! grep -Fq "content=\"0;url=$root_target\"" "$output_dir/index.html"; then
    echo "Root entrypoint must redirect to $root_target" >&2
    exit 1
fi

xml_count=0
while IFS= read -r -d '' xml_file; do
    xml_count=$((xml_count + 1))
    html_file="${xml_file%index.xml}index.html"
    if [ ! -f "$html_file" ]; then
        echo "Missing rendered HTML for $xml_file" >&2
        exit 1
    fi
done < <(find "$output_dir" -mindepth 2 -maxdepth 2 -type f -name index.xml -print0)

if [ "$xml_count" -eq 0 ]; then
    echo "No rendered Forester XML pages found in $output_dir" >&2
    exit 1
fi

if find "$output_dir" -type f -name index.tree -print -quit | grep -q .; then
    echo "Forester debug index.tree files must not be published" >&2
    exit 1
fi

if rg -l 'meta.*http-equiv.*refresh.*index\.xml' "$output_dir" -g index.html | grep -q .; then
    echo "Forester redirect stubs remain after XML-to-HTML conversion" >&2
    exit 1
fi

for pdf_id in "$@"; do
    pdf_file="$output_dir/$pdf_id.pdf"
    if [ ! -s "$pdf_file" ]; then
        echo "Missing or empty PDF regression artifact: $pdf_file" >&2
        exit 1
    fi
done

echo "Forester output contract verified: $xml_count XML/HTML page pair(s)"
