# Basic configs for just and env vars

set dotenv-load
set ignore-comments

export HOMEBREW_NO_AUTO_UPDATE := "1"
# https://blog.rust-lang.org/inside-rust/2023/01/30/cargo-sparse-protocol/
# export CARGO_REGISTRIES_CRATES_IO_PROTOCOL := "sparse"
export XDG_CONFIG_HOME := home_directory() / ".config"
export TERM := "xterm-256color"
