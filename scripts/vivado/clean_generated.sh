#!/usr/bin/env bash
set -euo pipefail

# Cleans common Vivado-generated artifacts from the repo directory.
# Default is a dry-run (prints what would be removed).
#
# Usage:
#   scripts/vivado/clean_generated.sh          # dry-run
#   scripts/vivado/clean_generated.sh --force  # actually delete

force=0
if [[ ${1:-} == "--force" ]]; then
  force=1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

# Keep the .xpr and any source RTL; remove only generated dirs/files.
paths=(
  ".Xil"
  "turtle-cpu.cache"
  "turtle-cpu.hw"
  "turtle-cpu.ip_user_files"
  "turtle-cpu.sim"
  "turtle-cpu.runs"
  "turtle-cpu.gen"
  "turtle-cpu.srcs"

  "vivado.jou"
  "vivado.log"
  "vivado_"*".backup.jou"
  "vivado_"*".backup.log"
  "vivado_pid"*".str"

  "xvlog.pb"
  "xsim_"*".log"
  "xsim_"*".jou"
  "xsim_"*".wdb"
  "xsim_register_file.txt"

  "webtalk.log"
  "webtalk.jou"
  "webtalk_"*".log"
  "webtalk_"*".jou"
  "usage_statistics_"*".xml"
  "hs_err_pid"*".log"
)

# Expand globs safely.
expanded=()
shopt -s nullglob
for p in "${paths[@]}"; do
  for m in $p; do
    expanded+=("$m")
  done
done
shopt -u nullglob

if (( ${#expanded[@]} == 0 )); then
  echo "Nothing to clean."
  exit 0
fi

echo "Repo: $repo_root"
if (( force == 0 )); then
  echo "Dry-run: would remove:"
  printf '  %s\n' "${expanded[@]}"
  echo
  echo "Re-run with --force to delete."
  exit 0
fi

echo "Removing:"
printf '  %s\n' "${expanded[@]}"
rm -rf -- "${expanded[@]}"
echo "Done."
