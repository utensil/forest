
# prep-llms:
#     which aichat || brew install aichat
#     which assembllm || (brew tap bradyjoslin/assembllm && brew install bradyjoslin/assembllm/assembllm)
#     which cortex || echo "Visit https://cortex.so/docs/installation to download and install cortex"

prep-aichat:
    #!/usr/bin/env bash
    which aichat || brew install aichat
    mkdir -p "$HOME/Library/Application Support/aichat/"
    cat > "$HOME/Library/Application Support/aichat/config.yaml" << EOF
    model: $OPENAI_API_PROVIDER
    clients:
    - type: openai-compatible
      name: $OPENAI_API_PROVIDER
      api_base: $OPENAI_API_BASE
      api_key: $OPENAI_API_KEY
      models:
        - name: $OPENAI_API_MODEL

    EOF
    cat "$HOME/Library/Application Support/aichat/config.yaml"

aichat *PARAMS: sync-aichat
    aichat {{PARAMS}}

# Deprecated:
# In Helix, select some code, press `|` then type `aicode`
# Instead:
# In Helix, select some code, press `|` then type `aichat -c` optionally with extra `--prompt` as system prompt
#
prep-aicode:
    sudo cp -f aicode /usr/local/bin/

# Render aichat config
sync-aichat:
    #!/usr/bin/env bash
    ./render_yaml.py dotfiles/.config/aichat/config.yaml.in ~/.config/aichat/config.yaml
    cat ~/.config/aichat/config.yaml|sd 'api_key:(.*)' 'api_key: <hidden>'

prep-aider:
    just sync-aider
    which mcpm-aider || npm install -g @poai/mcpm-aider
    mkdir -p ~/.config/claude
    [[ -f ~/.config/claude/claude_desktop_config.json ]] || echo '{"mcpServers": {} }' > ~/.config/claude/claude_desktop_config.json

sync-aider:
    cp -f aider /usr/local/bin || sudo cp -f aider /usr/local/bin

todo:
    #!/usr/bin/env bash
    cat trees/uts-0018.tree |aichat --prompt "randomly suggest 3 small TODOs that I was interested to read or I intend to try"

# just mcp search
# just mcp install XXX
# just mcp list
# just mcp remove XXX
# just mcp toolprompt
#
mcp *PARAMS="":
    #!/usr/bin/env bash
    mcpm-aider {{PARAMS}}

aider PROJ="forest" *PARAMS="": # sync-aider
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && aider {{PARAMS}}

aiderweb URL:
    uvx --python 3.11 --from 'aider-chat[help,playwright,browser]' python -m aider.scrape {{URL}}

prep-mp4:
    #!/usr/bin/env bash
    just clone Olow304 memvid
    cd ~/projects/memvid
    git reset --hard 5524b0a8b268c02df01cca87110cc1b978460c97
    uv venv --python 3.11 --seed
    source .venv/bin/activate
    uv pip install -e .
    uv pip install PyPDF2 openai
    # sd 'extensions = \{' 'extensions = { ".tree", ' examples/file_chat.py
    # sd "with_suffix\('_index.json'\)" "with_suffix('.json')" examples/file_chat.py

# just mp4 forest --input-dir trees --extensions .tree
# just mp4 forest --load-existing output/dir_trees_20250606_200619.mkv
#
mp4 PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/memvid
    source .venv/bin/activate
    cd ~/projects/{{PROJ}}
    export OPENAI_BASE_URL=$OPENAI_API_BASE
    python ~/projects/memvid/examples/file_chat.py --provider openai --model $OPENAI_API_MODEL {{PARAMS}}

# prep-ad:
#    #!/usr/bin/env bash
#    rip ../aider-desk
#    if [ ! -d ../aider-desk ]; then
#        # (cd .. && git clone https://github.com/hotovo/aider-desk)
#        # clone a tag v0.4.0
#        (cd .. && git clone --branch v0.4.0 https://github.com/hotovo/aider-desk)
#    else
#        (cd ../aider-desk && git pull)
#    fi
#    cd ../aider-desk
#    npm install
#    npm run build:mac


