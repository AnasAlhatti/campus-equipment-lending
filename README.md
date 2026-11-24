# Campus Equipment Lending

A PostgreSQL homework project for a campus media lab. A student can make multiple checkouts, and a checkout can contain several pieces of equipment.

## Schema

| Table | Primary key | Foreign keys | Other constraints |
| --- | --- | --- | --- |
| `students` | `student_id` | | Unique, required email and a required, nonblank name |
| `equipment` | `equipment_id` | | Unique, required asset tag and a required, nonblank name |
| `checkouts` | `checkout_id` | `student_id → students` | Both dates are required. The due date must be on or after the checkout date. |
| `checkout_items` | `(checkout_id, equipment_id)` | `checkout_id → checkouts` and `equipment_id → equipment` | Each asset appears at most once per checkout. Deleting a checkout deletes its item links. |

## Run the homework

With PostgreSQL running and `createdb` and `psql` available, run these commands from the repo. Use a fresh database for each full run.

```sh
createdb campus_equipment_lending
psql -X -v ON_ERROR_STOP=1 -d campus_equipment_lending -f sql/01_schema.sql -f sql/02_seed.sql -f sql/03_queries.sql -f sql/04_transactions.sql -f sql/05_index.sql
```

## Verified results

The five SQL scripts were executed in PostgreSQL 19.0 via PGlite 0.6.0.

| Demo | Observed result |
| --- | --- |
| Seed data | 3 students, 4 assets, 22 checkouts, and 44 checkout item links |
| Constraints | PostgreSQL rejected duplicate email and asset tag values, a missing equipment name, an invalid due date, and two invalid foreign key references. |
| CRUD | `DEMO-01` was inserted and read as **Handheld recorder**, updated to **Portable audio recorder**, and deleted. The final lookup counted 0 rows. |
| JOIN | The four-table join returned 4 item rows across the 2 most recent checkouts. Deniz borrowed the camera and tripod. Ada borrowed the microphone and tripod. |
| GROUP BY | Tripod 22, camera 11, microphone 11, and light panel 0 |
| Pagination | Page 1 returned IDs 22 through 13. Page 2 returned IDs 12 through 3. Each page had 10 rows and the pages had no overlap. |
| COMMIT | 1 checkout and its 2 item links persisted. |
| ROLLBACK | PostgreSQL rejected the duplicate item. There was 1 valid link before rollback and 0 matching checkouts afterward. The total item link count stayed at 46, including the earlier committed links. |

## Index evaluation

The benchmark adds 100,000 synthetic checkouts, refreshes planner statistics with `ANALYZE`, and runs the same `EXPLAIN (ANALYZE, BUFFERS)` twice. The query fetches the 10 newest checkouts for one student on a table containing 100,023 checkouts.

| | Plan on `checkouts` | Rows returned | Execution time |
| --- | --- | ---: | ---: |
| Before | Sequential scan and top-N sort | 10 | 11.398 ms |
| After | Scan using `checkouts_student_history_idx` | 10 | 0.094 ms |

The sequential scan discarded 99,923 rows. The composite B-tree index lets PostgreSQL find the student's entries in the requested date and ID order and stop after 10 rows without a separate sort. These times are from a single local run and vary with hardware, cache state, and PostgreSQL version. The script rolls back the benchmark rows and the test index after printing both plans. [PostgreSQL documentation on EXPLAIN](https://www.postgresql.org/docs/18/sql-explain.html) · [Multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html)

## AI usage

The homework prompt asked Codex to propose a project with 2–4 related tables, define keys and constraints, generate SQL schema and sample data, verify CRUD, JOIN, GROUP BY and pagination, demonstrate COMMIT and ROLLBACK, and evaluate one index with EXPLAIN ANALYZE. Anas chose the Campus Equipment Lending proposal. Codex generated the SQL files and the synthetic data, executed the scripts, and checked the results against expected row counts, SQLSTATE codes, and execution plan nodes.
