ROLLBACK;

BEGIN;

EXPLAIN (ANALYZE, BUFFERS, WAL)
DELETE FROM public.asset_history
WHERE id IN (
    SELECT id
    FROM public.asset_history
    ORDER BY id
    LIMIT 1000
);

ROLLBACK;