-- ============================================================
-- INSERT
-- ============================================================

-- Pengujian INSERT dengan indeks tersedia
BEGIN;

EXPLAIN (ANALYZE, BUFFERS, WAL)
INSERT INTO asset_history (
    id_asset, tanggal, id_jenis, id_status,
    keluhan, tindakan, biaya
)
SELECT
    (SELECT id FROM asset ORDER BY random() LIMIT 1),
    CURRENT_DATE - (random() * 700)::int,
    1, 1,
    repeat('keluhan uji ', 5),
    repeat('tindakan uji ', 5),
    round((random() * 5000000)::numeric, 2)
FROM generate_series(1, 100000);

ROLLBACK;


-- Pengujian INSERT tanpa indeks
BEGIN;

DROP INDEX IF EXISTS idx_asset_history_asset;

EXPLAIN (ANALYZE, BUFFERS, WAL)
INSERT INTO asset_history (
    id_asset, tanggal, id_jenis, id_status,
    keluhan, tindakan, biaya
)
SELECT
    (SELECT id FROM asset ORDER BY random() LIMIT 1),
    CURRENT_DATE - (random() * 700)::int,
    1, 1,
    repeat('keluhan uji ', 5),
    repeat('tindakan uji ', 5),
    round((random() * 5000000)::numeric, 2)
FROM generate_series(1, 100000);

ROLLBACK;


-- ============================================================
-- UPDATE
-- ============================================================

-- Pengujian UPDATE dengan indeks tersedia
BEGIN;

EXPLAIN (ANALYZE, BUFFERS, WAL)
UPDATE asset
SET id_lokasi = id_lokasi
WHERE id BETWEEN 1 AND 10000;

ROLLBACK;


-- Pengujian UPDATE tanpa indeks
BEGIN;

DROP INDEX IF EXISTS idx_asset_filter_laporan;

EXPLAIN (ANALYZE, BUFFERS, WAL)
UPDATE asset
SET id_lokasi = id_lokasi
WHERE id BETWEEN 1 AND 10000;

ROLLBACK;


-- ============================================================
-- DELETE
-- ============================================================

-- Pengujian DELETE dengan indeks tersedia
BEGIN;

EXPLAIN (ANALYZE, BUFFERS, WAL)
DELETE FROM asset
WHERE id BETWEEN 1 AND 100;

ROLLBACK;


-- Pengujian DELETE tanpa indeks
BEGIN;

DROP INDEX IF EXISTS idx_asset_filter_laporan;

EXPLAIN (ANALYZE, BUFFERS, WAL)
DELETE FROM asset
WHERE id BETWEEN 1 AND 100;

ROLLBACK;