#!/usr/bin/env python3
"""Day 7: Security Hub scores from findings (CLI view).
Per control (from ACTIVE Security Hub findings): FAILED if any finding
FAILED, else PASSED if any PASSED, else OTHER. Per standard: intersect
the standard's ENABLED control ids (describe-standards-controls) with
finding verdicts. Standards whose control ids use a legacy scheme
(CIS v1.2.0: CIS.x.y) will not match consolidated finding ids; that is
reported, not hidden.
"""
import json, subprocess, sys

PROFILE = ["--profile", "lab", "--region", "us-east-1"]

def aws(*args):
    out = subprocess.run(["aws", "securityhub", *args, *PROFILE, "--output", "json"],
                         capture_output=True, text=True)
    if out.returncode != 0:
        print("AWS ERROR:", out.stderr.strip()[:300]); sys.exit(1)
    return json.loads(out.stdout)

filt = json.dumps({"RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}],
                   "ProductName": [{"Value": "Security Hub", "Comparison": "EQUALS"}]})
per_control, token, total = {}, None, 0
while True:
    args = ["get-findings", "--max-results", "100", "--filters", filt]
    if token: args += ["--next-token", token]
    page = aws(*args)
    for f in page.get("Findings", []):
        total += 1
        gen = f.get("GeneratorId", "")
        if not gen.startswith("security-control/"): continue
        cid = gen.split("/", 1)[1]
        per_control.setdefault(cid, set()).add(f.get("Compliance", {}).get("Status"))
    token = page.get("NextToken")
    if not token: break

def verdict(s):
    if "FAILED" in s: return "FAILED"
    if "PASSED" in s: return "PASSED"
    return "OTHER"
verdicts = {cid: verdict(s) for cid, s in per_control.items()}
print(f"active findings scanned: {total}; distinct controls with findings: {len(verdicts)}")

def report(label, cids):
    p = sum(1 for c in cids if verdicts.get(c) == "PASSED")
    f_ = sum(1 for c in cids if verdicts.get(c) == "FAILED")
    o = sum(1 for c in cids if verdicts.get(c) == "OTHER")
    d = p + f_
    if d:
        print(f"{label}: PASSED {p} / FAILED {f_} / OTHER {o} -> score {100.0*p/d:.0f}% (of {d} evaluated)")
    else:
        print(f"{label}: no evaluated controls matched")

report("OVERALL (each control once)", list(verdicts.keys()))

subs = aws("get-enabled-standards")["StandardsSubscriptions"]
for s in subs:
    sarn = s["StandardsArn"]
    label = sarn.split("/")[-2] + " v" + sarn.split("/")[-1]
    controls, token = set(), None
    while True:
        args = ["describe-standards-controls", "--standards-subscription-arn",
                s["StandardsSubscriptionArn"], "--max-results", "100"]
        if token: args += ["--next-token", token]
        page = aws(*args)
        for c in page.get("Controls", []):
            if c.get("ControlStatus") == "ENABLED":
                controls.add(c["ControlId"])
        token = page.get("NextToken")
        if not token: break
    matched = [c for c in controls if c in verdicts]
    print(f"standard {label}: {len(controls)} enabled controls, {len(matched)} match finding ids")
    report("  " + label, matched)
