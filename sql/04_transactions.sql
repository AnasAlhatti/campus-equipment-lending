BEGIN;

WITH new_checkout AS (
    INSERT INTO checkouts (student_id, checked_out_at, due_on)
    SELECT student_id, DATE '2026-11-01', DATE '2026-11-08'
    FROM students WHERE email = 'ece@example.org'
    RETURNING checkout_id
)
INSERT INTO checkout_items (checkout_id, equipment_id)
SELECT checkout_id, equipment_id
FROM new_checkout CROSS JOIN equipment
WHERE asset_tag IN ('CAM-01', 'TRI-01');

COMMIT;

SELECT count(DISTINCT c.checkout_id) AS committed_checkouts,
       count(ci.equipment_id) AS committed_items
FROM checkouts AS c
JOIN students AS s USING (student_id)
LEFT JOIN checkout_items AS ci USING (checkout_id)
WHERE s.email = 'ece@example.org' AND c.checked_out_at = DATE '2026-11-01';

BEGIN;

WITH new_checkout AS (
    INSERT INTO checkouts (student_id, checked_out_at, due_on)
    SELECT student_id, DATE '2026-11-02', DATE '2026-11-09'
    FROM students WHERE email = 'ece@example.org'
    RETURNING checkout_id
)
INSERT INTO checkout_items (checkout_id, equipment_id)
SELECT checkout_id, equipment_id
FROM new_checkout CROSS JOIN equipment
WHERE asset_tag = 'CAM-01';

-- Catch the expected duplicate-key error so the script can issue ROLLBACK.
DO $$
DECLARE
    violated_constraint text;
BEGIN
    INSERT INTO checkout_items (checkout_id, equipment_id)
    SELECT c.checkout_id, e.equipment_id
    FROM checkouts AS c
    JOIN students AS s USING (student_id)
    CROSS JOIN equipment AS e
    WHERE s.email = 'ece@example.org'
        AND c.checked_out_at = DATE '2026-11-02'
        AND e.asset_tag = 'CAM-01';

    RAISE EXCEPTION 'Expected the duplicate checkout item to be rejected';
EXCEPTION WHEN unique_violation THEN
    GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
    IF violated_constraint <> 'checkout_items_pkey' THEN
        RAISE;
    END IF;
    RAISE NOTICE 'Duplicate checkout item rejected by %', violated_constraint;
END;
$$;

SELECT count(ci.equipment_id) AS items_before_rollback
FROM checkouts AS c
JOIN students AS s USING (student_id)
JOIN checkout_items AS ci USING (checkout_id)
WHERE s.email = 'ece@example.org' AND c.checked_out_at = DATE '2026-11-02';

ROLLBACK;

SELECT count(*) AS checkouts_after_rollback
FROM checkouts AS c
JOIN students AS s USING (student_id)
WHERE s.email = 'ece@example.org' AND c.checked_out_at = DATE '2026-11-02';
