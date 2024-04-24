#!/bin/bash
rm -rf output
opam exec -- forester build --dev
