SELECT a.kode_asset, a.nama_asset, s.nama AS status,  
(SELECT SUM(h.biaya) FROM asset_history h WHERE h.id_asset = a.id) AS total_biaya,
 (SELECT MAX(h.tanggal) FROM asset_history h WHERE h.id_asset = a.id) AS history_terakhir
FROM asset a
JOIN status s ON s.id = a.id_status
JOIN lokasi l ON l.id = a.id_lokasi
WHERE a.id_kategori = 5
  AND l.id = 4
  AND a.tanggal_pembelian BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY total_biaya DESC NULLS LAST;