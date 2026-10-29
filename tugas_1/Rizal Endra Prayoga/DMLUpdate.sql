ROLLBACK;

BEGIN;

EXPLAIN (ANALYZE, BUFFERS, WAL)
UPDATE public.asset_history
SET tanggal = tanggal + INTERVAL '1 day'
WHERE id IN (
    SELECT id
    FROM public.asset_history
    ORDER BY id
    LIMIT 1000
);

ROLLBACK;