#!/bin/bash

rm -rf build
rm -rf output
./build.sh

watchexec --no-vcs-ignore --project-origin . --on-busy-update queue --poll 500ms -e tree,tex,css,js,xsl -w trees -w assets --emit-events-to=stdio -- ./build_changed.sh

