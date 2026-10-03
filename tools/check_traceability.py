#!/usr/bin/env python3
"""Fail when requirements, test plan and tests stop naming each other.

    check_traceability.py <requirements.md> <test plan.md> <test file or dir>...

Requirements are defined where a line starts with the ID (`R-1.2 ...`, `| R-1.2 |`,
`### R-1`). Plan rows are table rows starting with a plan ID; the row's R-IDs are
what it covers and its last cell is the status: `implemented`, `planned`, or
`manual`. Tests carry `Plan: T-3. Covers: R-1.2, R-1.3.` in a comment or docstring.

Checks, each reported with the IDs involved:
  1. every requirement is covered by at least one plan row (a group by any sub-item);
  2. every plan row names only requirements that exist;
  3. every `implemented` row is claimed by a test with exactly that row's R-IDs;
  4. every test tag names a plan row that exists and is `implemented`.
Exit 0 when all hold, 1 otherwise. Adjust the patterns below to the project's IDs.
"""
import pathlib
import re
import sys

REQ = r"R-\d+(?:\.\d+)*[a-z]?"
PLAN = r"T-\d+"
DEFINED = re.compile(rf"^(?:\|\s*|#+\s*|\*\*)?({REQ})\b", re.M)
ROW = re.compile(rf"^\|\s*({PLAN})\s*\|(.*)\|\s*$", re.M)
TAG = re.compile(rf"Plan:\s*({PLAN})\.\s*Covers:\s*([^\n]*?)\.?\s*(?:\"\"\"|\*/|$)", re.M)
SUFFIXES = {".py", ".m", ".cpp", ".cc", ".hpp", ".h", ".c", ".rs", ".go", ".ts", ".js", ".java", ".sh", ".swift"}


def ids(text):
    return set(re.findall(REQ, text))


def main(req_path, plan_path, *test_paths):
    known = set(DEFINED.findall(pathlib.Path(req_path).read_text(encoding="utf-8")))
    rows = {}
    for row, body in ROW.findall(pathlib.Path(plan_path).read_text(encoding="utf-8")):
        status = body.rsplit("|", 1)[-1].strip().lower()
        rows[row] = (ids(body), status)

    files = []
    for p in map(pathlib.Path, test_paths):
        files += [f for f in p.rglob("*") if f.suffix in SUFFIXES] if p.is_dir() else [p]
    claims = {}
    for f in files:
        for row, cover in TAG.findall(f.read_text(encoding="utf-8", errors="replace")):
            claims.setdefault(row, []).append((f"{f}", ids(cover)))

    errors = []
    covered = set().union(*(r for r, _ in rows.values())) if rows else set()
    # A group heading (`### R-1`) is covered through any of its sub-items (R-1.1, ...).
    covered |= {k for k in known if any(c.startswith(k + ".") for c in covered)}
    if missing := sorted(known - covered):
        errors.append(f"requirements with no plan row: {', '.join(missing)}")
    for row, (reqs, status) in sorted(rows.items()):
        if unknown := sorted(reqs - known):
            errors.append(f"{row} names requirements that do not exist: {', '.join(unknown)}")
        if status == "implemented":
            if row not in claims:
                errors.append(f"{row} is implemented but no test carries `Plan: {row}.`")
            for where, got in claims.get(row, []):
                if got != reqs:
                    errors.append(f"{row}: plan covers {sorted(reqs)}, {where} says {sorted(got)}")
    for row, found in sorted(claims.items()):
        if row not in rows:
            errors.append(f"{', '.join(w for w, _ in found)} claims {row}, which the plan lacks")
        elif rows[row][1] != "implemented":
            errors.append(f"{row} has a test but is marked {rows[row][1]!r}, not implemented")

    for e in errors:
        print(f"traceability: {e}", file=sys.stderr)
    print(f"traceability: {len(known)} requirements, {len(rows)} plan rows, "
          f"{sum(map(len, claims.values()))} tagged tests, {len(errors)} problems")
    return 1 if errors else 0


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    sys.exit(main(*sys.argv[1:]))
