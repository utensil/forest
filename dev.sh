#!/bin/bash

export UTS_DEV=1

# echo "🛁 Cleaning up build and output"
# rm -rf build
# rm -rf output
./build.sh

if [ $? -ne 0 ]; then
    echo "🚨 Build failed, exiting"
    exit 1
fi

# when receiving SIGINT, kill all child processes
# trap 'echo $(jobs -p) && kill -9 $(jobs -p)' SIGINT

POLL="--poll 500ms" # $POLL
BUZY_UPDATE="--on-busy-update queue" # $BUZY_UPDATE
DEBOUNCE="--debounce 500ms" # $DEBOUNCE
WPN="--wrap-process=none"
WPS="--wrap-process=session"
NPG="--no-process-group"
PO="--project-origin=."

# watchexec --quiet --ignore-nothing --no-meta $POLL $PO -e tree,tex,bib,css,js,jsx,xsl,ts,tsx,glsl,typ,domain,style,substance,trio.json -w trees -w assets -w tex -w bun --emit-events-to=stdio -- ./build_changed.sh &

watchexec --quiet --ignore-nothing --no-meta $PO -w trees -w assets -w tex -w bun --emit-events-to=stdio -- ./build_changed.sh &

export PORT=1314

# bun add http-server
# bunx http-server -p $PORT output &

# bun add reload
# ps aux|grep reload|grep node|awk '{print $2}'|xargs kill -9 #-s index.xml -f
# bunx reload -d output -p $PORT &

bun --watch --no-clear-screen dev.ts &

# echo "Open http://localhost:$PORT/index.xml"

wait
