
prep-llms:
    which aichat || brew install aichat
    which assembllm || (brew tap bradyjoslin/assembllm && brew install bradyjoslin/assembllm/assembllm)
    which cortex || echo "Visit https://cortex.so/docs/installation to download and install cortex"


aichat *PARAMS:
    aichat {{PARAMS}}

# a Python script to render the aichat config
sync-aichat:
    #!/usr/bin/env zsh
    ./render_yaml.py dotfiles/.config/aichat/config.yaml.in ~/.config/aichat/config.yaml
    bat ~/.config/aichat/config.yaml

prep-aider:
    just sync-aider
    which mcpm-aider || npm install -g @poai/mcpm-aider
    mkdir -p ~/.config/claude
    [[ -f ~/.config/claude/claude_desktop_config.json ]] || echo '{"mcpServers": {} }' > ~/.config/claude/claude_desktop_config.json

sync-aider:
    cp -f aider /usr/local/bin || sudo cp -f aider /usr/local/bin

# just mcp search
# just mcp install XXX
# just mcp list
# just mcp remove XXX
# just mcp toolprompt
mcp *PARAMS="":
    #!/usr/bin/env bash
    mcpm-aider {{PARAMS}}

aider PROJ="forest" *PARAMS="": sync-aider
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}} && aider {{PARAMS}}

# prep-ad:
#    #!/usr/bin/env zsh
#    rm -rf ../aider-desk
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
aw PROJ="forest" *PARAMS="":
    just aider {{PROJ}} -v --watch-files {{PARAMS}}

llm-proxy *PARAMS:
    #!/usr/bin/env bash
    # uvx --python 3.11 --from 'litellm[proxy]' litellm {{PARAMS}}
    aichat --serve 0.0.0.0:4000

llp *PARAMS:
    #!/usr/bin/env zsh
    uvx --python 3.11 --from 'litellm[proxy]' --with opentelemetry-api --with opentelemetry-sdk --with opentelemetry-exporter-otlp --with langchain --with langchain-openai --with lunary --with openinference-instrumentation-litellm litellm {{PARAMS}} --api_base {{env('OPENAI_API_BASE')}} -m 'openai/{{env('OPENAI_API_MODEL')}}' -c litellm.yaml

