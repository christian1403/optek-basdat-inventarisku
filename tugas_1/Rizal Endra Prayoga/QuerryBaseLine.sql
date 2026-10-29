EXPLAIN(ANALYSE,BUFFERS)
SELECT
    a.id AS id_aset,
    a.nama_asset,
    a.kode_asset,
    a.brand,
    a.model,
    a.serial_number,
    a.tanggal_pembelian,
    l.nama AS lokasi,

    COUNT(h.id) AS jumlah_riwayat,
    COUNT(DISTINCT h.id_jenis) AS jumlah_jenis_aktivitas,
    COUNT(DISTINCT h.id_teknisi) AS jumlah_teknisi,

    SUM(COALESCE(h.biaya, 0)) AS total_biaya_riwayat,
    MAX(h.tanggal) AS tanggal_aktivitas_terakhir,

    MAX(terakhir.aktivitas_terakhir)
        AS jenis_aktivitas_terakhir

FROM public.asset a

LEFT JOIN public.lokasi l
    ON l.id = a.id_lokasi

LEFT JOIN public.asset_history h
    ON h.id_asset = a.id

LEFT JOIN LATERAL (
    SELECT
        j.nama AS aktivitas_terakhir
    FROM public.asset_history hx
    LEFT JOIN public.jenis_history j
        ON j.id = hx.id_jenis
    WHERE hx.id_asset = a.id
    ORDER BY hx.tanggal DESC, hx.id DESC
    LIMIT 1
) terakhir ON TRUE

WHERE a.id_kategori = 2
  AND a.tanggal_pembelian >= DATE '2023-01-01'
  AND a.tanggal_pembelian < DATE '2024-01-01'

GROUP BY
    a.id,
    a.nama_asset,
    a.kode_asset,
    a.brand,
    a.model,
    a.serial_number,
    a.tanggal_pembelian,
    l.nama

ORDER BY
    jumlah_riwayat DESC,
    total_biaya_riwayat DESC

