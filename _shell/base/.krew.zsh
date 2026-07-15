#!/usr/bin/env bash

function export-krew() {
  kubectl krew list >"${DOTFILES:-$HOME/.dotfiles}/Krewfile"
}
