#!/bin/bash
# Tests for the pi extensions in ../. They run on a copy in a temp directory
# whose node_modules links to the installed pi's, so they test against the
# packages pi itself loads, with nothing to install. After a pi upgrade they
# test against the new versions.
#
#   tests/run.sh            the fast tests, about a second
#   tests/run.sh --mutants  also break each extension in several ways; every
#                           mutant must fail a test
#   tests/run.sh --live     also drive real pi over RPC with a cheap model
#                           through magpie: about 5 minutes and a few cents
#                           (LOOP_TEST_MODEL picks another model)
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
agent=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
version=$(cat "$agent/install/current-version")
modules=$agent/install/releases/$version/node_modules
if [ ! -d "$modules/typebox" ]; then
	echo "no pi packages at $modules" >&2
	exit 1
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/pi-extension-tests.XXXXXX")
trap 'rm -rf "$work"' EXIT
cp "$here"/../loop.ts "$here"/*.ts "$here"/*.mjs "$here"/*.sh "$work"/
ln -s "$modules" "$work/node_modules"
cd "$work"
echo "pi $version, node $(node --version)"

node --test ./*.test.ts

case "${1:-}" in
	--mutants) ./loop-mutants.sh ;;
	--live) node loop-live.mjs && node loop-live-reload.mjs ;;
	"") ;;
	*) echo "unknown option: $1" >&2; exit 2 ;;
esac
