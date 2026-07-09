#!/usr/bin/env bash

function sync-krew() {
	"$HOME/bin/sync-krew" sync
}

function export-krew() {
	"$HOME/bin/sync-krew" export
}
