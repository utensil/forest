# Security audit tasks
# Audit for compromised litellm versions (supply chain attack, March 2026)
# Affected versions: v1.82.7 and v1.82.8 (published 2026-03-24)

# Reference: https://docs.litellm.ai/blog/security-update-march-2026
audit-litellm:
    #!/usr/bin/env bash
    set -e
    echo "=== LiteLLM Supply Chain Audit ==="
    echo "Checking for compromised versions (v1.82.7, v1.82.8)..."
    echo ""
    FOUND=0

    # Check pip (system and user)
    echo "--- pip ---"
    if command -v pip3 &>/dev/null; then
        VER=$(pip3 show litellm 2>/dev/null | grep "^Version:" | awk '{print $2}')
        if [ -n "$VER" ]; then
            echo "  INSTALLED via pip: v$VER"
            if [ "$VER" = "1.82.7" ] || [ "$VER" = "1.82.8" ]; then
                echo "  ⚠️  COMPROMISED VERSION DETECTED!"
                FOUND=1
            else
                echo "  ✅ Version is not affected"
            fi
        else
            echo "  ✅ Not installed via pip"
        fi
    else
        echo "  pip3 not found, skipping"
    fi

    # Check uv environments
    echo ""
    echo "--- uv environments ---"
    if [ -d "$HOME/.cache/uv/environments-v2" ]; then
        UV_FOUND=0
        for sp in "$HOME"/.cache/uv/environments-v2/*/lib/python*/site-packages; do
            if [ -d "$sp/litellm" ]; then
                VER=$(cat "$sp/litellm/version.py" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                echo "  INSTALLED in $(dirname "$(dirname "$(dirname "$sp")")"): v${VER:-unknown}"
                if [ "$VER" = "1.82.7" ] || [ "$VER" = "1.82.8" ]; then
                    echo "  ⚠️  COMPROMISED VERSION DETECTED!"
                    FOUND=1
                else
                    echo "  ✅ Version is not affected"
                fi
                UV_FOUND=1
            fi
        done
        if [ "$UV_FOUND" = "0" ]; then
            echo "  ✅ Not found in any uv environment"
        fi
    else
        echo "  No uv environments found"
    fi

    # Check uv cache for downloaded packages
    echo ""
    echo "--- uv cache ---"
    CACHED=$(find "$HOME/.cache/uv" -name "litellm-1.82.7*" -o -name "litellm-1.82.8*" 2>/dev/null)
    if [ -n "$CACHED" ]; then
        echo "  ⚠️  Compromised version found in cache:"
        echo "$CACHED" | sed 's/^/    /'
        FOUND=1
    else
        echo "  ✅ No compromised versions in cache"
    fi

    # Check for the malicious .pth file
    echo ""
    echo "--- Malicious .pth file ---"
    PTH=$(find "$HOME/.local" "$HOME/.cache" "$HOME/Library/Python" -name "litellm_init.pth" 2>/dev/null || true)
    if [ -n "$PTH" ]; then
        echo "  ⚠️  MALICIOUS FILE FOUND:"
        echo "$PTH" | sed 's/^/    /'
        FOUND=1
    else
        echo "  ✅ No litellm_init.pth found"
    fi

    # Check node_modules (litellm has a JS SDK too)
    echo ""
    echo "--- node_modules ---"
    NODE_FOUND=$(find "$HOME/projects" -path "*/node_modules/litellm" -maxdepth 5 2>/dev/null | head -5)
    if [ -n "$NODE_FOUND" ]; then
        echo "  Found in node_modules:"
        echo "$NODE_FOUND" | sed 's/^/    /'
    else
        echo "  ✅ Not found in node_modules"
    fi

    # Summary
    echo ""
    echo "=== Summary ==="
    if [ "$FOUND" = "1" ]; then
        echo "⚠️  ACTION REQUIRED: Compromised litellm detected!"
        echo "  1. Rotate ALL credentials (API keys, SSH keys, cloud tokens, DB passwords)"
        echo "  2. Remove litellm_init.pth if found"
        echo "  3. Downgrade to v1.82.6 or remove litellm"
        echo "  4. Audit CI/CD pipelines and Docker builds"
        exit 1
    else
        echo "✅ No compromised litellm versions found on this system"
        exit 0
    fi
