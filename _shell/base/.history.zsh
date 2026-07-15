#!/usr/bin/env bash

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

alias forget=' forget_last_history_entry' # The alias starts with a space so it won't be included in history.

forget_last_history_entry() {
  # Set history file's location
  local HISTORY_FILE="${HOME}/.zsh_history"

  # Create a temp unique file
  local HISTORY_TEMP_FILE="${HISTORY_FILE}.$$"

  local LINES_TO_REMOVE="${1:-1}"

  # shellcheck disable=SC2065
  if ! test "$LINES_TO_REMOVE" -eq "$LINES_TO_REMOVE" > /dev/null 2>&1; then
		echo "Non-numeric argument provided. Exiting."
		return
	else
		LINES_TO_REMOVE="$((LINES_TO_REMOVE * -1))"
	fi

	# Write current shell's history to the history file.
  fc -W

	# Remove last lines x from history
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    < "$HISTORY_FILE" head -n "${LINES_TO_REMOVE}" &> "$HISTORY_TEMP_FILE"
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		if ! command -v ghead &> /dev/null; then
			echo head does not work with negative numbers on Mac. Use ghead instead from GNU utils.
			echo "$ brew install coreutils"
			return
		fi

		< "$HISTORY_FILE" ghead -n "${LINES_TO_REMOVE}" &> "$HISTORY_TEMP_FILE"
	fi
  mv "$HISTORY_TEMP_FILE" "$HISTORY_FILE"

	# Read history file.
  fc -R
}
