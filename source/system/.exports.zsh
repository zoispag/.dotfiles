export GOPATH=$(go env GOPATH)
export GOROOT="$(brew --prefix golang)/libexec"
export VOLTA_HOME="${HOME}/.volta"
export PATH="${HOME}/scripts:${VOLTA_HOME}/bin:/usr/local/sbin:${HOME}/.composer/vendor/bin:${HOME}/.yarn/bin:${HOME}/.bun/bin:${HOME}/.config/yarn/global/node_modules/.bin:${HOME}/.cargo/bin:${KREW_ROOT:-$HOME/.krew}/bin:${PATH}:${GOPATH}/bin:${GOROOT}/bin"
