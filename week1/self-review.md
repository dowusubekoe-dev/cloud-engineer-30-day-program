# Week 1 self-review

Half a page, written 2026-11-25 from the verified session record.

**Strongest day: Day 6, the Terraform rebuild.** I tore down a stack I
had built by hand across four days and rebuilt all of it from code:
39 resources, one apply, verified end to end, including restoring the
database from a snapshot. That is the day the week stopped being console
practice and became engineering: the design survived being written down
precisely enough for a machine to reproduce it.

**Weakest day: Day 5, the security day.** The work itself was real:
GuardDuty sample incidents analyzed, Config findings separated into the
lab's deliberate violation, one real exposure in my own agency project,
and noise, and the remediation verified. But the day's screenshot
evidence was never captured as files: the tooling could photograph the
console pages and still not save them, and I let the day close with the
evidence living in notes instead of images. The lesson is to check the
evidence path before the session, not after it.

**The question I could not answer:** why the management account's
CloudTrail trails list is empty when event history clearly works, and
whether an organization trail exists somewhere I have not looked. I
documented around it on Day 5 instead of tracing it. It is still open,
and it matters, because "the audit log exists" is a claim I should be
able to point at, not assume.
