#!/bin/bash

echo "🛁 Cleaning up build and output"
rm -rf build
rm -rf output
./build.sh

watchexec --no-vcs-ignore --project-origin . --on-busy-update queue --poll 500ms -e tree,tex,css,js,xsl -w trees -w assets --emit-events-to=stdio -- ./build_changed.sh &

http-server -p 1314 output &

wait

