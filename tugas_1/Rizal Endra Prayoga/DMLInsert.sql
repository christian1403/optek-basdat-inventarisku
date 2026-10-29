ROLLBACK;

BEGIN;

EXPLAIN (ANALYZE, BUFFERS, WAL)
INSERT INTO public.asset_history
    (id_asset, tanggal, id_jenis, id_status, biaya)
SELECT
    id_asset,
    tanggal,
    id_jenis,
    id_status,
    biaya
FROM public.asset_history
ORDER BY id
LIMIT 1000;

ROLLBACK;