# Uses aider in watch mode to actively monitor and assist with code changes.
# To work with other projects:
#   1. Use `just proj` to select and open a project in a new kitty terminal
#   2. Or use `just aider ../project_name` to start aider in another directory
# I've tested that it works with `AI!`, `AI?`, and `ai!`
#
aw PROJ="forest" *PARAMS="":
    just aider {{PROJ}} --watch-files {{PARAMS}} --read AGENT.md --edit-format diff # -v

llm-proxy *PARAMS:
    #!/usr/bin/env bash
    # uvx --python 3.11 --from 'litellm[proxy]' litellm {{PARAMS}}
    aichat --serve 0.0.0.0:4000

llp *PARAMS:
    #!/usr/bin/env bash
    uvx --python 3.11 --from 'litellm[proxy]' --with opentelemetry-api --with opentelemetry-sdk --with opentelemetry-exporter-otlp --with langchain --with langchain-openai --with lunary --with openinference-instrumentation-litellm litellm {{PARAMS}} --api_base {{env('OPENAI_API_BASE')}} -m 'openai/{{env('OPENAI_API_MODEL')}}' -c litellm.yaml

cpm:
    #!/usr/bin/env bash
    set -e
    # if env var REFRESH_TOKEN is not set, prompt for it
    if [ -z "$REFRESH_TOKEN" ]; then
        # curl https://github.com/login/device/code -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email'
        # curl https://github.com/login/oauth/access_token -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email&device_code=YOUR_DEVICE_CODE&grant_type=urn:ietf:params:oauth:grant-type:device_code'
        echo "Please follow https://github.com/jjleng/copilot-more to set up REFRESH_TOKEN"
    fi
    just clone jjleng copilot-more
    cd ~/projects/copilot-more
    git reset --hard 21d9ee3dce5c7852d431d2c13cca72c426c8a302
    uvx poetry install
    LOGURU_LEVEL=DEBUG uvx poetry run uvicorn copilot_more.server:app --port 15432 --host {{env('COPILOT_HOST', '127.0.0.1')}}

# -c : Generate a command to launch Claude Code with Copilot API config
cpa *PARAMS: prep-node
    #!/usr/bin/env bash
    npx -y copilot-api@latest start --port 15432 {{PARAMS}} # --verbose

cpa-usage:
    open "https://ericc-ch.github.io/copilot-api/?endpoint=http://localhost:15432/usage"
    # see also
    # - Metered usage: https://github.com/settings/billing
    # - Model multipliers: https://docs.github.com/en/copilot/concepts/copilot-billing/understanding-and-managing-requests-in-copilot#model-multipliers

# works only for Ubuntu
#
[linux]
prep-cortex:
    #!/usr/bin/env bash
    curl -L https://app.cortexcpp.com/download/latest/linux-amd64-local -o cortex.deb
    sudo dpkg -i cortex.deb
    # fix broken dependencies
    sudo apt-get install -f -y

prep-coder:
    # cortex pull bartowski/DeepSeek-V2.5-GGUF
    cortex run qwen2.5-coder

md FILE:
    uvx markitdown "{{FILE}}"

p2t FILE:
    uvx --python 3.12 --from 'pix2text[multilingual]' p2t predict --device mps --file-type pdf -i "{{FILE}}"

prep-p2t:
    #!/usr/bin/env bash
    set -e
    # if the directory not exits
    if [ ! -d ~/.pix2text-mac ]; then
        git clone https://github.com/breezedeus/Pix2Text-Mac ~/.pix2text-mac
    fi
    cd ~/.pix2text-mac
    uv venv --python 3.12 --seed
    source ~/.pix2text/.venv/bin/activate
    pip install -r requirements.txt
    pip install pix2text[multilingual]>=1.1.0.1
    python setup.py py2app -A

# https://github.com/Byaidu/PDFMathTranslate
#
pzh:
    uvx pdf2zh -i

DS_MODEL := "deepseek-r1:7b"
# DS_MODEL := "deepseek-r1:14b"
# DS_MODEL := "deepseek-r1:32b"

