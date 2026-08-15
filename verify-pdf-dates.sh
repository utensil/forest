#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 TREE_ID [...]" >&2
    exit 2
fi

for tree_id in "$@"; do
    source_file="trees/$tree_id.tree"
    pdf_file="output/forest/$tree_id.pdf"
    source_date=$(sed -nE 's/^[[:space:]]*\\date\{([0-9]{4})-([0-9]{2})-([0-9]{2})\}[[:space:]]*$/\1-\2-\3/p' "$source_file")

    if [ -z "$source_date" ]; then
        echo "Missing ISO publication date in $source_file" >&2
        exit 1
    fi

    IFS=- read -r year month day <<< "$source_date"
    case "$month" in
        01) month_name=January ;;
        02) month_name=February ;;
        03) month_name=March ;;
        04) month_name=April ;;
        05) month_name=May ;;
        06) month_name=June ;;
        07) month_name=July ;;
        08) month_name=August ;;
        09) month_name=September ;;
        10) month_name=October ;;
        11) month_name=November ;;
        12) month_name=December ;;
        *)
            echo "Invalid month in $source_file: $source_date" >&2
            exit 1
            ;;
    esac
    expected_date="$month_name $((10#$day)), $year"

    pdf_text=$(pdftotext "$pdf_file" -)
    if ! grep -Fqx "$expected_date" <<< "$pdf_text"; then
        echo "PDF publication date mismatch for $tree_id: expected $expected_date" >&2
        exit 1
    fi
done

echo "PDF publication dates verified for $# fixture(s)"
