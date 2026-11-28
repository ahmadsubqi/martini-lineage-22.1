#!/usr/bin/env bash
set -uo pipefail

MANIFEST="${1:-.repo/local_manifests/martini.xml}"
REPORT="martini-dependency-audit.txt"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: manifest not found: $MANIFEST" >&2
  exit 2
fi

: > "$REPORT"
python3 - "$MANIFEST" <<'PY' > /tmp/martini-projects.tsv
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
remotes = {item.get("name"): item.get("fetch", "") for item in root.findall("remote")}
for project in root.findall("project"):
    remote = project.get("remote", "")
    fetch = remotes.get(remote, "")
    name = project.get("name", "")
    url = (fetch.rstrip("/") + "/" + name + ".git") if fetch else ""
    print("\\t".join([
        project.get("path", ""), url, project.get("revision", ""),
        remote, name
    ]))
PY

{
  echo "=== LUMIA 930 MARTINI DEPENDENCY AUDIT ==="
  echo "Manifest: $MANIFEST"
  echo "Audit UTC: $(date -u +%F\\ %T)"
  echo
  echo "=== PROJECT AND REVISION REACHABILITY ==="

  while IFS=$'\\t' read -r path url revision remote name; do
    [[ -n "$name" ]] || continue
    echo
    echo "PROJECT: $name"
    echo "  path=$path"
    echo "  remote=$remote"
    echo "  revision=$revision"
    echo "  url=$url"

    if [[ -z "$url" ]]; then
      echo "  RESULT=FAIL remote URL could not be resolved"
    elif git ls-remote --exit-code "$url" "refs/heads/$revision" >/tmp/martini-lsremote.txt 2>/dev/null; then
      echo "  RESULT=PASS branch exists"
      cat /tmp/martini-lsremote.txt
    elif git ls-remote --exit-code "$url" "refs/tags/$revision" >/tmp/martini-lsremote.txt 2>/dev/null; then
      echo "  RESULT=PASS tag exists"
      cat /tmp/martini-lsremote.txt
    else
      echo "  RESULT=FAIL revision missing or repository inaccessible"
    fi
  done < /tmp/martini-projects.tsv

  echo
  echo "=== ANDROID 15 READINESS GATE ==="
  if grep -Eq 'lineage-18\\.1|lineage-19\\.1|lineage-20\\.0|lineage-21\\.0' "$MANIFEST"; then
    echo "BLOCKER: manifest contains Android 11-14 era branch names."
    echo "This is a legacy reference manifest, not a LineageOS 22.1 manifest."
  else
    echo "No known LineageOS 18.1-21.0 branch labels detected."
    echo "This alone does not prove Android 15 compatibility."
  fi

  echo
  echo "LIMITATIONS"
  echo "- Checks Git repository/revision reachability only."
  echo "- Does not certify API, HAL, kernel, firmware, sepolicy or build compatibility."
  echo "- Does not sync the full Android source, build, flash or test hardware."
  echo
  echo "NEXT ACTION"
  echo "Prepare a separate Android 15 manifest using verified compatible projects."
} | tee "$REPORT"

# Fail the workflow when legacy refs or unreachable dependencies are found.
# The workflow's always() artifact step still uploads the report for inspection.
if grep -Eq 'RESULT=FAIL|BLOCKER:' "$REPORT"; then
  echo "Dependency audit is BLOCKED; inspect $REPORT."
  exit 1
fi
