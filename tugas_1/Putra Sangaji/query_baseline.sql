SELECT
    s.nama AS status,
    EXTRACT(MONTH FROM a.tanggal_pembelian) AS bulan_beli,
    COUNT(*) AS jml_server,
    SUM(a.harga_pembelian) AS total_nilai
FROM asset a
JOIN status s
    ON s.id = a.id_status
WHERE a.id_kategori = 5 AND s.id = 2
    AND a.id_lokasi = 4
    AND a.tanggal_pembelian >= DATE '2023-01-01'
    AND a.tanggal_pembelian < DATE '2024-01-01'
    AND (
        SELECT COUNT(*)
        FROM asset_history h
        WHERE h.id_asset = a.id
    ) >= 1
GROUP BY
    s.nama,
    EXTRACT(MONTH FROM a.tanggal_pembelian)
ORDER BY
		bulan_beli ASC,
    jml_server;