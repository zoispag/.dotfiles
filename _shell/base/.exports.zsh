# Derived statically -- `go env GOPATH` and `brew --prefix golang` cost ~60ms per
# shell between them, and neither value ever changes on a given machine.
export GOPATH="${HOME}/go"
export GOROOT="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/go/libexec"
export VOLTA_HOME="${HOME}/.volta"
export PATH="${HOME}/scripts:${VOLTA_HOME}/bin:/usr/local/sbin:${HOME}/.composer/vendor/bin:${HOME}/.yarn/bin:${HOME}/.bun/bin:${HOME}/.config/yarn/global/node_modules/.bin:${HOME}/.cargo/bin:${KREW_ROOT:-$HOME/.krew}/bin:${PATH}:${GOPATH}/bin:${GOROOT}/bin"
export OMO_SEND_ANONYMOUS_TELEMETRY=0
export OMO_DISABLE_POSTHOG=1
