CREATE INDEX IF NOT EXISTS idx_asset_history_asset
ON asset_history (id_asset);

CREATE INDEX IF NOT EXISTS idx_asset_filter_laporan
ON asset (id_kategori, id_status, id_lokasi, tanggal_pembelian);

ANALYZE asset;
ANALYZE asset_history;