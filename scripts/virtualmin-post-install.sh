#!/usr/bin/env bash
# Opt-in wrapper for Virtualmin's post-modification hook.
# Ship disabled. Do not install into live Virtualmin until a pilot passes.
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Virtualmin calls the post-modification command for many server actions;
# never act on domain creation, deletion, upgrades, or non-WordPress scripts.
[[ "${VIRTUALSERVER_ACTION:-}" == 'SCRIPT_DOMAIN' ]] || exit 0
[[ "${VIRTUALSERVER_LASTSAVE_SCRIPT:-}" == 'wordpress' ]] || exit 0
[[ "${SCRIPT_UPGRADE:-0}" != '1' ]] || exit 0

# Explicit opt-in required, even after someone configures this hook in Virtualmin.
if [[ "${TNR_WP_BASELINE_ENABLED:-0}" != '1' ]]; then
  printf 'TNR WP default: fresh WordPress detected; baseline is disabled.\n'
  exit 0
fi

wp_path="${SCRIPT_PATH:-}"
site_owner="${VIRTUALSERVER_USER:-}"
if [[ -z "$wp_path" || -z "$site_owner" ]]; then
  printf 'TNR WP default: skipped, missing SCRIPT_PATH or VIRTUALSERVER_USER.\n' >&2
  exit 0
fi

if ! "$script_dir/apply-baseline.sh" --path "$wp_path" --owner "$site_owner" --apply; then
  # Never make an otherwise successful Virtualmin install look rolled back.
  printf 'TNR WP default: baseline failed for %s; review the error and retry manually.\n' "${VIRTUALSERVER_DOM:-unknown}" >&2
fi
exit 0
