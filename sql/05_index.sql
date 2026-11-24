-- Keep the synthetic benchmark rows and test index out of the demo data.
BEGIN;

INSERT INTO students (name, email)
SELECT 'Benchmark student ' || n, 'benchmark-' || n || '@example.org'
FROM generate_series(1, 1000) AS ids(n);

INSERT INTO checkouts (student_id, checked_out_at, due_on)
SELECT student_id, DATE '2025-01-01' + day_number, DATE '2025-01-08' + day_number
FROM generate_series(1, 100) AS days(day_number)
CROSS JOIN students
WHERE email LIKE 'benchmark-%@example.org';

ANALYZE students;
ANALYZE checkouts;

SELECT count(*) AS checkouts_in_benchmark FROM checkouts;

EXPLAIN (ANALYZE, BUFFERS)
SELECT checkout_id, checked_out_at, due_on
FROM checkouts
WHERE student_id = (SELECT student_id FROM students WHERE email = 'benchmark-42@example.org')
ORDER BY checked_out_at DESC, checkout_id DESC
LIMIT 10;

CREATE INDEX checkouts_student_history_idx
ON checkouts (student_id, checked_out_at DESC, checkout_id DESC);

EXPLAIN (ANALYZE, BUFFERS)
SELECT checkout_id, checked_out_at, due_on
FROM checkouts
WHERE student_id = (SELECT student_id FROM students WHERE email = 'benchmark-42@example.org')
ORDER BY checked_out_at DESC, checkout_id DESC
LIMIT 10;

ROLLBACK;
