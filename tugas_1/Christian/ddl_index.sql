-- Index Tunggal
CREATE INDEX idx_asset_history_id_asset ON asset_history (id_asset);
-- Index Komposit
CREATE INDEX idx_asset_lokasi_kategori_tanggal ON asset (id_lokasi, id_kategori, tanggal_pembelian);