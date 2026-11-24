-- Create.
INSERT INTO equipment (name, asset_tag)
VALUES ('Handheld recorder', 'DEMO-01')
RETURNING asset_tag, name;

-- Read.
SELECT asset_tag, name FROM equipment WHERE asset_tag = 'DEMO-01';

-- Update.
UPDATE equipment
SET name = 'Portable audio recorder'
WHERE asset_tag = 'DEMO-01'
RETURNING asset_tag, name;

-- Delete, then verify the row is gone.
DELETE FROM equipment WHERE asset_tag = 'DEMO-01'
RETURNING asset_tag, name;

SELECT count(*) AS remaining_demo_rows
FROM equipment
WHERE asset_tag = 'DEMO-01';

-- Join all four tables for the most recent day's checkouts.
SELECT c.checkout_id, s.name AS student, c.checked_out_at, e.name AS equipment
FROM checkouts AS c
JOIN students AS s USING (student_id)
JOIN checkout_items AS ci USING (checkout_id)
JOIN equipment AS e USING (equipment_id)
WHERE c.checked_out_at = (SELECT max(checked_out_at) FROM checkouts)
ORDER BY c.checkout_id, e.asset_tag;

-- Include equipment with zero loans.
SELECT e.asset_tag, e.name, count(ci.checkout_id) AS times_borrowed
FROM equipment AS e
LEFT JOIN checkout_items AS ci USING (equipment_id)
GROUP BY e.equipment_id, e.asset_tag, e.name
ORDER BY times_borrowed DESC, e.asset_tag;

-- Page one.
SELECT checkout_id, checked_out_at, due_on
FROM checkouts
ORDER BY checked_out_at DESC, checkout_id DESC
LIMIT 10 OFFSET 0;

-- Page two.
SELECT checkout_id, checked_out_at, due_on
FROM checkouts
ORDER BY checked_out_at DESC, checkout_id DESC
LIMIT 10 OFFSET 10;
