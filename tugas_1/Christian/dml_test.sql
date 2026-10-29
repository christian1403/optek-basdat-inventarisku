-- INSERT
BEGIN;
-- DROP INDEX idx_asset_history_id_asset;
EXPLAIN (ANALYZE, BUFFERS, WAL)
INSERT INTO asset_history (id_asset, tanggal, id_jenis, id_status, keluhan, tindakan, biaya)
SELECT 1 + floor(random() * (SELECT max(id) FROM asset))::int,
       current_date - (random() * 700)::int,
       1, 1,
       repeat('keluhan uji ', 5),
       repeat('tindakan uji ', 5),
       round((random() * 5000000)::numeric, 2)
FROM generate_series(1, 100000);
ROLLBACK;

BEGIN;
DROP INDEX idx_asset_history_id_asset;
EXPLAIN (ANALYZE, BUFFERS, WAL)
INSERT INTO asset_history (id_asset, tanggal, id_jenis, id_status, keluhan, tindakan, biaya)
SELECT 1 + floor(random() * (SELECT max(id) FROM asset))::int,
       current_date - (random() * 700)::int,
       1, 1,
       repeat('keluhan uji ', 5),
       repeat('tindakan uji ', 5),
       round((random() * 5000000)::numeric, 2)
FROM generate_series(1, 100000);
ROLLBACK;


-- UPDATE
BEGIN;
-- DROP INDEX idx_asset_history_id_asset;

EXPLAIN (ANALYZE, BUFFERS, WAL)
UPDATE asset_history
SET biaya = coalesce(biaya, 0) + 50000,
    update_at = now()
WHERE id_asset BETWEEN 1 AND 100000;

ROLLBACK;

BEGIN;
DROP INDEX idx_asset_history_id_asset;

EXPLAIN (ANALYZE, BUFFERS, WAL)
UPDATE asset_history
SET biaya = coalesce(biaya, 0) + 50000,
    update_at = now()
WHERE id_asset BETWEEN 1 AND 100000;

ROLLBACK;

-- DELETE
BEGIN;
-- DROP INDEX idx_asset_history_id_asset;

EXPLAIN (ANALYZE, BUFFERS, WAL)
DELETE FROM asset_history
WHERE id_asset BETWEEN 1 AND 100000;

ROLLBACK;

BEGIN;
DROP INDEX idx_asset_history_id_asset;

EXPLAIN (ANALYZE, BUFFERS, WAL)
DELETE FROM asset_history
WHERE id_asset BETWEEN 1 AND 100000;

ROLLBACK;