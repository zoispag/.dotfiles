#!/usr/bin/env bash

KREW_PLUGINS_PATH="$HOME/krew-plugins.txt"

function sync-krew() {
	if [[ ! -f $KREW_PLUGINS_PATH ]]; then
		echo "⚠️  No krew plugins file found at $KREW_PLUGINS_PATH"
		return 1
	fi

	if ! command -v kubectl &> /dev/null; then
		echo "❌ kubectl is not installed. Please install kubectl first."
		return 1
	fi

	echo "📦 [krew] Installing plugins..."
	LIST="$(kubectl krew list | tail -n +1 | awk '{print $1}')"
	for plugin in $(cat "$KREW_PLUGINS_PATH"); do
		if ! echo "$LIST" | grep -qx "$plugin"; then
			echo "➡️  Installing $plugin"
			kubectl krew install "$plugin"
		else
			echo "✅ $plugin already installed"
		fi
	done
}

function export-krew() {
	kubectl krew list | tail -n +1 | awk '{print $1}' > $KREW_PLUGINS_PATH
}
