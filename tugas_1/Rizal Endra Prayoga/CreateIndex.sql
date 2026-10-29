CREATE INDEX idx_history_asset_latest
ON public.asset_history (
    id_asset,
    tanggal DESC,
    id DESC
);