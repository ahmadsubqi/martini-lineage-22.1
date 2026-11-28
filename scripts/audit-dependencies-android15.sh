#!/usr/bin/env bash
set -uo pipefail
MANIFEST="${1:-.repo/local_manifests/martini.xml}"
REPORT="martini-dependency-audit.txt"
if [[ ! -f "$MANIFEST" ]]; then echo "ERROR: manifest not found: $MANIFEST" >&2; exit 2; fi
: > "$REPORT"
{
  echo "=== LUMIA 930 MARTINI DEPENDENCY AUDIT ==="
  echo "Manifest: $MANIFEST"
  echo "Audit UTC: $(date -u +%F\ %T)"
  echo
  echo "=== MANIFEST PROJECTS AND REMOTE REACHABILITY ==="
  python3 - "$MANIFEST" <<'PY' > /tmp/martini-projects.tsv
import sys, xml.etree.ElementTree as ET
root=ET.parse(sys.argv[1]).getroot()
remotes={x.get("name"):x.get("fetch","") for x in root.findall("remote")}
for p in root.findall("project"):
    remote=p.get("remote","")
    fetch=remotes.get(remote,"")
    name=p.get("name","")
    url=(fetch.rstrip("/")+"/"+name+".git") if fetch else ""
    print("\t".join([p.get("path",""),url,p.get("revision",""),remote,name]))
PY
  while IFS=$'\t' read -r path url revision remote name; do
    [[ -n "$name" ]] || continue
    echo
    echo "PROJECT: $name"
    echo "  path=$path"
    echo "  remote=$remote"
    echo "  revision=$revision"
    echo "  url=$url"
    if [[ -z "$url" ]]; then
      echo "  RESULT=ERROR remote URL could not be resolved"
      continue
    fi
    if git ls-remote --exit-code "$url" "refs/heads/$revision" >/tmp/martini-lsremote.txt 2>/dev/null; then
      echo "  RESULT=PASS branch exists"
      cat /tmp/martini-lsremote.txt
    elif git ls-remote --exit-code "$url" "refs/tags/$revision" >/tmp/martini-lsremote.txt 2>/dev/null; then
      echo "  RESULT=PASS tag exists"
      cat /tmp/martini-lsremote.txt
    else
      echo "  RESULT=FAIL revision not found or repository inaccessible"
    fi
  done < /tmp/martini-projects.tsv
  echo
  echo "=== ANDROID 15 READINESS CHECK ==="
  if grep -q 'lineage-18\.1' "$MANIFEST"; then
    echo "BLOCKER: manifest contains lineage-18.1 revisions. These are legacy references, not a LineageOS 22.1 manifest."
  fi
  echo "NOTE: this audit checks repository/revision reachability only; it does not certify API, HAL, kernel, firmware or build compatibility."
  echo "NOTE: no source sync, ROM build, flash or hardware test was performed."
  echo
  echo "=== NEXT ACTION ==="
  echo "Resolve all missing revisions, then create a separate Android 15 manifest with verified LineageOS 22.1-compatible projects."
} | tee "$REPORT"
