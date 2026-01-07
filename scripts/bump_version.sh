#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
project_root="$repo_root/apps/keyboard-defense-godot"
version_path="$project_root/VERSION.txt"
preset_path="$project_root/export_presets.cfg"
default_version="0.0.0"
declare -A preset_product
declare -A preset_file
declare -A preset_seen
declare -a preset_indices_sorted

fail() {
  echo "$1" >&2
  exit 1
}

read_version() {
  if [[ -f "$version_path" ]]; then
    local value
    value="$(head -n 1 "$version_path" | tr -d '\r\n')"
    if [[ -n "$value" ]]; then
      echo "$value"
      return
    fi
  fi
  echo "$default_version"
}

read_version_raw() {
  if [[ -f "$version_path" ]]; then
    head -n 1 "$version_path" | tr -d '\r\n'
    return
  fi
  echo ""
}

trim_line() {
  local line="$1"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  echo "$line"
}

load_preset_versions() {
  if [[ ! -f "$preset_path" ]]; then
    fail "ERROR: Missing export preset: $preset_path"
  fi

  preset_product=()
  preset_file=()
  preset_seen=()
  preset_indices_sorted=()
  current_preset=""
  current_section=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    trimmed="$(trim_line "$line")"
    if [[ "$trimmed" =~ ^\[preset\.([0-9]+)\.options\]$ ]]; then
      current_preset="${BASH_REMATCH[1]}"
      current_section="options"
      if [[ -z "${preset_seen[$current_preset]+x}" ]]; then
        preset_indices_sorted+=("$current_preset")
        preset_seen["$current_preset"]=1
      fi
      continue
    fi
    if [[ "$trimmed" =~ ^\[preset\.([0-9]+)\]$ ]]; then
      current_preset="${BASH_REMATCH[1]}"
      current_section="preset"
      continue
    fi
    if [[ "$current_section" == "options" && -n "$current_preset" ]]; then
      if [[ "$trimmed" =~ ^application/product_version=\"(.*)\"$ ]]; then
        preset_product["$current_preset"]="${BASH_REMATCH[1]}"
      elif [[ "$trimmed" =~ ^application/file_version=\"(.*)\"$ ]]; then
        preset_file["$current_preset"]="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$preset_path"

  if [[ "${#preset_indices_sorted[@]}" -gt 0 ]]; then
    mapfile -t preset_indices_sorted < <(printf '%s\n' "${preset_indices_sorted[@]}" | sort -n)
  fi

  for preset_index in "${preset_indices_sorted[@]}"; do
    local product="${preset_product[$preset_index]-}"
    local file="${preset_file[$preset_index]-}"
    if [[ -z "$product" || -z "$file" ]]; then
      fail "ERROR: Missing version keys in preset options for preset index $preset_index"
    fi
  done
}

current_version="$(read_version)"

if [[ $# -eq 0 ]]; then
  echo "Current version: $current_version"
  echo "Usage:"
  echo "  bash ./scripts/bump_version.sh set <version>"
  echo "  bash ./scripts/bump_version.sh apply <version>"
  echo "  bash ./scripts/bump_version.sh patch"
  echo "  bash ./scripts/bump_version.sh minor"
  echo "  bash ./scripts/bump_version.sh major"
  echo "  bash ./scripts/bump_version.sh apply patch"
  echo "  bash ./scripts/bump_version.sh apply minor"
  echo "  bash ./scripts/bump_version.sh apply major"
  exit 0
fi

mode="$1"
target_version=""
increment_mode=""
if [[ "$mode" == "set" ]]; then
  if [[ $# -lt 2 ]]; then
    fail "ERROR: Missing version. Use set <version> or apply <version>."
  fi
  target_version="$2"
elif [[ "$mode" == "apply" ]]; then
  if [[ $# -lt 2 ]]; then
    fail "ERROR: Missing version. Use set <version> or apply <version>."
  fi
  if [[ "$2" == "patch" || "$2" == "minor" || "$2" == "major" ]]; then
    increment_mode="$2"
  else
    target_version="$2"
  fi
elif [[ "$mode" == "patch" || "$mode" == "minor" || "$mode" == "major" ]]; then
  increment_mode="$mode"
else
  fail "ERROR: Unknown mode: $mode"
fi

if [[ -n "$increment_mode" ]]; then
  current_raw="$(read_version_raw)"
  if [[ -z "$current_raw" || ! "$current_raw" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "ERROR: Current VERSION.txt is missing or invalid; use set <version>."
  fi
  IFS='.' read -r current_major current_minor current_patch <<< "$current_raw"
  case "$increment_mode" in
    patch)
      current_patch=$((current_patch + 1))
      ;;
    minor)
      current_minor=$((current_minor + 1))
      current_patch=0
      ;;
    major)
      current_major=$((current_major + 1))
      current_minor=0
      current_patch=0
      ;;
  esac
  target_version="${current_major}.${current_minor}.${current_patch}"
else
  if [[ ! "$target_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "ERROR: Invalid version: $target_version"
  fi
fi
load_preset_versions

if [[ "$mode" == "set" || ( -n "$increment_mode" && "$mode" != "apply" ) ]]; then
  echo "VERSION.txt: $current_version -> $target_version"
  echo "export_presets.cfg:"
  for preset_index in "${preset_indices_sorted[@]}"; do
    echo "  preset.${preset_index}: product_version ${preset_product[$preset_index]} -> $target_version; file_version ${preset_file[$preset_index]} -> $target_version"
  done
  exit 0
fi

tmp_version="$(mktemp)"
tmp_preset="$(mktemp)"
cleanup() {
  rm -f "$tmp_version" "$tmp_preset"
}
trap cleanup EXIT

printf '%s\n' "$target_version" > "$tmp_version"

current_preset=""
current_section=""
while IFS= read -r line || [[ -n "$line" ]]; do
  trimmed="$(trim_line "$line")"
  if [[ "$trimmed" =~ ^\[preset\.([0-9]+)\.options\]$ ]]; then
    current_preset="${BASH_REMATCH[1]}"
    current_section="options"
  elif [[ "$trimmed" =~ ^\[preset\.([0-9]+)\]$ ]]; then
    current_preset="${BASH_REMATCH[1]}"
    current_section="preset"
  fi
  if [[ "$current_section" == "options" ]]; then
    if [[ "$trimmed" =~ ^application/product_version=\".*\"$ ]]; then
      line="${line%%application/product_version=*}application/product_version=\"$target_version\""
    elif [[ "$trimmed" =~ ^application/file_version=\".*\"$ ]]; then
      line="${line%%application/file_version=*}application/file_version=\"$target_version\""
    fi
  fi
  printf '%s\n' "$line" >> "$tmp_preset"
done < "$preset_path"

mv -f "$tmp_version" "$version_path"
mv -f "$tmp_preset" "$preset_path"

echo "Bumped version to $target_version"
