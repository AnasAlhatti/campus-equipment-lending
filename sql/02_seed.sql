BEGIN;

INSERT INTO students (name, email) VALUES
    ('Deniz Kaya', 'deniz@example.org'),
    ('Ada Demir', 'ada@example.org'),
    ('Ece Yilmaz', 'ece@example.org');

INSERT INTO equipment (name, asset_tag) VALUES
    ('Mirrorless camera', 'CAM-01'),
    ('Tripod', 'TRI-01'),
    ('Wireless microphone', 'MIC-01'),
    ('LED light panel', 'LGT-01');

-- Two checkouts share each date so pagination exercises the ID tie-breaker.
WITH new_checkouts AS (
    INSERT INTO checkouts (student_id, checked_out_at, due_on)
    SELECT student_id,
           DATE '2026-10-01' + (day_number - 1),
           DATE '2026-10-08' + (day_number - 1)
    FROM generate_series(1, 11) AS days(day_number)
    CROSS JOIN students
    WHERE email IN ('deniz@example.org', 'ada@example.org')
    ORDER BY day_number, student_id
    RETURNING checkout_id, student_id
)
INSERT INTO checkout_items (checkout_id, equipment_id)
SELECT checkout_id, equipment_id
FROM new_checkouts
JOIN students USING (student_id)
JOIN equipment ON asset_tag = 'TRI-01'
    OR (email = 'deniz@example.org' AND asset_tag = 'CAM-01')
    OR (email = 'ada@example.org' AND asset_tag = 'MIC-01');

COMMIT;
