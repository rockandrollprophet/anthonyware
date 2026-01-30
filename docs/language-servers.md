# Language Server Installation Guide

Below are the recommended language servers for your stack, with install commands for Arch Linux:

## Python

- Language Server: pyright
- Install: `npm install -g pyright`

## JavaScript/TypeScript

- Language Server: typescript-language-server
- Install: `npm install -g typescript typescript-language-server`

## Shell (Bash)

- Language Server: bash-language-server
- Install: `npm install -g bash-language-server`

## Go

- Language Server: gopls
- Install: `go install golang.org/x/tools/gopls@latest`

## Rust

- Language Server: rust-analyzer
- Install: `sudo pacman -S rust-analyzer`

## C/C++

- Language Server: clangd
- Install: `sudo pacman -S clang clang-tools-extra`

## Java

- Language Server: jdtls
- Install: `sudo pacman -S jdtls`

---

After installing, reload VS Code. Most language servers will be auto-detected by VS Code extensions.