prep-om:
    which ollama || brew install ollama

prep-gom:
    which gollama || go install github.com/sammcj/gollama@HEAD

gom-link: prep-gom
    #!/usr/bin/env bash
    gollama -link-lmstudio --dry-run
    read -q "?Confirm linking LMStudio models to ollama (y/n)? " && gollama -link-lmstudio
    gollama -L --dry-run
    read -q "?Confirm linking ollma models to LMStudio (y/n)? " && gollama -L

gom-reset:
    gollama -cleanup

om:
    ollama serve

ds:
    ollama run {{DS_MODEL}}

# VISUAL_MODEL := "llama3.2-vision"
# VISUAL_MODEL := "minicpm-v"
#
VISUAL_MODEL := "erwan2/DeepSeek-Janus-Pro-7B"

lv:
    ollama run {{VISUAL_MODEL}}

prep-exo:
    # 1. we need uv venv --python 3.12 --seed
    # 2. we need to install exo from source
    echo "visit https://github.com/exo-explore/exo?tab=readme-ov-file#from-source"
    # 3. we need to manually install pytorch in the venv
    # 4. when in doubt, run: DEBUG=9 exo --disable-tui

prep-tr:
    brew install --cask buzz

# just gs start -s SERVER_IP --token TOKEN
# TOKEN is retrieved on server via:
# cat /var/lib/gpustack/token
#
gs *PARAMS:
    #!/usr/bin/env bash
    uvx --python 3.12 --from 'gpustack[all]' gpustack {{PARAMS}}

