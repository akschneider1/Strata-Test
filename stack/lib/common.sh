# shellcheck shell=bash
# Shared helpers for bin/* scripts. Source after `set -euo pipefail`.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../versions.env
# shellcheck disable=SC1091
source "$REPO_ROOT/stack/versions.env"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
ok() { printf '\033[1;32m ok\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33mwarn\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31merror\033[0m %s\n' "$*" >&2
  exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

# Put user-level tool dirs and rbenv shims on PATH so per-app .ruby-version
# files are honored without a shell restart.
setup_path() {
  ORIG_PATH="${ORIG_PATH:-$PATH}"
  export PATH="$HOME/.local/bin:$PATH"
  if have rbenv; then
    PATH="$(rbenv root)/shims:$PATH"
    export PATH
  fi
}

# Prints the template type (rails|nextjs|flask) an app was created from,
# based on the answers file nava-platform writes; empty if unknown.
app_type() {
  local name="$1" t
  for t in rails nextjs flask; do
    if [[ -f "$REPO_ROOT/.template-application-$t/$name.yml" ]]; then
      echo "$t"
      return
    fi
  done
}

# Lists apps installed from Strata application templates, one per line.
app_names() {
  local f
  for f in "$REPO_ROOT"/.template-application-*/*.yml; do
    [[ -e "$f" ]] || continue
    basename "$f" .yml
  done | sort -u
}

# Database-safe identifier for an app name (my-app -> my_app).
db_ident() { echo "${1//-/_}"; }
