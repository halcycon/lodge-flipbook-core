#!/usr/bin/env bash
set -euo pipefail

# ------------------------ helpers ------------------------

json_escape() {
  # escape backslashes and quotes for JSON string values
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

pretty_title() {
  # turn "Some_File-Name.pdf" -> "Some File Name"
  local s="${1%.pdf}"
  s="${s//_/ }"
  s="${s//-/ }"
  printf '%s' "$s"
}

write_gallery() {
  # $1=dir (e.g. summons | minutes | other | guides/1 | guides/inst)
  local dir="$1"
  local out="${dir}/gallery.json"

  if ! compgen -G "${dir}/*.pdf" > /dev/null; then
    mkdir -p "$(dirname "$out")"
    echo "[] " > "$out"
    echo "Wrote empty $out"
    return
  fi

  # Collect files; sort newest->oldest by filename (works when numbers are 0-padded)
  mapfile -t files < <(ls -1 "${dir}"/*.pdf 2>/dev/null | sort -r)

  mkdir -p "$(dirname "$out")"
  {
    echo "["
    local first=1
    for f in "${files[@]}"; do
      local base="$(basename "$f")"
      local path="/${dir}/${base}"
      local title=""
      case "$dir" in
        summons)
          if [[ "$base" =~ ^L5749-Summons-([0-9]{4})\.pdf$ ]]; then
            title="Summons #${BASH_REMATCH[1]#0}"
          else
            title="$(pretty_title "$base")"
          fi
          ;;
        minutes)
          if [[ "$base" =~ ^L5749-Minutes-([0-9]{4})\.pdf$ ]]; then
            title="Minutes #${BASH_REMATCH[1]#0}"
          else
            title="$(pretty_title "$base")"
          fi
          ;;
        *)
          title="$(pretty_title "$base")"
          ;;
      esac

      [[ $first -eq 1 ]] || echo ","
      first=0
      printf '  {"path":"%s","title":"%s"}' \
        "$(json_escape "$path")" \
        "$(json_escape "$title")"
    done
    echo
    echo "]"
  } > "$out"

  echo "Wrote $out with ${#files[@]} items"
}

# --------------------- current.json ----------------------

echo "==> Generating current.json"

latest_num="$(
  ls -1 summons/L5749-Summons-*.pdf 2>/dev/null \
    | sed -E 's#.*/L5749-Summons-([0-9]{4})\.pdf#\1#' \
    | sort -n | tail -n1
)"

if [[ -z "${latest_num:-}" ]]; then
  echo '{"meeting":null,"summons":null,"minutes":null,"appendices":[]}' > current.json
  echo "No summons found; wrote empty current.json"
else
  meeting="${latest_num#0}"
  summons_path="/summons/L5749-Summons-${latest_num}.pdf"

  prev_num=$(printf "%04d" $((10#$latest_num - 1)))
  minutes_path=""
  if [[ -f "minutes/L5749-Minutes-${prev_num}.pdf" ]]; then
    minutes_path="/minutes/L5749-Minutes-${prev_num}.pdf"
  fi

  # Appendices /appendices/NNNN-*.pdf
  appendices_json="[]"
  if compgen -G "appendices/${latest_num}-*.pdf" > /dev/null; then
    first=1
    appendices_json="["
    for f in appendices/${latest_num}-*.pdf; do
      [[ -f "$f" ]] || continue
      base="$(basename "$f")"
      title="${base#${latest_num}-}"
      title="${title%.pdf}"
      path="/${f}"
      item="{\"path\":\"$(json_escape "$path")\",\"title\":\"$(json_escape "$title")\"}"
      if [[ $first -eq 1 ]]; then
        appendices_json="${appendices_json}${item}"
        first=0
      else
        appendices_json="${appendices_json},${item}"
      fi
    done
    appendices_json="${appendices_json}]"
  fi

  if [[ -n "$minutes_path" ]]; then
    minutes_json="\"$minutes_path\""
  else
    minutes_json="null"
  fi

  cat > current.json <<EOF
{
  "meeting": ${meeting},
  "summons": "${summons_path}",
  "minutes": ${minutes_json},
  "appendices": ${appendices_json}
}
EOF
  echo "Wrote current.json for meeting ${meeting}"
fi

# ------------------- galleries --------------------------

write_gallery "summons"
write_gallery "minutes"
write_gallery "appendices"
write_gallery "other"

# Guides sections (public page; PDFs gated by degree in the Worker)
write_gallery "guides/1"
write_gallery "guides/2"
write_gallery "guides/3"
write_gallery "guides/inst"

# At the end of build.sh
if [[ -n "${CF_PAGES_COMMIT_SHA:-}" ]]; then
  built_at_iso="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  built_at_epoch="$(date -u +%s)"
  printf '{"commit":"%s","builtAt":"%s","builtAtEpoch":%s}\n' \
    "$CF_PAGES_COMMIT_SHA" "$built_at_iso" "$built_at_epoch" > version.json
else
  built_at_iso="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  built_at_epoch="$(date -u +%s)"
  printf '{"commit":"dev","builtAt":"%s","builtAtEpoch":%s}\n' \
    "$built_at_iso" "$built_at_epoch" > version.json
fi

echo "Build script finished."

# ------------------- optional cache warm-up -------------------
# If you want to warm Cloudflare edge caches after deployment, set:
#   WARM_ORIGIN=https://your-domain.example
#   WARM_TOKEN=<secret matching env.WARM_TOKEN in the worker>
# This step will POST to /__warm and is safe to run multiple times.
warm_cache() {
  local origin="${WARM_ORIGIN:-}"
  local token="${WARM_TOKEN:-}"
  # Fallback to CF_PAGES_URL when origin not provided (useful for previews)
  if [[ -z "$origin" && -n "${CF_PAGES_URL:-}" ]]; then
    origin="$CF_PAGES_URL"
  fi
  if [[ -z "$origin" || -z "$token" ]]; then
    echo "Warm: skipped (WARM_ORIGIN/WARM_TOKEN not set)"
    return 0
  fi

  local url="$origin/__warm"
  local tries=12
  local wait=5
  local code=""
  # If running inside Cloudflare Pages build, skip explicit warm — site isn't live yet.
  if [[ -n "${CF_PAGES:-}" || -n "${CF_PAGES_URL:-}" ]]; then
    echo "Warm: skipped during Pages build (worker not yet active). Background warm will run on first traffic."
    return 0
  fi

  echo "Warm: attempting to populate edge cache via $url"
  for i in $(seq 1 $tries); do
    echo "Warm: attempt $i/$tries"
  code=$(curl -sS -o /tmp/l5749-warm.json -w '%{http_code}' -X POST -H "Authorization: Bearer $token" "$url" || true)
    if [[ "$code" == "200" ]]; then
      echo "Warm: success — response: $(cat /tmp/l5749-warm.json)"
      rm -f /tmp/l5749-warm.json
      return 0
    fi
    echo "Warm: not ready (HTTP $code). Retrying in ${wait}s..."
    sleep "$wait"
  done
  echo "Warm: failed after $tries attempts (last HTTP $code)"
  if [[ -f /tmp/l5749-warm.json ]]; then
    echo "Warm: last body:"; cat /tmp/l5749-warm.json
    rm -f /tmp/l5749-warm.json
  fi
  # Do not fail the build if warm-up fails
  return 0
}

warm_cache