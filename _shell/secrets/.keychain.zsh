# Cache environment variables from 1Password in the macOS Keychain
#
# `syncSecrets` reads the ENTRIES section of a 1Password item (field label is
# the variable name, field value its value) and stores it in the login Keychain.
# Every new shell then exports those variables from the Keychain, without
# calling `op`. Run it again after changing the item.
# Fields that are empty or still set to CHANGE_ME are skipped.
#
# Examples:
# - `$ syncSecrets`
# - `$ syncSecrets "Keychain Secrets" my`

_KEYCHAIN_ENV_SERVICE=dotfiles-env
# `security -i` cuts lines at about 4 KB, so the data is stored in chunks.
_KEYCHAIN_ENV_CHUNK=3000

function syncSecrets() {
	[[ $OSTYPE == darwin* ]] || { echo "syncSecrets: macOS only" >&2; return 1; }
	local item=${1:-Keychain Secrets}
	local opaccount=${2:-my}

	local res
	res=$(op --account "$opaccount" item get "$item" --format json) || return 1

	# Values travel base64-encoded so multi-line secrets survive the loop.
	local env="" row name value
	local -a skipped
	for row in ${(f)"$(jq -r '.fields[] | select(.section.label=="ENTRIES") | [(.label // ""), ((.value // "") | tostring | @base64)] | @tsv' <<<"$res")"}; do
		name=${row%%$'\t'*}
		value=$(base64 -D <<<"${row#*$'\t'}")
		if [[ ! $name =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]]; then
			echo "* Skipping field '${name}': not a valid variable name" >&2
			continue
		fi
		if [[ -z $value || $value == CHANGE_ME ]]; then
			skipped+=($name)
			continue
		fi
		env+="export ${name}=${(qq)value}"$'\n'
		echo "* Storing ${name}"
	done
	(( ${#skipped} )) && echo "* Skipped (empty or CHANGE_ME): ${skipped[*]}"

	if [[ -z $env ]]; then
		echo "syncSecrets: no variables found in '${item}', Keychain left unchanged" >&2
		return 1
	fi
	_keychainEnvWrite "$env" || return 1
	_keychainEnvLoad
	echo "* Done. Open a new shell (and restart Claude Code) to pick up the changes."
}

# Store the export lines in the Keychain as base64 chunks: <service>.0, .1, …
# The value goes through `security -i` on stdin so it never shows up in `ps`.
function _keychainEnvWrite() {
	local blob=$(print -rn -- "$1" | base64 | tr -d '\n')
	local rest=$blob i=0
	while [[ -n $rest ]]; do
		print -r -- "add-generic-password -U -a ${USER} -s ${_KEYCHAIN_ENV_SERVICE}.${i} -w ${rest[1,_KEYCHAIN_ENV_CHUNK]}" | security -i
		rest=${rest[_KEYCHAIN_ENV_CHUNK+1,-1]}
		(( i++ ))
	done
	# Remove chunks left over from an earlier, larger sync.
	local j=$i
	while security delete-generic-password -a "$USER" -s "${_KEYCHAIN_ENV_SERVICE}.${j}" >/dev/null 2>&1; do
		(( j++ ))
	done

	if [[ "$(_keychainEnvRead)" != "$blob" ]]; then
		echo "syncSecrets: Keychain data does not match what was written" >&2
		return 1
	fi
}

function _keychainEnvRead() {
	local blob="" chunk i=0
	while chunk=$(security find-generic-password -a "$USER" -s "${_KEYCHAIN_ENV_SERVICE}.${i}" -w 2>/dev/null); do
		blob+=$chunk
		(( ${#chunk} < _KEYCHAIN_ENV_CHUNK )) && break
		(( i++ ))
	done
	print -rn -- "$blob"
}

function _keychainEnvLoad() {
	[[ $OSTYPE == darwin* ]] || return 0
	local blob=$(_keychainEnvRead)
	[[ -n $blob ]] && eval "$(print -r -- "$blob" | base64 -D)"
}

_keychainEnvLoad
