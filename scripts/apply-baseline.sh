#!/usr/bin/env bash
# TNR WordPress Default: explicit, one-site baseline installer.
# Dry-run unless --apply is provided. Never run against a migrated/live site.
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(dirname -- "$script_dir")"
manifest="$repo_dir/manifest/default.json"
wp_path=''
site_owner=''
apply=0

usage() {
  printf '%s\n' 'Usage: apply-baseline.sh --path /home/USER/public_html --owner USER [--apply]'
  printf '%s\n' 'Without --apply this command only prints the planned changes.'
}

fail() {
  printf 'TNR WordPress baseline ERROR: %s\n' "$*" >&2
  exit 1
}

while (( $# > 0 )); do
  case "$1" in
    --path|--owner)
      (( $# >= 2 )) || fail "Missing value after $1"
      if [[ "$1" == '--path' ]]; then wp_path="$2"; else site_owner="$2"; fi
      shift 2
      ;;
    --apply) apply=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; fail "Unknown option: $1" ;;
  esac
done

[[ -n "$wp_path" && -n "$site_owner" ]] || { usage >&2; fail 'Both --path and --owner are required'; }
[[ "$wp_path" == /* && "$wp_path" != '/' ]] || fail 'WordPress path must be an absolute, non-root directory'
[[ "$site_owner" =~ ^[a-z_][a-z0-9_-]*$ ]] || fail 'Invalid Virtualmin owner name'
[[ -r "$manifest" ]] || fail 'Baseline manifest is missing'

if (( apply == 0 )); then
  printf 'TNR WORDPRESS DEFAULT — DRY RUN ONLY\n'
  printf 'Site owner: %s\nWordPress path: %s\n' "$site_owner" "$wp_path"
  printf 'Would verify the site is installed and owned by this account.\n'
  printf 'Would install/activate TNR New Site Splash 1.0.0 if absent.\n'
  printf 'Would default timezone to America/Phoenix and close new comments/pingbacks.\n'
  printf 'Would leave theme, permalinks, existing users, search visibility, SSL, mail and backups alone.\n'
  printf 'Pass --apply only on a disposable NEW WordPress test site after taking a backup.\n'
  exit 0
fi

id "$site_owner" >/dev/null 2>&1 || fail "Owner account does not exist: $site_owner"
owner_home="$(getent passwd "$site_owner" | cut -d: -f6)"
[[ -n "$owner_home" ]] || fail 'Owner home directory was not found'
owner_home="$(realpath -e -- "$owner_home")" || fail 'Invalid owner home directory'
wp_path="$(realpath -e -- "$wp_path")" || fail 'WordPress path does not exist'
[[ "$wp_path" == "$owner_home"/* ]] || fail 'WordPress path is outside the named owner home'
[[ -f "$wp_path/wp-config.php" && -f "$wp_path/wp-includes/version.php" ]] || fail 'Not an existing WordPress installation'
[[ "$(stat -c '%U' -- "$wp_path")" == "$site_owner" ]] || fail 'The webroot is not owned by the named Virtualmin user'
if (( EUID != 0 )); then
  [[ "$(id -un)" == "$site_owner" ]] || fail 'Run as root or the named site owner'
else
  command -v runuser >/dev/null || fail 'runuser is required for safe user isolation'
fi
command -v wp >/dev/null || fail 'WP-CLI is required; install it with Virtualmin WP Workbench first'
command -v python3 >/dev/null || fail 'python3 is required to read the baseline manifest'
wp_bin="$(command -v wp)"

run_wp() {
  if (( EUID == 0 )); then
    runuser -u "$site_owner" -- "$wp_bin" --path="$wp_path" "$@"
  else
    "$wp_bin" --path="$wp_path" "$@"
  fi
}

run_wp core is-installed --quiet || fail 'WP-CLI reports WordPress is not installed'

# Refuse mutable branches and unexpected repository names from the manifest.
read -r plugin_repo plugin_commit plugin_version < <(
  python3 - "$manifest" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    manifest = json.load(f)
p = manifest['plugins'][0]
print(p['repository'], p['commit'], p['version'])
PY
)
[[ "$plugin_repo" == 'tnrdevelopmentstudio/tnr-new-site-splash' ]] || fail 'Unexpected plugin repository'
[[ "$plugin_commit" =~ ^[0-9a-f]{40}$ ]] || fail 'Plugin must be pinned to an immutable commit'
[[ "$plugin_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Invalid plugin version'

if run_wp plugin is-installed tnr-new-site-splash >/dev/null 2>&1; then
  printf 'TNR splash plugin is already installed; keeping its current files.\n'
else
  for utility in curl unzip zip mktemp; do
    command -v "$utility" >/dev/null || fail "Required utility not found: $utility"
  done
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/tnr-wp-default.XXXXXXXX")" || fail 'Cannot create temporary directory'
  trap 'if [[ -n "${temp_dir:-}" && "$temp_dir" == /tmp/tnr-wp-default.* ]]; then rm -rf -- "$temp_dir"; fi' EXIT

  archive_url="https://github.com/$plugin_repo/archive/$plugin_commit.zip"
  curl --fail --silent --show-error --location --retry 2 --connect-timeout 15 --max-time 120 \
    --output "$temp_dir/source.zip" "$archive_url" || fail 'Could not download pinned TNR plugin source'
  mkdir -p "$temp_dir/source" "$temp_dir/package/tnr-new-site-splash"
  unzip -q "$temp_dir/source.zip" -d "$temp_dir/source" || fail 'Invalid plugin source archive'
  shopt -s nullglob
  matches=( "$temp_dir"/source/*/tnr-new-site-splash.php )
  (( ${#matches[@]} == 1 )) || fail 'Expected exactly one TNR splash plugin file in the archive'
  cp -- "${matches[0]}" "$temp_dir/package/tnr-new-site-splash/tnr-new-site-splash.php"
  ( cd "$temp_dir/package" && zip -q -r "$temp_dir/tnr-new-site-splash.zip" tnr-new-site-splash )
  if (( EUID == 0 )); then
    chown -R "$site_owner":"$(id -gn "$site_owner")" "$temp_dir"
  fi
  # The site user must be able to read their private temp folder for WP-CLI.
  run_wp plugin install "$temp_dir/tnr-new-site-splash.zip" --activate
fi

run_wp plugin activate tnr-new-site-splash --quiet
run_wp option update timezone_string America/Phoenix --quiet
run_wp option update default_comment_status closed --quiet
run_wp option update default_ping_status closed --quiet

printf 'TNR baseline applied successfully to %s (owner: %s).\n' "$wp_path" "$site_owner"
