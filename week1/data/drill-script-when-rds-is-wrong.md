# Drill script: "When is RDS the wrong choice?"
Read it out loud as written. About 2.5 minutes at a calm pace.
Pause where you see a line break. Do not rush the opening.

---

"RDS is my default for relational data, and I reach for it first. But
there are three cases where I would argue against it in a design review.

First, unstructured data at scale. If the data is documents, images,
event logs, or anything without a stable schema, it does not belong in
a relational table. It belongs in S3, where storage is cheap and
effectively unlimited, queried with Athena when it is analytical, or
held in DynamoDB when the access pattern is simple key lookups. Forcing
unstructured data into RDS buys you expensive storage and slow queries.

Second, extreme write throughput. A single relational primary has a
ceiling: every write goes through one writer, with indexes and
constraints checked on the way in. If the workload is hundreds of
thousands of writes per second, telemetry, clickstream, IoT ingestion,
no vertical resize saves you. That is DynamoDB on-demand territory, or
a distributed store built for it, where writes shard across nodes by
design.

Third, global active-active. RDS replication is built around one
primary in one region. Read replicas in other regions help reads, but
writes still cross the world to one place, and multi-master options
come with real conflict and consistency limits. If users on three
continents all need to write with local latency, I would pick DynamoDB
Global Tables, or a distributed SQL database designed for it, and I
would say plainly what consistency I am giving up to get it.

The pattern in all three: RDS is the wrong choice when the data is not
really relational, when one writer cannot keep up, or when one region
cannot be home. If none of those is true, and the data has
relationships, transactions, and joins, RDS is usually the most boring
and correct answer I can give."

---

## After you record
- Save the recording next to this file and note the date.
- Listen once. Mark one sentence you stumbled on and one you liked.
- Re-record once if you want; two takes is the drill, not ten.
