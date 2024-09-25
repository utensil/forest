#!/bin/bash
git submodule deinit --all -f
git rm theme -f
rm -rf theme
rm -rf .git/modules/theme
# git submodule add -f -b fix-data-taxon --name theme https://git.sr.ht/~utensil/forester-base-theme theme
# git submodule add -f --name theme https://git.sr.ht/~jonsterling/forester-base-theme theme
git submodule add -f --name theme https://github.com/utensil/forester-base-theme theme
git submodule update --init --recursive
git submodule update --remote --merge