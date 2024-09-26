#!/bin/bash

# run the following to install deps the first time
# brew install orbstack
# brew install gh
# brew install act

# gh auth login

# wait for 20GB download the first time
# --container-architecture linux/amd64 is need on my Mac M1
act -s GITHUB_TOKEN="$(gh auth token)" push -j build --container-architecture linux/amd64 -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-latest