cpm:
    #!/usr/bin/env bash
    # if env var REFRESH_TOKEN is not set, prompt for it
    if [ -z "$REFRESH_TOKEN" ]; then
        # curl https://github.com/login/device/code -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email'
        # curl https://github.com/login/oauth/access_token -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email&device_code=YOUR_DEVICE_CODE&grant_type=urn:ietf:params:oauth:grant-type:device_code'
        echo "Please follow https://github.com/jjleng/copilot-more to set up REFRESH_TOKEN"
    fi
    if [ ! -d ../copilot-more ]; then
        (cd .. && git clone https://github.com/jjleng/copilot-more.git)
    else
        (cd ../copilot-more && git pull)
    fi
    cd ../copilot-more
    git reset --hard 21d9ee3dce5c7852d431d2c13cca72c426c8a302
    uvx poetry install
    uvx poetry run uvicorn copilot_more.server:app --port 15432 --host {{env('COPILOT_HOST', '127.0.0.1')}}


# works only for Ubuntu
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
pzh:
    uvx pdf2zh -i

DS_MODEL := "deepseek-r1:7b"
# DS_MODEL := "deepseek-r1:14b"
# DS_MODEL := "deepseek-r1:32b"

prep-om:
    which ollama || brew install ollama

om:
    ollama serve

ds:
    ollama run {{DS_MODEL}}

# VISUAL_MODEL := "llama3.2-vision"
# VISUAL_MODEL := "minicpm-v"
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
gs *PARAMS:
    #!/usr/bin/env zsh
    uvx --python 3.12 --from 'gpustack[all]' gpustack {{PARAMS}}

prep-pl:
    curl -sL https://plandex.ai/install.sh | bash

pl PROJ="forest":
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    while read -r line; do
        plandex $line
    done

prep-sg:
    #!/usr/bin/env zsh
    # https://docs.sglang.ai/start/install.html
    uv pip install sgl-kernel --force-reinstall --no-deps
    uv pip install "sglang[all]>=0.4.3.post2" --find-links https://flashinfer.ai/whl/cu124/torch2.5/flashinfer-python

prep-mlx:
    #!/usr/bin/env zsh
    # https://kconner.com/2025/02/17/running-local-llms-with-mlx.html
    # https://simonwillison.net/2025/Feb/15/llm-mlx/
    uvx llm install llm-mlx

# Models are downloaded to ~/.cache/huggingface/hub/
# See https://github.com/simonw/llm-mlx?tab=readme-ov-file#models-to-try for models to try

# just mlx download-model MODEL
# just mlx models
# just mlx import-models
mlx *PARAMS:
    #!/usr/bin/env zsh
    uvx llm mlx {{PARAMS}}

# just llm models default mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# just llm chat -m MODEL
llm *PARAMS:
    #!/usr/bin/env zsh
    uvx llm {{PARAMS}}

# lms comes with LMStudio: https://github.com/lmstudio-ai/lms
# I want it for https://github.com/lmstudio-ai/mlx-engine
prep-lms:
    #!/usr/bin/env zsh
    npx lmstudio install-cli

# lms get mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# open ~/.cache/lm-studio
# lms load mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# lms server start
lms *PARAMS:
    #!/usr/bin/env zsh
    lms {{PARAMS}}

omni *PARAMS:
    #!/usr/bin/env zsh
    uvx mlx-omni-server {{PARAMS}}

perf *PARAMS:
    # run llm_perf.py using uv with package requests installed
    uv run --with requests llm_perf.py {{PARAMS}}

# ~/.cache/lm-studio/models/
VLM_MODEL := env("VLM_MODEL", "mlx-community/Qwen2.5-VL-3B-Instruct-4bit")
VLM_PROMPT := env("VLM_PROMPT", "describe the image as detailed as possible")

vlm IMAGE *PARAMS=" --max-tokens 100 ":
    #!/usr/bin/env zsh
    uv run --python 3.12 --with 'mlx-vlm' --with torch python -m mlx_vlm.generate --model '{{VLM_MODEL}}' --prompt '{{VLM_PROMPT}}' --image {{IMAGE}} {{PARAMS}}

lobe *PARAMS:
    #!/usr/bin/env zsh
    docker run -it --rm -p 3210:3210 \
      -e OPENAI_API_KEY={{env('OPENAI_API_KEY')}} \
      -e OPENAI_PROXY_URL={{env('OPENAI_API_BASE')}} \
      -e ACCESS_CODE=lobe66 \
      --name lobe-chat \
      lobehub/lobe-chat

# Not working
prep-scr:
    curl -fsSL get.screenpi.pe/cli | sh

# prep-rd:
#     #!/usr/bin/env zsh
#     which ra-aid || (brew tap ai-christianson/homebrew-ra-aid && brew install ra-aid)

# -m Hi
# --chat
# --use-aider
rd PROJ="forest" *PARAMS="":
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    OPENAI_API_MODEL=${OPENAI_API_MODEL:-"claude-3.5-sonnet"}
    uvx --python 3.12 ra-aid --model $OPENAI_API_MODEL {{PARAMS}}

# Not working yet
dt:
    uv run --python 3.11 --with 'detikzify @ git+https://github.com/potamides/DeTikZify' -m detikzify.webui --light

kj:
    #!/usr/bin/env zsh
    CMAKE_ARGS="-DGGML_METAL=on" USE_EMBEDDED_DB="true" uvx --from 'khoj[local]' khoj --help

# --output .
# --enrich-code
# --enrich-formula
# --enrich-picture-classes
# --enrich-picture-description
# --image-export-mode [placeholder|embedded|referenced]
dl *PARAMS:
    uvx --with mlx-vlm docling {{PARAMS}}

# DOC could be a local file or an URL
dlmd DOC:
    just dl --pipeline vlm --vlm-model smoldocling {{DOC}}

