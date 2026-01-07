#!/usr/bin/env bash
set -euo pipefail
if [[ ! -x "$0" ]]; then
  chmod +x "$0" 2>/dev/null || true
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRESET="Windows Desktop"
OUTPUT_REL="build/windows/KeyboardDefense.exe"
OUTPUT="${ROOT}/${OUTPUT_REL}"
OUTPUT_DIR_REL="$(dirname "${OUTPUT_REL}")"
OUTPUT_DIR="${ROOT}/${OUTPUT_DIR_REL}"
ZIP_REL="build/windows/KeyboardDefense-win64.zip"
PRESET_FILE="${ROOT}/export_presets.cfg"

DEFAULT_PRODUCT_NAME="Keyboard Defense"
DEFAULT_PRODUCT_VERSION="0.0.0"
PRODUCT_NAME="${DEFAULT_PRODUCT_NAME}"
PRODUCT_VERSION="${DEFAULT_PRODUCT_VERSION}"
FILE_VERSION="${DEFAULT_PRODUCT_VERSION}"
EMBED_PCK="false"
MATCHED_ID=""
if [[ -f "${PRESET_FILE}" ]]; then
  mapfile -t PRESET_LINES < "${PRESET_FILE}"
  current_id=""
  for line in "${PRESET_LINES[@]}"; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    if [[ "${trimmed}" =~ ^\[preset\.([0-9]+)\]$ ]]; then
      current_id="${BASH_REMATCH[1]}"
      continue
    fi
    if [[ -n "${current_id}" && "${trimmed}" =~ ^name=\"(.*)\"$ ]]; then
      if [[ "${BASH_REMATCH[1]}" == "${PRESET}" ]]; then
        MATCHED_ID="${current_id}"
      fi
    fi
  done

  if [[ -n "${MATCHED_ID}" ]]; then
    current_id=""
    current_section=""
    found_embed=false
    found_name=false
    found_version=false
    found_file_version=false
    for line in "${PRESET_LINES[@]}"; do
      trimmed="${line#"${line%%[![:space:]]*}"}"
      trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
      if [[ "${trimmed}" =~ ^\[preset\.([0-9]+)\]$ ]]; then
        current_id="${BASH_REMATCH[1]}"
        current_section="preset"
        continue
      fi
      if [[ "${trimmed}" =~ ^\[preset\.([0-9]+)\.options\]$ ]]; then
        current_id="${BASH_REMATCH[1]}"
        current_section="options"
        continue
      fi
      if [[ "${current_section}" != "options" || "${current_id}" != "${MATCHED_ID}" ]]; then
        continue
      fi
      if [[ "${trimmed}" =~ ^binary_format/embed_pck=(true|false)$ ]]; then
        EMBED_PCK="${BASH_REMATCH[1]}"
        found_embed=true
        continue
      fi
      if [[ "${trimmed}" =~ ^application/product_name=\"(.*)\"$ ]]; then
        if [[ -n "${BASH_REMATCH[1]}" ]]; then
          PRODUCT_NAME="${BASH_REMATCH[1]}"
          found_name=true
        fi
        continue
      fi
      if [[ "${trimmed}" =~ ^application/product_version=\"(.*)\"$ ]]; then     
        if [[ -n "${BASH_REMATCH[1]}" ]]; then
          PRODUCT_VERSION="${BASH_REMATCH[1]}"
          found_version=true
        fi
        continue
      fi
      if [[ "${trimmed}" =~ ^application/file_version=\"(.*)\"$ ]]; then
        if [[ -n "${BASH_REMATCH[1]}" ]]; then
          FILE_VERSION="${BASH_REMATCH[1]}"
          found_file_version=true
        fi
        continue
      fi
      if [[ "${found_embed}" == true && "${found_name}" == true && "${found_version}" == true && "${found_file_version}" == true ]]; then
        break
      fi
    done
  fi
fi

if [[ -z "${PRODUCT_NAME}" ]]; then
  PRODUCT_NAME="${DEFAULT_PRODUCT_NAME}"
fi
if [[ -z "${PRODUCT_VERSION}" ]]; then
  PRODUCT_VERSION="${DEFAULT_PRODUCT_VERSION}"
fi
if [[ -z "${FILE_VERSION}" ]]; then
  FILE_VERSION="${DEFAULT_PRODUCT_VERSION}"
fi

VERSION_FILE="${ROOT}/VERSION.txt"
VERSION_VALUE="${DEFAULT_PRODUCT_VERSION}"
if [[ -f "${VERSION_FILE}" ]]; then
  VERSION_VALUE="$(head -n 1 "${VERSION_FILE}" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
fi
if [[ -z "${VERSION_VALUE}" ]]; then
  VERSION_VALUE="${DEFAULT_PRODUCT_VERSION}"
fi

ZIP_VERSIONED_REL="build/windows/KeyboardDefense-${PRODUCT_VERSION}-win64.zip"
MANIFEST_REL="build/windows/export_manifest.json"
MANIFEST="${ROOT}/${MANIFEST_REL}"

PCK_REL="none"
PCK=""
if [[ "${EMBED_PCK}" == "false" ]]; then
  PCK_REL="${OUTPUT_REL%.exe}.pck"
  PCK="${ROOT}/${PCK_REL}"
fi

if [[ -n "${GODOT_BIN:-}" ]]; then
  GODOT="${GODOT_BIN}"
  GODOT_SOURCE="GODOT_BIN"
else
  GODOT="godot"
  GODOT_SOURCE="PATH"
fi

GODOT_RESOLVED="${GODOT}"
GODOT_FOUND=true
if [[ "${GODOT_SOURCE}" == "PATH" ]]; then
  if command -v "${GODOT}" >/dev/null 2>&1; then
    GODOT_RESOLVED="$(command -v "${GODOT}")"
  else
    GODOT_FOUND=false
  fi
else
  if [[ ! -f "${GODOT}" ]]; then
    GODOT_FOUND=false
  fi
fi

MODE="dry-run"
APPLY=false
PACKAGE=false
VERSIONED=false
for arg in "$@"; do
  if [[ "${arg}" == "apply" ]]; then
    APPLY=true
  elif [[ "${arg}" == "package" ]]; then
    PACKAGE=true
  elif [[ "${arg}" == "versioned" ]]; then
    VERSIONED=true
  fi
done
if [[ "${APPLY}" == true && "${PACKAGE}" == true ]]; then
  MODE="apply+package"
elif [[ "${APPLY}" == true ]]; then
  MODE="apply"
elif [[ "${PACKAGE}" == true ]]; then
  MODE="package"
fi

ZIP_SELECTED_REL="${ZIP_REL}"
if [[ "${VERSIONED}" == true ]]; then
  ZIP_SELECTED_REL="${ZIP_VERSIONED_REL}"
fi
ZIP_SELECTED="${ROOT}/${ZIP_SELECTED_REL}"

GODOT_LABEL="${GODOT_RESOLVED}"
if [[ "${GODOT_FOUND}" == false ]]; then
  GODOT_LABEL="${GODOT_RESOLVED} (not found)"
fi

COMMAND="\"${GODOT_RESOLVED}\" --headless --path \"${ROOT}\" --export-release \"${PRESET}\" \"${OUTPUT_REL}\""
OUTPUT_NAME="$(basename "${OUTPUT_REL}")"
PCK_NAME=""
if [[ "${EMBED_PCK}" == "false" ]]; then
  PCK_NAME="$(basename "${PCK_REL}")"
fi
MANIFEST_NAME="$(basename "${MANIFEST_REL}")"
ZIP_NAME="$(basename "${ZIP_SELECTED_REL}")"
ZIP_INPUTS=("${OUTPUT_NAME}")
if [[ "${EMBED_PCK}" == "false" ]]; then
  ZIP_INPUTS+=("${PCK_NAME}")
fi
ZIP_INPUTS+=("${MANIFEST_NAME}")

ZIP_TOOL="none"
ZIP_COMMAND="zip tool not found"
if command -v zip >/dev/null 2>&1; then
  ZIP_TOOL="zip"
  ZIP_COMMAND="zip -q \"${ZIP_NAME}\" ${ZIP_INPUTS[*]}"
elif command -v python3 >/dev/null 2>&1; then
  ZIP_TOOL="python3"
  ZIP_COMMAND="python3 -m zipfile -c \"${ZIP_NAME}\" ${ZIP_INPUTS[*]}"
fi

FILE_VERSION_MISMATCH=false
if [[ "${FILE_VERSION}" != "${PRODUCT_VERSION}" ]]; then
  FILE_VERSION_MISMATCH=true
fi
VERSION_FILE_MISMATCH=false
if [[ "${VERSION_VALUE}" != "${FILE_VERSION}" ]]; then
  VERSION_FILE_MISMATCH=true
fi
VERSION_MISMATCH=false
if [[ "${VERSION_VALUE}" != "${PRODUCT_VERSION}" ]]; then
  VERSION_MISMATCH=true
fi

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

write_manifest() {
  local manifest_path="$1"
  shift
  local outputs=("$@")
  local escaped_preset
  local escaped_name
  local escaped_version
  escaped_preset="$(json_escape "${PRESET}")"
  escaped_name="$(json_escape "${PRODUCT_NAME}")"
  escaped_version="$(json_escape "${PRODUCT_VERSION}")"
  {
    echo "{"
    echo "  \"schema\": \"typing-defense.export-manifest\","
    echo "  \"schema_version\": 1,"
    echo "  \"preset\": \"${escaped_preset}\","
    echo "  \"product_name\": \"${escaped_name}\","
    echo "  \"product_version\": \"${escaped_version}\","
    echo "  \"embed_pck\": ${EMBED_PCK},"
    echo "  \"outputs\": ["
    for i in "${!outputs[@]}"; do
      local suffix=""
      if [[ "${i}" -lt $((${#outputs[@]} - 1)) ]]; then
        suffix=","
      fi
      echo "    \"${outputs[$i]}\"${suffix}"
    done
    echo "  ]"
    echo "}"
  } > "${manifest_path}"
}

echo "Mode: ${MODE}"
echo "Godot: ${GODOT_LABEL} (${GODOT_SOURCE})"
echo "Project: ${ROOT}"
echo "Preset: ${PRESET}"
echo "Product: ${PRODUCT_NAME} ${PRODUCT_VERSION}"
echo "Version file: ${VERSION_VALUE}"
echo "Preset version: ${PRODUCT_VERSION}"
echo "Preset file_version: ${FILE_VERSION}"
echo "Output: ${OUTPUT_REL}"
echo "Embed PCK: ${EMBED_PCK}"
echo "PCK Output: ${PCK_REL}"
echo "Zip: ${ZIP_REL}"
echo "Zip (versioned): ${ZIP_VERSIONED_REL}"
echo "Manifest: ${MANIFEST_REL}"
echo "Zip Command: ${ZIP_COMMAND}"
echo "Command: ${COMMAND}"

HAS_MISMATCH=false
if [[ "${FILE_VERSION_MISMATCH}" == true ]]; then
  if [[ "${MODE}" == "dry-run" ]]; then
    echo "WARNING: preset file_version (${FILE_VERSION}) != preset product_version (${PRODUCT_VERSION})"
  else
    echo "ERROR: preset file_version (${FILE_VERSION}) != preset product_version (${PRODUCT_VERSION})" >&2
    HAS_MISMATCH=true
  fi
fi
if [[ "${VERSION_FILE_MISMATCH}" == true ]]; then
  if [[ "${MODE}" == "dry-run" ]]; then
    echo "WARNING: VERSION.txt (${VERSION_VALUE}) != preset file_version (${FILE_VERSION})"
  else
    echo "ERROR: VERSION.txt (${VERSION_VALUE}) != preset file_version (${FILE_VERSION})" >&2
    HAS_MISMATCH=true
  fi
fi
if [[ "${VERSION_MISMATCH}" == true ]]; then
  if [[ "${MODE}" == "dry-run" ]]; then
    echo "WARNING: VERSION.txt (${VERSION_VALUE}) != preset product_version (${PRODUCT_VERSION})"
  else
    echo "ERROR: VERSION.txt (${VERSION_VALUE}) != preset product_version (${PRODUCT_VERSION})" >&2
    HAS_MISMATCH=true
  fi
fi
if [[ "${HAS_MISMATCH}" == true && "${MODE}" != "dry-run" ]]; then
  exit 1
fi

if [[ "${MODE}" == "dry-run" ]]; then
  exit 0
fi

if [[ "${APPLY}" == true ]]; then
  if [[ "${GODOT_FOUND}" == false ]]; then
    echo "Godot not found: ${GODOT_RESOLVED}" >&2
    exit 1
  fi

  mkdir -p "$(dirname "${OUTPUT}")"
  "${GODOT_RESOLVED}" --headless --path "${ROOT}" --export-release "${PRESET}" "${OUTPUT_REL}"

  if [[ ! -f "${OUTPUT}" ]]; then
    echo "Export output missing: ${OUTPUT_REL}" >&2
    exit 1
  fi
  if [[ "${EMBED_PCK}" == "false" && ! -f "${PCK}" ]]; then
    echo "Export output missing: ${PCK_REL}" >&2
    exit 1
  fi

  echo "Exported: ${OUTPUT_REL}"
fi

if [[ "${PACKAGE}" == true ]]; then
  if [[ ! -f "${OUTPUT}" ]]; then
    echo "Export output missing: ${OUTPUT_REL}" >&2
    exit 1
  fi
  if [[ "${EMBED_PCK}" == "false" && ! -f "${PCK}" ]]; then
    echo "Export output missing: ${PCK_REL}" >&2
    exit 1
  fi

  if [[ "${ZIP_TOOL}" == "none" ]]; then
    echo "Zip tool not found (install zip or python3)." >&2
    exit 1
  fi

  manifest_outputs=("${OUTPUT_NAME}")
  if [[ "${EMBED_PCK}" == "false" ]]; then
    manifest_outputs+=("${PCK_NAME}")
  fi
  IFS=$'\n' manifest_outputs=($(printf '%s\n' "${manifest_outputs[@]}" | sort))
  unset IFS
  mkdir -p "${OUTPUT_DIR}"
  write_manifest "${MANIFEST}" "${manifest_outputs[@]}"

  mkdir -p "$(dirname "${ZIP_SELECTED}")"
  rm -f "${ZIP_SELECTED}"
  if [[ "${ZIP_TOOL}" == "zip" ]]; then
    (cd "${OUTPUT_DIR}" && zip -q "${ZIP_NAME}" "${ZIP_INPUTS[@]}")
  else
    (cd "${OUTPUT_DIR}" && python3 -m zipfile -c "${ZIP_NAME}" "${ZIP_INPUTS[@]}")
  fi

  echo "Packaged: ${ZIP_SELECTED_REL}"
fi
