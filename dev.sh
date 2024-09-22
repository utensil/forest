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

POLL="--poll 500ms" # $POLL

watchexec --quiet --no-vcs-ignore --project-origin . --on-busy-update queue  -e tree,tex,bib,css,js,jsx,xsl,ts,tsx,glsl,typ,domain,style,substance,trio.json -w trees -w assets -w tex -w bun --emit-events-to=stdio -- ./build_changed.sh &

http-server -p 1314 output &

wait

