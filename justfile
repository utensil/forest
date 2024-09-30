# to access recipes without prefixing `just`, run `source ./init.sh` after openning each new terminal
default:
    just --list

new +X:
    ./new.sh {{X}}

build:
    ./build.sh

dev:
    ./dev.sh

lize:
    ./lize.sh

fize:
    ./fize.py

chk:
    ./chk.sh

thm:
    ./thm.sh

bib:
    ./bib.sh

# act:
#     ./act.sh