prep-pl:
    #!/usr/bin/env bash
    which plandex || (curl -sL https://plandex.ai/install.sh | bash)
    just clone plandex-ai plandex
    cd ~/projects/plandex/app
    sd 'docker compose' 'docker-compose' start_local.sh
    ./start_local.sh

pl PROJ="forest":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    plandex --semi

prep-sg:
    #!/usr/bin/env bash
    # https://docs.sglang.ai/start/install.html
    uv pip install sgl-kernel --force-reinstall --no-deps
    uv pip install "sglang[all]>=0.4.3.post2" --find-links https://flashinfer.ai/whl/cu124/torch2.5/flashinfer-python

prep-mlx:
    #!/usr/bin/env bash
    # https://kconner.com/2025/02/17/running-local-llms-with-mlx.html
    # https://simonwillison.net/2025/Feb/15/llm-mlx/
    uvx llm install llm-mlx

# Models are downloaded to ~/.cache/huggingface/hub/
# See https://github.com/simonw/llm-mlx?tab=readme-ov-file#models-to-try for models to try

# just mlx download-model MODEL
# just mlx models
# just mlx import-models
#
mlx *PARAMS:
    #!/usr/bin/env bash
    uvx llm mlx {{PARAMS}}

# Note: just llm doesn't work for passing quoted strings
# Use the shell alias instead
# llm models default mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# llm chat -m MODEL
# llm plugins
# llm -f github:simonw/s3-credentials 'Suggest new features for this tool'
# llm -f docs: "How do I embed a binary file?"
# llm *PARAMS:
#     uvx llm {{PARAMS}}
#
prep-llm:
    uvx llm install llm-docs
    uvx llm install llm-fragments-github
    uvx llm install llm-mlx

sync-llm:
    #!/usr/bin/env bash
    dir_llm=`dirname "$(uvx llm logs path)"`
    ./render_yaml.py dotfiles/.config/llm/extra-openai-models.yaml.in $dir_llm/extra-openai-models.yaml
    cat $dir_llm/extra-openai-models.yaml
    uvx llm keys set env_key --value ${OPENAI_API_KEY}
    uvx llm models default env

# dir-llm:
#     uv run --with 'llm' python -c 'import llm; print(llm.user_dir())'

# lms comes with LMStudio: https://github.com/lmstudio-ai/lms
# I want it for https://github.com/lmstudio-ai/mlx-engine
#
prep-lms:
    #!/usr/bin/env bash
    npx lmstudio install-cli

# lms get mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# open ~/.cache/lm-studio
# lms load mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# lms server start
#
lms *PARAMS:
    #!/usr/bin/env bash
    lms {{PARAMS}}

omni *PARAMS:
    #!/usr/bin/env bash
    uvx mlx-omni-server {{PARAMS}}

perf *PARAMS:
    # run llm_perf.py using uv with package requests installed
    uv run --with requests llm_perf.py {{PARAMS}}

# ~/.cache/lm-studio/models/
VLM_MODEL := env("VLM_MODEL", "mlx-community/Qwen2.5-VL-3B-Instruct-4bit")
VLM_PROMPT := env("VLM_PROMPT", "describe the image as detailed as possible")

vlm IMAGE *PARAMS=" --max-tokens 100 ":
    #!/usr/bin/env bash
    uv run --python 3.12 --with 'mlx-vlm' --with torch python -m mlx_vlm.generate --model '{{VLM_MODEL}}' --prompt '{{VLM_PROMPT}}' --image {{IMAGE}} {{PARAMS}}

lobe *PARAMS:
    #!/usr/bin/env bash
    docker run -it --rm -p 3210:3210 \
      -e OPENAI_API_KEY={{env('OPENAI_API_KEY')}} \
      -e OPENAI_PROXY_URL={{env('OPENAI_API_BASE')}} \
      -e ACCESS_CODE=lobe66 \
      --name lobe-chat \
      lobehub/lobe-chat

# Not working
#
prep-scr:
    curl -fsSL get.screenpi.pe/cli | sh

# prep-rd:
#     #!/usr/bin/env bash
#     which ra-aid || (brew tap ai-christianson/homebrew-ra-aid && brew install ra-aid)

# -m Hi
# --chat
# --use-aider
#
rd PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    OPENAI_API_MODEL=${OPENAI_API_MODEL:-"claude-3.5-sonnet"}
    uvx --python 3.12 ra-aid --model $OPENAI_API_MODEL {{PARAMS}}

# Not working yet
#
dt:
    uv run --python 3.11 --with 'detikzify @ git+https://github.com/potamides/DeTikZify' -m detikzify.webui --light

kj:
    #!/usr/bin/env bash
    CMAKE_ARGS="-DGGML_METAL=on" USE_EMBEDDED_DB="true" uvx --from 'khoj[local]' khoj --help

# --output .
# --enrich-code
# --enrich-formula
# --enrich-picture-classes
# --enrich-picture-description
# --image-export-mode [placeholder|embedded|referenced]
#
dl *PARAMS:
    uvx --with mlx-vlm docling {{PARAMS}}

# DOC could be a local file or an URL
#
dlmd DOC:
    just dl --pipeline vlm --vlm-model smoldocling {{DOC}}

prep-probe:
    which probe || npm install -g @buger/probe@latest
    which probe-chat || npm install -g @buger/probe-chat@latest

# in `just zsh`, --allow-edit
# --web
#
probe *PARAMS="":
    #!/usr/bin/env bash
    export OPENAI_API_URL=$OPENAI_API_BASE
    export MODEL_NAME=$OPENAI_API_MODEL
    probe-chat {{PARAMS}}

prep-dw:
    #!/usr/bin/env bash
    just clone AsyncFuncAI deepwiki-open
    cd ~/projects/deepwiki-open
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" > .env
    echo "OPENAI_API_URL=$OPENAI_API_BASE" >> .env
    mkdir -p ~/.adalflow
    # https://github.com/AsyncFuncAI/deepwiki-open/issues/20#issuecomment-2857485755

dw: prep-dw
    #!/usr/bin/env bash
    cd ~/projects/deepwiki-open
    docker-compose up

# Not working yet
#
prep-odw:
    #!/usr/bin/env bash
    just clone AIDotNet OpenDeepWiki
    cd ~/projects/OpenDeepWiki
    make build

prep-goose:
    #!/usr/bin/env bash
    mkdir -p ~/.config/goose
    cp -f dotfiles/.config/goose/config.yaml ~/.config/goose/config.yaml
    which goose || (curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | bash)

# goose info
# goose configure
# MEMORY_BANK_ROOT="$HOME/.membank" goose session
#
goose *PARAMS="session":
    #!/usr/bin/env bash
    goose {{PARAMS}}

kit-mcp:
    uv run --python 3.11 --with cased-kit python -m kit.mcp

# Choose other model
# Put the following in the box below
# base_url=https://some_api_base/v1
# api_key=YOUR_API_KEY
# see https://github.com/frdel/agent-zero/issues/326#issuecomment-2679344132
#
zero:
    docker pull frdel/agent-zero-run
    docker run --rm -p 50001:80 frdel/agent-zero-run

prep-cc:
    #!/usr/bin/env bash
    which claude || npm install -g @anthropic-ai/claude-code
    mkdir -p ~/.claude
    # https://docs.anthropic.com/en/docs/claude-code/settings
    cat > ~/.claude/settings.json << EOF
    {
      "permissions": {
        "allow": [
          "Bash(sg:*)",
          "Bash(rg:*)",
          "Bash(jj:*)",
          "Bash(backlog:*)",
          "WebFetch",
          "WebSearch",
          "Edit",
          "MultiEdit",
          "mcp__container-use__environment_checkpoint",
          "mcp__container-use__environment_file_delete",
          "mcp__container-use__environment_file_list",
          "mcp__container-use__environment_file_read",
          "mcp__container-use__environment_file_write",
          "mcp__container-use__environment_open",
          "mcp__container-use__environment_run_cmd",
          "mcp__container-use__environment_update"
        ],
        "deny": [
            "Read(.env)"
        ]
      }
    }
    EOF

prep-ccr:
    #!/usr/bin/env bash
    which ccr || npm install -g @musistudio/claude-code-router
    mkdir -p ~/.claude-code-router
    cat > ~/.claude-code-router/config.json << EOF
    {
        "LOG": true,
        "Providers": [
            {
                "name": "local",
                "api_base_url": "${OPENAI_API_BASE}/chat/completions",
                "api_key": "$OPENAI_API_KEY",
                "models": [
                    "$OPENAI_API_MODEL"
                ]
            }
        ],
        "Router": {
            "default": "local"
        }
    }
    EOF

cc-mcp-reset:
    claude mcp list|grep -v -F 'No MCP servers'|awk -F":" '{print $1}'|xargs -n 1 claude mcp remove

prep-cc-mcp PROJ="forest":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    just cc-mcp-reset
    # Add MCP servers from goose config
    claude mcp add --transport stdio playwright-mcp -- npx -y @executeautomation/playwright-mcp-server
    # claude mcp add --transport stdio memory-mcp -- npx -y @modelcontextprotocol/server-memory
    # claude mcp add --transport stdio sequential-thinking-mcp -- npx -y @modelcontextprotocol/server-sequential-thinking
    claude mcp add --transport stdio ddg-mcp -- uvx ddg-mcp
    claude mcp add --transport stdio probe-mcp -- npx -y @buger/probe-mcp
    # it works but I need to figure out how to actually use it
    # claude mcp add --transport stdio zls-mcp -- npx tritlo/lsp-mcp zig `which zls`
    # claude mcp add --transport stdio speech-mcp -- uvx speech-mcp
    # claude mcp add --transport stdio kit-mcp -- uv run --python 3.11 --with cased-kit python -m kit.mcp
    # claude mcp add --transport stdio deepwiki-mcp -e DEEPWIKI_REQUEST_TIMEOUT=60000 -- npx -y mcp-deepwiki@latest
    # claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant # --project $(pwd)

prep-cu:
    which container-use || brew install dagger/tap/container-use || ( curl -fsSL https://raw.githubusercontent.com/dagger/container-use/main/install.sh | bash )

prep-cc-cu:
    #!/usr/bin/env bash
    claude mcp add --scope user container-use -- `which cu` stdio
    # curl https://raw.githubusercontent.com/dagger/container-use/main/rules/agent.md >> CLAUDE.md
    # claude --allowedTools mcp__container-use__environment_checkpoint,mcp__container-use__environment_file_delete,mcp__container-use__environment_file_list,mcp__container-use__environment_file_read,mcp__container-use__environment_file_write,mcp__container-use__environment_open,mcp__container-use__environment_run_cmd,mcp__container-use__environment_update

# just cc forest --debug
#
ccr PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    ccr code {{PARAMS}}

# When running out of premium quota
# export ANTHROPIC_BASE_URL=http://localhost:15432 ANTHROPIC_AUTH_TOKEN=dummy ANTHROPIC_MODEL=gpt-4.1 ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1 && claude
#
cc PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    export ANTHROPIC_BASE_URL=$OPENAI_API_BASE ANTHROPIC_AUTH_TOKEN=$OPENAI_API_KEY ANTHROPIC_MODEL=$OPENAI_API_MODEL ANTHROPIC_SMALL_FAST_MODEL=$OPENAI_API_MODEL_FAST && claude

prep-codex:
    npm install -g @openai/codex

codex *PARAMS:
    #!/usr/bin/env bash
    export LOCAL_API_KEY=$OPENAI_API_KEY
    export LOCAL_BASE_URL=$OPENAI_API_BASE
    codex -a auto-edit --provider LOCAL --model $OPENAI_API_MODEL {{PARAMS}}

# build failed: FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory
#
prep-easyds:
    #!/usr/bin/env bash
    just clone ConardLi easy-dataset
    cd ~/projects/easy-dataset
    docker build -t easy-dataset .

easyds:
    #!/usr/bin/env bash
    mkdir -p ~/.easy-dataset
    docker run --rm -p 1717:1717 -v ~/.easy-dataset:/app/local-db --name easy-dataset easy-dataset

# tutorial intro
# https://docs.marimo.io/guides/package_management/inlining_dependencies/
#
mm *PARAMS="edit --sandbox":
    uvx marimo {{PARAMS}}

# dspy
# funnydspy
# math-equivalence==0.0.0 (from git+https://github.com/hendrycks/math.git@357963a7f5501a6c1708cf3f3fb0cdf525642761)

prep-amp:
    which amp || npm install -g @sourcegraph/amp
    # login, say no to re-login if already logged in
    yes n|amp login

prep-oc:
    #!/usr/bin/env bash
    which opencode || npm install -g opencode-ai
    mkdir -p ~/.config/opencode
    ./render_yaml.py --json dotfiles/.config/opencode/opencode.in.yaml ~/.config/opencode/opencode.json
    just check-oc


check-oc:
    #!/usr/bin/env bash
    set -e
    cat ~/.config/opencode/opencode.json
    opencode auth list
    # opencode auth list|grep ${OPENAI_API_PROVIDER:-GitHub Copilot}
    opencode run -m "${OPENAI_API_PROVIDER:-github-copilot}/${OPENAI_API_MODEL:-claude-sonnet-4}" --log-level DEBUG --print-logs Hi

# use `opencode auth login` to log into Github Copilot
# use `opencode run -m github-copilot/claude-3.5-sonnet --print-logs Hi` for a first run, which runs bun install that might take a while

prep-uz:
    which uzi || go install github.com/devflowinc/uzi@latest

prep-q:
    which q || brew install amazon-q
    which q || sudo ln -s "/Applications/Amazon Q.app/Contents/MacOS/q" /usr/local/bin/q
    which qchat || sudo ln -s "/Applications/Amazon Q.app/Contents/MacOS/qchat" /usr/local/bin/qchat
    which qterm || sudo ln -s "/Applications/Amazon Q.app/Contents/MacOS/qterm" /usr/local/bin/qterm
    # q login

init-q PROJ="forest":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    q chat --no-interactive "/context add AGENTS.md"
    # q chat --no-interactive '/hooks add --trigger per_prompt --command "cat AGENTS.md" AGENTS.md'

q:
    q chat --trust-tools=fs_read,fs_write "ALWAYS follow AGENTS.md"

# requires too many permissions to my GitHub account, rejected
#
prep-kb:
    npx -y vibe-kanban

# backlog init <project name>
# backlog browser
#
prep-backlog:
    bun i -g backlog.md

todos:
    backlog browser # --no-open
