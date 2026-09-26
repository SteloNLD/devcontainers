#!/usr/bin/env bash
# Reports whether the base image's Fedora is behind, or nearing end of life.
#
# Renovate cannot do this. quay.io/fedora/fedora publishes numeric tags for
# unreleased versions -- with 44 stable it offered 46, which is rawhide -- and the
# docker datasource simply takes the highest tag. endoflife.date carries the real
# release and EOL dates, which is the signal the registry does not expose.
#
# Emits GITHUB_OUTPUT-style keys and exits 0 whatever it finds; what to do about
# the result is the caller's decision.
set -euo pipefail

CONTAINERFILE="${1:-templates/iac-spec/.devcontainer/Containerfile}"
EOL_WARN_DAYS="${EOL_WARN_DAYS:-90}"

CURRENT=$(grep -oE '^FROM quay\.io/fedora/fedora:[0-9]+' "$CONTAINERFILE" | grep -oE '[0-9]+$' || true)
[ -n "$CURRENT" ] || { echo "Could not find a Fedora tag in $CONTAINERFILE" >&2; exit 1; }

# Passed through the environment, and the script below is a quoted heredoc, so
# the shell does not touch either one.
FEDORA_JSON="$(curl -fsSL --retry 3 https://endoflife.date/api/fedora.json)" \
CURRENT="$CURRENT" EOL_WARN_DAYS="$EOL_WARN_DAYS" \
python3 <<'PY'
import json, os, datetime

data = json.loads(os.environ["FEDORA_JSON"])
cur = int(os.environ["CURRENT"])
warn_days = int(os.environ["EOL_WARN_DAYS"])
today = datetime.date.today()

def as_date(value):
    try:
        return datetime.date.fromisoformat(value)
    except Exception:
        return None

# A cycle counts as available only once its release date has passed. Anything
# newer is branched or rawhide, however high its tag number looks.
released = [r for r in data if as_date(r.get("releaseDate") or "") and as_date(r["releaseDate"]) <= today]
newest = max((int(r["cycle"]) for r in released), default=cur)
ga_date = next((r["releaseDate"] for r in released if int(r["cycle"]) == newest), "unknown")
eol_raw = next((r.get("eol") for r in data if int(r["cycle"]) == cur), None)
eol = as_date(eol_raw or "")

reasons = []
if newest > cur:
    reasons.append(f"Fedora {newest} has been generally available since {ga_date}; the base image is still on {cur}.")
if eol:
    left = (eol - today).days
    if left < 0:
        reasons.append(f"Fedora {cur} reached end of life on {eol} ({-left} days ago).")
    elif left <= warn_days:
        reasons.append(f"Fedora {cur} reaches end of life on {eol}, in {left} days.")

print(f"current={cur}")
print(f"newest_ga={newest}")
print(f"ga_date={ga_date}")
print(f"eol={eol_raw or 'unknown'}")
print("action=" + ("true" if reasons else "false"))
print("summary<<SUMMARY_EOF")
print("\n".join(f"- {r}" for r in reasons) if reasons
      else f"- Fedora {cur} is the newest released version; end of life {eol_raw or 'unknown'}.")
print("SUMMARY_EOF")
PY
