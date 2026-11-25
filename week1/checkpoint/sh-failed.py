#!/usr/bin/env python3
"""Day 7 helper: which Security Hub controls fail, and on how many resources."""
import json, subprocess, collections
PROFILE = ["--profile", "lab", "--region", "us-east-1"]
def aws(*args):
    out = subprocess.run(["aws", "securityhub", *args, *PROFILE, "--output", "json"],
                         capture_output=True, text=True)
    return json.loads(out.stdout)
filt = json.dumps({"RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}],
                   "ProductName": [{"Value": "Security Hub", "Comparison": "EQUALS"}],
                   "ComplianceStatus": [{"Value": "FAILED", "Comparison": "EQUALS"}]})
counts, titles, token = collections.Counter(), {}, None
while True:
    args = ["get-findings", "--max-results", "100", "--filters", filt]
    if token: args += ["--next-token", token]
    page = aws(*args)
    for f in page.get("Findings", []):
        gen = f.get("GeneratorId", "")
        if not gen.startswith("security-control/"): continue
        cid = gen.split("/", 1)[1]
        counts[cid] += 1
        titles.setdefault(cid, f.get("Title", ""))
    token = page.get("NextToken")
    if not token: break
print(f"distinct FAILED controls: {len(counts)}; total FAILED findings: {sum(counts.values())}")
for cid, n in counts.most_common(15):
    print(f"{n:3d}  {cid:22s} {titles[cid][:80]}")
