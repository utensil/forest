#!/bin/bash

# echo "🛁 Cleaning up build and output"
# rm -rf build
# rm -rf output
./build.sh

watchexec --quiet --no-vcs-ignore --project-origin . --on-busy-update queue --poll 500ms -e tree,tex,css,js,xsl,ts,tsx,glsl,typ,domain,style,substance,trio.json -w trees -w assets -w tex -w bun --emit-events-to=stdio -- ./build_changed.sh &

http-server -p 1314 output &

wait

