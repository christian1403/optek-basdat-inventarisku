-- =====================================================================
-- Seeding data inventaris aset IT kantor (PostgreSQL)
-- Target: ±1,6 juta row
--   users          50
--   karyawan       100.000
--   status         7
--   lokasi         50
--   kategori       5
--   jenis_history  9
--   sparepart      ~47
--   teknisi        200
--   asset          ~250.000  (maks 3 aset per karyawan)
--   asset_history  ~1.290.000
--
-- Jalankan: psql -d <database> -f seed.sql
-- PERINGATAN: semua data lama di tabel-tabel ini akan dihapus (TRUNCATE).
-- Tanggal acuan "hari ini" = 2026-10-23 (hardcoded agar hasil reproducible).
-- =====================================================================

\timing on
SET client_min_messages = warning;

BEGIN;

SELECT setseed(0.42);

TRUNCATE asset_history, asset, sparepart, teknisi, jenis_history,
         kategori, lokasi, status, karyawan, users
RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------------
-- MASTER DATA
-- ---------------------------------------------------------------------

INSERT INTO status (id, nama) VALUES
    (1, 'Tersedia'),
    (2, 'Digunakan'),
    (3, 'Dalam Perbaikan'),
    (4, 'Selesai'),
    (5, 'Rusak'),
    (6, 'Hilang'),
    (7, 'Dihapuskan');

INSERT INTO kategori (id, nama) VALUES
    (1, 'PC'),
    (2, 'LAPTOP'),
    (3, 'HP'),
    (4, 'PRINTER'),
    (5, 'SERVER');

INSERT INTO jenis_history (id, nama) VALUES
    (1, 'Serah Terima'),
    (2, 'Pengembalian'),
    (3, 'Perbaikan'),
    (4, 'Perawatan Rutin'),
    (5, 'Peningkatan Spesifikasi'),
    (6, 'Penggantian Sparepart'),
    (7, 'Mutasi Lokasi'),
    (8, 'Penghapusan Aset'),
    (9, 'Laporan Kehilangan');

-- id 1-4: gudang & data center, id 5-50: ruang kantor
INSERT INTO lokasi (id, nama) VALUES
    (1, 'Gudang IT Jakarta'),
    (2, 'Gudang IT Surabaya'),
    (3, 'Data Center Jakarta'),
    (4, 'Data Center Surabaya (DRC)');

INSERT INTO lokasi (id, nama)
SELECT 4 + row_number() OVER (ORDER BY o.urut, l.lantai),
       o.nama || ' - Lantai ' || l.lantai
FROM (VALUES
        (1,  'Kantor Pusat Jakarta',     10),
        (2,  'Kantor Cabang Surabaya',    4),
        (3,  'Kantor Cabang Bandung',     4),
        (4,  'Kantor Cabang Medan',       4),
        (5,  'Kantor Cabang Semarang',    4),
        (6,  'Kantor Cabang Makassar',    4),
        (7,  'Kantor Cabang Yogyakarta',  4),
        (8,  'Kantor Cabang Denpasar',    4),
        (9,  'Kantor Cabang Balikpapan',  4),
        (10, 'Kantor Cabang Palembang',   4)
     ) o(urut, nama, jml_lantai)
CROSS JOIN LATERAL generate_series(1, o.jml_lantai) l(lantai);

INSERT INTO sparepart (nama) VALUES
    -- storage
    ('SSD SATA 256GB'), ('SSD SATA 512GB'), ('SSD NVMe 512GB'), ('SSD NVMe 1TB'),
    ('HDD 1TB 7200RPM'), ('HDD 2TB'),
    -- memory
    ('RAM DDR4 8GB'), ('RAM DDR4 16GB'), ('RAM DDR5 16GB'),
    ('RAM SODIMM DDR4 8GB'), ('RAM SODIMM DDR4 16GB'),
    -- PC
    ('PSU 450W'), ('PSU 550W'), ('Fan Processor'), ('Thermal Paste'),
    ('Motherboard PC'), ('Keyboard USB'), ('Mouse USB'), ('Kabel Power'),
    -- laptop
    ('Keyboard Laptop'), ('Baterai Laptop'), ('Charger Laptop 65W'),
    ('LCD Laptop 14 inch'), ('Touchpad Laptop'), ('Engsel Laptop'),
    -- HP
    ('Baterai HP'), ('LCD HP'), ('Charger HP'), ('Port Charging HP'),
    ('Kamera HP'), ('Speaker HP'),
    -- printer
    ('Toner Hitam'), ('Tinta Printer'), ('Head Printer'), ('Roller Printer'),
    ('Fuser Printer'), ('Drum Unit'), ('Mainboard Printer'),
    -- server
    ('RAM ECC DDR4 32GB'), ('RAM ECC DDR4 64GB'), ('SSD Enterprise 960GB'),
    ('HDD SAS 1.2TB'), ('HDD SAS 2.4TB'), ('PSU Redundant Server 750W'),
    ('Fan Server'), ('RAID Controller'), ('NIC 10GbE');

-- password = "password" (bcrypt)
INSERT INTO users (username, password, role, timestamp)
SELECT u.username,
       '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
       u.role,
       TIMESTAMP '2019-01-02 09:00' + (u.n * INTERVAL '17 days')
FROM (
    SELECT 0 AS n, 'superadmin' AS username, 'superadmin' AS role
    UNION ALL
    SELECT g, 'admin' || lpad(g::text, 2, '0'), 'admin' FROM generate_series(1, 10) g
    UNION ALL
    SELECT 10 + g, 'staffit' || lpad(g::text, 2, '0'), 'staff' FROM generate_series(1, 39) g
) u
ORDER BY u.n;

-- ---------------------------------------------------------------------
-- KARYAWAN & TEKNISI
-- ---------------------------------------------------------------------

CREATE TEMP TABLE tmp_nama ON COMMIT DROP AS
SELECT
    ARRAY['Agus','Budi','Citra','Dewi','Eko','Fajar','Gita','Hendra','Indah','Joko',
          'Kurniawan','Lestari','Maya','Nanda','Oktaviani','Putri','Rizky','Sari','Teguh','Utami',
          'Vina','Wahyu','Yusuf','Zahra','Andi','Bayu','Dian','Fitri','Galih','Hadi',
          'Ilham','Intan','Kevin','Lukman','Mega','Nur','Rina','Rudi','Siti','Taufik',
          'Wulan','Yoga','Ayu','Bambang','Dimas','Eka','Farhan','Hana','Irfan','Lina',
          'Muhammad','Nia','Reza','Sinta','Tono','Ratna','Arif','Desi','Gilang','Novi'] AS depan,
    ARRAY['Adi','Dwi','Tri','Sri','Nur','Ayu','Putra','Dewi','Rahmat','Indra'] AS tengah,
    ARRAY['Pratama','Saputra','Wijaya','Santoso','Hidayat','Kusuma','Setiawan','Nugroho','Wibowo','Susanto',
          'Gunawan','Halim','Siregar','Nasution','Harahap','Simanjuntak','Lubis','Sihombing','Ramadhan','Firmansyah',
          'Hakim','Purnomo','Suryadi','Hartono','Kurnia','Rahman','Syahputra','Maulana','Permana','Utomo',
          'Sulistyo','Anggraini','Lestari','Wahyudi','Hasibuan','Tanjung','Panjaitan','Situmorang','Manurung','Mahendra',
          'Prasetyo','Irawan','Fauzi','Saragih','Daulay','Pohan','Effendi','Iskandar','Sembiring','Hutapea'] AS belakang,
    ARRAY['Teknologi Informasi','Keuangan','Akuntansi','Sumber Daya Manusia','Pemasaran',
          'Penjualan','Operasional','Hukum','Pengadaan','Umum',
          'Layanan Pelanggan','Produksi','Logistik','Audit Internal','Perencanaan Strategis'] AS departemen;

INSERT INTO karyawan (nama, departement)
SELECT n.depan[1 + floor(random() * array_length(n.depan, 1))::int]
       || CASE WHEN random() < 0.3
               THEN ' ' || n.tengah[1 + floor(random() * array_length(n.tengah, 1))::int]
               ELSE '' END
       || ' ' || n.belakang[1 + floor(random() * array_length(n.belakang, 1))::int],
       n.departemen[1 + floor(random() * array_length(n.departemen, 1))::int]
FROM generate_series(1, 100000) g
CROSS JOIN tmp_nama n;

INSERT INTO teknisi (nama)
SELECT n.depan[1 + floor(random() * array_length(n.depan, 1))::int]
       || ' ' || n.belakang[1 + floor(random() * array_length(n.belakang, 1))::int]
FROM generate_series(1, 200) g
CROSS JOIN tmp_nama n;

-- ---------------------------------------------------------------------
-- REFERENSI MODEL & KATEGORI (temp)
-- ---------------------------------------------------------------------

CREATE TEMP TABLE tmp_kat (id int, prefix text, label text, garansi_bulan int) ON COMMIT DROP;
INSERT INTO tmp_kat VALUES
    (1, 'PC',  'PC Desktop', 36),
    (2, 'LAP', 'Laptop',     36),
    (3, 'HP',  'Smartphone', 12),
    (4, 'PRN', 'Printer',    12),
    (5, 'SRV', 'Server',     36);

CREATE TEMP TABLE tmp_model (id_kategori int, brand text, model text, harga numeric) ON COMMIT DROP;
INSERT INTO tmp_model VALUES
    -- PC
    (1, 'Dell',   'OptiPlex 3000 Tower',        9500000),
    (1, 'Dell',   'OptiPlex 7010 SFF',         14500000),
    (1, 'HP',     'ProDesk 400 G9',            10500000),
    (1, 'HP',     'EliteDesk 800 G6',          15500000),
    (1, 'Lenovo', 'ThinkCentre M70s',          10000000),
    (1, 'Lenovo', 'ThinkCentre M90q',          15000000),
    (1, 'Acer',   'Veriton M4690G',             8500000),
    (1, 'ASUS',   'ExpertCenter D5',            9000000),
    -- LAPTOP
    (2, 'Lenovo', 'ThinkPad E14 Gen 4',        12500000),
    (2, 'Lenovo', 'ThinkPad T14 Gen 3',        21000000),
    (2, 'Lenovo', 'ThinkPad X1 Carbon Gen 10', 30000000),
    (2, 'Dell',   'Latitude 3420',             11500000),
    (2, 'Dell',   'Latitude 5430',             18500000),
    (2, 'HP',     'ProBook 440 G9',            12000000),
    (2, 'HP',     'EliteBook 840 G9',          23000000),
    (2, 'ASUS',   'ExpertBook B1400',          10500000),
    (2, 'Acer',   'TravelMate P214',           10000000),
    (2, 'Apple',  'MacBook Air M2',            19000000),
    (2, 'Apple',  'MacBook Pro 14 M3',         32000000),
    -- HP
    (3, 'Samsung', 'Galaxy A15',                2600000),
    (3, 'Samsung', 'Galaxy A35',                5000000),
    (3, 'Samsung', 'Galaxy A55',                6500000),
    (3, 'Samsung', 'Galaxy S23',               12000000),
    (3, 'Xiaomi',  'Redmi Note 13',             3000000),
    (3, 'Oppo',    'A78',                       3500000),
    (3, 'Vivo',    'Y36',                       3200000),
    (3, 'Apple',   'iPhone 13',                10500000),
    (3, 'Apple',   'iPhone 15',                14500000),
    -- PRINTER
    (4, 'Epson',   'L3210',                     2400000),
    (4, 'Epson',   'L5290',                     4000000),
    (4, 'Epson',   'L15150',                   14000000),
    (4, 'HP',      'LaserJet Pro M404dn',       5500000),
    (4, 'HP',      'LaserJet Pro MFP M428fdw',  9000000),
    (4, 'Canon',   'imageCLASS MF445dw',        7500000),
    (4, 'Canon',   'PIXMA G3020',               2600000),
    (4, 'Brother', 'HL-L2375DW',                3500000),
    -- SERVER
    (5, 'Dell',       'PowerEdge R650',           185000000),
    (5, 'Dell',       'PowerEdge R750',           260000000),
    (5, 'Dell',       'PowerEdge T350',            65000000),
    (5, 'HPE',        'ProLiant DL380 Gen10 Plus', 240000000),
    (5, 'HPE',        'ProLiant DL360 Gen10',      170000000),
    (5, 'Lenovo',     'ThinkSystem SR650 V2',      230000000),
    (5, 'Supermicro', 'SuperServer 1029P',         120000000);

CREATE TEMP TABLE tmp_model_idx ON COMMIT DROP AS
SELECT m.*,
       row_number() OVER (PARTITION BY m.id_kategori ORDER BY m.brand, m.model) AS rn,
       count(*)     OVER (PARTITION BY m.id_kategori)                          AS cnt
FROM tmp_model m;

-- ---------------------------------------------------------------------
-- ASSET
-- ---------------------------------------------------------------------

CREATE TEMP TABLE tmp_asset (
    id_kategori int,
    id_karyawan int,
    id_lokasi   int,
    id_status   int,
    tipe        text,
    tanggal     date,
    r           double precision
) ON COMMIT DROP;

-- Aset pegangan karyawan: maks 1 per kategori (LAPTOP/PC/HP) => maks 3 per karyawan.
-- Lokasi aset = lokasi kantor karyawan (deterministik dari id karyawan).
INSERT INTO tmp_asset (id_kategori, id_karyawan, id_lokasi, tipe)
SELECT x.id_kategori, x.id_karyawan, 5 + (x.id_karyawan * 7919) % 46, 'karyawan'
FROM (
    SELECT k.id AS id_karyawan, c.id_kategori, c.peluang, random() AS r
    FROM karyawan k
    CROSS JOIN (VALUES (2, 0.80), (1, 0.50), (3, 0.90)) c(id_kategori, peluang)
) x
WHERE x.r < x.peluang;

-- Printer: aset bersama di ruang kantor
INSERT INTO tmp_asset (id_kategori, id_lokasi, tipe)
SELECT 4, 5 + floor(random() * 46)::int, 'printer'
FROM generate_series(1, 12000);

-- Server: di data center (70% Jakarta, 30% DRC Surabaya)
INSERT INTO tmp_asset (id_kategori, id_lokasi, tipe)
SELECT 5, CASE WHEN random() < 0.7 THEN 3 ELSE 4 END, 'server'
FROM generate_series(1, 3000);

-- Aset di gudang (stok cadangan / rusak / dihapuskan)
INSERT INTO tmp_asset (id_kategori, id_lokasi, tipe)
SELECT CASE WHEN x.r < 0.40 THEN 2
            WHEN x.r < 0.70 THEN 1
            WHEN x.r < 0.95 THEN 3
            ELSE 4 END,
       CASE WHEN random() < 0.6 THEN 1 ELSE 2 END,
       'gudang'
FROM (SELECT random() AS r FROM generate_series(1, 15000)) x;

UPDATE tmp_asset SET r = random();

UPDATE tmp_asset SET id_status = CASE tipe
    WHEN 'karyawan' THEN CASE WHEN r < 0.965 THEN 2 WHEN r < 0.995 THEN 3 ELSE 6 END
    WHEN 'printer'  THEN CASE WHEN r < 0.92  THEN 2 WHEN r < 0.97  THEN 3 ELSE 5 END
    WHEN 'server'   THEN CASE WHEN r < 0.97  THEN 2 ELSE 3 END
    WHEN 'gudang'   THEN CASE WHEN r < 0.50  THEN 1 WHEN r < 0.75  THEN 5 ELSE 7 END
END;

-- Aset yang dihapuskan cenderung aset lama (2019-2021)
UPDATE tmp_asset SET tanggal = CASE
    WHEN id_status = 7 THEN DATE '2019-01-01' + floor(random() * 1095)::int
    ELSE DATE '2019-01-01' + floor(random() * (DATE '2026-09-30' - DATE '2019-01-01'))::int
END;

-- id urut berdasarkan tanggal pembelian; n_hist = jumlah history (~1 per tahun umur aset)
CREATE TEMP TABLE tmp_asset_final ON COMMIT DROP AS
SELECT row_number() OVER (ORDER BY a.tanggal, a.r) AS id,
       a.*,
       1 + floor(random() * mc.cnt)::int AS pick,
       greatest(CASE WHEN a.tipe IN ('karyawan', 'gudang') THEN 2 ELSE 1 END,
                1 + floor((DATE '2026-10-23' - a.tanggal) / 365.0 + random() * 1.5)::int) AS n_hist
FROM tmp_asset a
JOIN (SELECT id_kategori, count(*) AS cnt FROM tmp_model GROUP BY id_kategori) mc
  ON mc.id_kategori = a.id_kategori;

INSERT INTO asset (id, kode_asset, nama_asset, brand, model, serial_number,
                   tanggal_pembelian, harga_pembelian, garansi, foto, notes, qr_token,
                   id_kategori, id_status, id_lokasi, id_karyawan, create_by, create_at, update_at)
SELECT f.id,
       k.prefix || '-' || to_char(f.tanggal, 'YYYY') || '-' || lpad(f.id::text, 6, '0'),
       k.label || ' ' || m.brand || ' ' || m.model,
       m.brand,
       m.model,
       upper(left(m.brand, 2)) || upper(substr(md5('sn-' || f.id), 1, 8)) || lpad(f.id::text, 6, '0'),
       f.tanggal,
       round(m.harga * (0.9 + random() * 0.2) / 1000) * 1000,
       (f.tanggal + make_interval(months => k.garansi_bulan))::date,
       CASE WHEN random() < 0.7 THEN 'uploads/asset/' || lower(k.prefix) || '-' || f.id || '.jpg' END,
       CASE f.id_status
           WHEN 1 THEN 'Stok cadangan, siap digunakan'
           WHEN 3 THEN 'Sedang dalam proses perbaikan'
           WHEN 5 THEN 'Rusak berat, menunggu proses penghapusan'
           WHEN 6 THEN 'Dilaporkan hilang, menunggu investigasi'
           WHEN 7 THEN 'Sudah dihapuskan dari inventaris'
       END,
       md5('qr-' || f.id),
       f.id_kategori,
       f.id_status,
       f.id_lokasi,
       f.id_karyawan,
       2 + floor(random() * 49)::int,
       f.tanggal + make_interval(hours => 8 + floor(random() * 9)::int, mins => floor(random() * 60)::int),
       f.tanggal::timestamp
FROM tmp_asset_final f
JOIN tmp_kat k        ON k.id = f.id_kategori
JOIN tmp_model_idx m  ON m.id_kategori = f.id_kategori AND m.rn = f.pick
ORDER BY f.id;

-- ---------------------------------------------------------------------
-- TEMPLATE HISTORY (keluhan / tindakan / sparepart / range biaya)
-- ---------------------------------------------------------------------

CREATE TEMP TABLE tmp_tmpl_raw (
    id_kategori int,
    id_jenis    int,
    keluhan     text,
    tindakan    text,
    sparepart   text,
    bmin        numeric,
    bmax        numeric
) ON COMMIT DROP;

INSERT INTO tmp_tmpl_raw VALUES
    -- ===== PC =====
    (1, 3, 'PC tidak mau menyala',                    'Ganti power supply',                          'PSU 450W',          450000,  750000),
    (1, 3, 'PC sering restart sendiri',               'Ganti power supply dan cek kelistrikan',      'PSU 550W',          550000,  900000),
    (1, 3, 'PC lambat dan sering hang',               'Ganti HDD ke SSD dan install ulang OS',       'SSD SATA 512GB',    600000,  900000),
    (1, 3, 'Muncul blue screen (BSOD)',               'Ganti RAM yang rusak',                        'RAM DDR4 8GB',      350000,  550000),
    (1, 3, 'PC terkena virus/malware',                'Scan antivirus dan install ulang OS',         NULL,                100000,  250000),
    (1, 3, 'Kipas berisik dan PC cepat panas',        'Ganti fan processor dan thermal paste',       'Fan Processor',     150000,  300000),
    (1, 3, 'Keyboard tidak berfungsi',                'Ganti keyboard',                              'Keyboard USB',      100000,  200000),
    (1, 3, 'Mouse tidak responsif',                   'Ganti mouse',                                 'Mouse USB',          60000,  150000),
    (1, 4, NULL,                                      'Pembersihan debu, cek hardware, update OS dan antivirus', NULL,     0,  100000),
    (1, 4, NULL,                                      'Cek kesehatan disk dan update driver',        NULL,                     0,   50000),
    (1, 5, 'Kapasitas RAM tidak mencukupi',           'Upgrade RAM menjadi 16GB',                    'RAM DDR4 8GB',      350000,  550000),
    (1, 5, 'Kapasitas RAM tidak mencukupi',           'Upgrade RAM menjadi 32GB',                    'RAM DDR4 16GB',     700000, 1000000),
    (1, 5, 'Kapasitas RAM tidak mencukupi',           'Upgrade RAM DDR5 menjadi 32GB',               'RAM DDR5 16GB',     900000, 1300000),
    (1, 5, 'Kapasitas penyimpanan penuh',             'Tambah SSD NVMe 1TB',                         'SSD NVMe 1TB',     1000000, 1600000),
    (1, 5, 'Kapasitas penyimpanan penuh',             'Tambah HDD 2TB untuk data',                   'HDD 2TB',           800000, 1200000),
    (1, 6, 'Kabel power rusak',                       'Ganti kabel power',                           'Kabel Power',        30000,   75000),
    (1, 6, 'HDD terdeteksi bad sector',               'Ganti HDD 1TB',                               'HDD 1TB 7200RPM',   600000,  900000),
    (1, 6, 'SSD terdeteksi error SMART',              'Ganti SSD SATA 256GB',                        'SSD SATA 256GB',    350000,  550000),
    (1, 6, 'Motherboard rusak',                       'Ganti motherboard',                           'Motherboard PC',   1200000, 2500000),
    -- ===== LAPTOP =====
    (2, 3, 'Baterai cepat habis / drop',              'Ganti baterai laptop',                        'Baterai Laptop',     700000, 1500000),
    (2, 3, 'Laptop tidak bisa dicharge',              'Ganti charger laptop',                        'Charger Laptop 65W', 300000,  600000),
    (2, 3, 'Layar bergaris / blank',                  'Ganti LCD laptop',                            'LCD Laptop 14 inch',1200000, 2500000),
    (2, 3, 'Beberapa tombol keyboard tidak berfungsi','Ganti keyboard laptop',                       'Keyboard Laptop',    400000,  900000),
    (2, 3, 'Engsel layar patah',                      'Ganti engsel laptop',                         'Engsel Laptop',      250000,  500000),
    (2, 3, 'Laptop lambat saat booting',              'Ganti HDD ke SSD dan install ulang OS',       'SSD NVMe 512GB',     700000, 1100000),
    (2, 3, 'Laptop overheat dan mati sendiri',        'Bersihkan kipas dan ganti thermal paste',     'Thermal Paste',      100000,  250000),
    (2, 3, 'Touchpad tidak berfungsi',                'Ganti touchpad',                              'Touchpad Laptop',    300000,  650000),
    (2, 3, 'Windows error, tidak bisa login',         'Backup data dan install ulang OS',            NULL,                 100000,  250000),
    (2, 4, NULL,                                      'Pembersihan kipas, update OS dan antivirus',  NULL,                      0,  100000),
    (2, 4, NULL,                                      'Cek kesehatan baterai dan disk',              NULL,                      0,   50000),
    (2, 5, 'Laptop lambat saat multitasking',         'Upgrade RAM menjadi 16GB',                    'RAM SODIMM DDR4 8GB', 350000, 600000),
    (2, 5, 'Laptop lambat saat multitasking',         'Upgrade RAM menjadi 32GB',                    'RAM SODIMM DDR4 16GB',700000,1100000),
    (2, 5, 'Kapasitas penyimpanan penuh',             'Upgrade SSD NVMe 1TB',                        'SSD NVMe 1TB',      1000000, 1600000),
    (2, 6, 'Kesehatan baterai di bawah 50%',          'Ganti baterai laptop',                        'Baterai Laptop',     700000, 1500000),
    (2, 6, 'Charger rusak / hilang',                  'Ganti charger laptop',                        'Charger Laptop 65W', 300000,  600000),
    (2, 6, 'SSD terdeteksi error SMART',              'Ganti SSD SATA 512GB',                        'SSD SATA 512GB',     600000,  900000),
    -- ===== HP =====
    (3, 3, 'Baterai HP cepat habis / menggembung',    'Ganti baterai HP',                            'Baterai HP',         250000,  600000),
    (3, 3, 'Layar HP retak',                          'Ganti LCD HP',                                'LCD HP',             800000, 2500000),
    (3, 3, 'HP tidak bisa dicharge',                  'Ganti port charging',                         'Port Charging HP',   150000,  350000),
    (3, 3, 'Kamera HP buram / tidak berfungsi',       'Ganti modul kamera',                          'Kamera HP',          300000,  900000),
    (3, 3, 'Suara speaker pecah',                     'Ganti speaker HP',                            'Speaker HP',         100000,  250000),
    (3, 3, 'HP sering hang / bootloop',               'Factory reset dan flash ulang firmware',      NULL,                  50000,  150000),
    (3, 4, NULL,                                      'Update OS dan aplikasi MDM',                  NULL,                      0,       0),
    (3, 4, NULL,                                      'Cek kesehatan baterai dan pembersihan perangkat', NULL,                  0,       0),
    (3, 5, 'Versi OS sudah usang',                    'Upgrade versi OS',                            NULL,                      0,       0),
    (3, 5, 'Aplikasi kerja membutuhkan versi terbaru','Upgrade firmware dan aplikasi kantor',        NULL,                      0,       0),
    (3, 6, 'Kesehatan baterai di bawah 70%',          'Ganti baterai HP',                            'Baterai HP',         250000,  600000),
    (3, 6, 'Charger rusak / hilang',                  'Ganti charger HP',                            'Charger HP',         100000,  300000),
    -- ===== PRINTER =====
    (4, 3, 'Hasil cetak bergaris',                    'Ganti head printer',                          'Head Printer',       400000, 1200000),
    (4, 3, 'Kertas sering macet (paper jam)',         'Ganti roller printer',                        'Roller Printer',     150000,  400000),
    (4, 3, 'Hasil cetak pudar',                       'Ganti drum unit',                             'Drum Unit',          500000, 1200000),
    (4, 3, 'Hasil cetak luntur / tidak menempel',     'Ganti fuser printer',                         'Fuser Printer',      800000, 2000000),
    (4, 3, 'Printer tidak terdeteksi di jaringan',    'Konfigurasi ulang jaringan dan driver printer', NULL,                    0,  100000),
    (4, 3, 'Printer mati total',                      'Ganti mainboard printer',                     'Mainboard Printer',  900000, 2500000),
    (4, 4, NULL,                                      'Pembersihan head dan roller, kalibrasi',      NULL,                  50000,  150000),
    (4, 4, NULL,                                      'Cleaning printer dan cek counter halaman',    NULL,                      0,  100000),
    (4, 5, NULL,                                      'Upgrade firmware printer',                    NULL,                      0,       0),
    (4, 5, 'Kebutuhan fitur scan ke email',           'Upgrade firmware dan konfigurasi scan-to-email', NULL,                   0,  100000),
    (4, 6, 'Toner habis',                             'Ganti toner hitam',                           'Toner Hitam',        350000,  900000),
    (4, 6, 'Tinta habis',                             'Isi ulang tinta printer',                     'Tinta Printer',       80000,  200000),
    (4, 6, 'Tinta habis',                             'Isi ulang tinta semua warna',                 'Tinta Printer',      200000,  400000),
    (4, 6, 'Drum unit habis masa pakai',              'Ganti drum unit',                             'Drum Unit',          500000, 1200000),
    -- ===== SERVER =====
    (5, 3, 'Disk RAID degraded',                      'Ganti hard disk SAS yang rusak dan rebuild RAID', 'HDD SAS 1.2TB',   2500000, 4500000),
    (5, 3, 'PSU server failure (alarm)',              'Ganti PSU redundant',                         'PSU Redundant Server 750W', 3000000, 6000000),
    (5, 3, 'Fan server error / suhu tinggi',          'Ganti fan server',                            'Fan Server',         800000, 1800000),
    (5, 3, 'Memory error terdeteksi (ECC)',           'Ganti modul RAM ECC',                         'RAM ECC DDR4 32GB', 3000000, 5000000),
    (5, 3, 'RAID controller error',                   'Ganti RAID controller',                       'RAID Controller',   5000000, 9000000),
    (5, 3, 'Koneksi jaringan server putus-putus',     'Ganti NIC',                                   'NIC 10GbE',         2500000, 5000000),
    (5, 4, NULL,                                      'Update firmware/BIOS dan patch OS',           NULL,                      0,       0),
    (5, 4, NULL,                                      'Cek log hardware, suhu, dan status RAID',     NULL,                      0,       0),
    (5, 4, NULL,                                      'Pembersihan rak dan manajemen kabel',         NULL,                      0,       0),
    (5, 5, 'Utilisasi memori tinggi',                 'Tambah RAM ECC 64GB',                         'RAM ECC DDR4 64GB', 6000000, 9000000),
    (5, 5, 'Kapasitas storage hampir penuh',          'Tambah SSD enterprise 960GB',                 'SSD Enterprise 960GB', 4000000, 7000000),
    (5, 5, 'Kapasitas storage hampir penuh',          'Tambah HDD SAS 2.4TB',                        'HDD SAS 2.4TB',     4000000, 6500000),
    (5, 5, 'Bandwidth jaringan tidak mencukupi',      'Upgrade NIC ke 10GbE',                        'NIC 10GbE',         2500000, 5000000),
    (5, 6, 'Disk predictive failure',                 'Ganti SSD enterprise 960GB',                  'SSD Enterprise 960GB', 4000000, 7000000),
    (5, 6, 'Disk predictive failure',                 'Ganti HDD SAS 1.2TB',                         'HDD SAS 1.2TB',     2500000, 4500000),
    (5, 6, 'Fan server berisik',                      'Ganti fan server',                            'Fan Server',         800000, 1800000),
    (5, 7, 'Relokasi rak data center',                'Pemindahan server ke rak baru',               NULL,                      0,       0),
    (5, 7, 'Migrasi ke site DRC',                     'Pemindahan server antar data center',         NULL,                      0,       0);

-- Mutasi lokasi untuk PC/LAPTOP/HP/PRINTER
INSERT INTO tmp_tmpl_raw
SELECT k.id, 7, g.keluhan, g.tindakan, NULL, 0, 0
FROM kategori k
CROSS JOIN (VALUES
    ('Karyawan pindah ruangan / lantai', 'Pemindahan aset ke lokasi baru'),
    ('Reorganisasi tata letak kantor',   'Pemindahan dan instalasi ulang aset')
) g(keluhan, tindakan)
WHERE k.id <> 5;

-- Template umum (berlaku semua kategori)
INSERT INTO tmp_tmpl_raw
SELECT k.id, g.id_jenis, g.keluhan, g.tindakan, NULL, 0, 0
FROM kategori k
CROSS JOIN (VALUES
    (1, NULL,                                           'Serah terima aset kepada karyawan'),
    (1, NULL,                                           'Serah terima aset beserta kelengkapannya'),
    (1, NULL,                                           'Serah terima aset untuk karyawan baru'),
    (2, 'Karyawan resign',                              'Pengembalian aset ke Gudang IT'),
    (2, 'Penggantian dengan unit baru',                 'Pengembalian aset lama ke Gudang IT'),
    (2, 'Karyawan mutasi',                              'Pengembalian aset ke Gudang IT'),
    (8, 'Aset melewati umur ekonomis',                  'Aset dihapuskan dari inventaris'),
    (8, 'Kerusakan berat, tidak ekonomis diperbaiki',   'Aset dihapuskan dan diserahkan ke vendor e-waste'),
    (8, 'Aset dilelang',                                'Aset dihapuskan melalui proses lelang'),
    (9, 'Aset dilaporkan hilang oleh karyawan',         'Pembuatan berita acara kehilangan'),
    (9, 'Aset hilang saat perjalanan dinas',            'Pembuatan berita acara kehilangan dan laporan polisi')
) g(id_jenis, keluhan, tindakan);

CREATE TEMP TABLE tmp_tmpl ON COMMIT DROP AS
SELECT t.*,
       s.id AS id_sparepart,
       row_number() OVER (PARTITION BY t.id_kategori, t.id_jenis
                          ORDER BY t.tindakan, t.keluhan NULLS FIRST) AS rn
FROM tmp_tmpl_raw t
LEFT JOIN sparepart s ON s.nama = t.sparepart;

CREATE TEMP TABLE tmp_tmpl_grp ON COMMIT DROP AS
SELECT id_kategori, id_jenis, count(*) AS cnt
FROM tmp_tmpl
GROUP BY id_kategori, id_jenis;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM tmp_tmpl WHERE sparepart IS NOT NULL AND id_sparepart IS NULL) THEN
        RAISE EXCEPTION 'Ada nama sparepart di template yang tidak ditemukan di tabel sparepart';
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- ASSET HISTORY
-- ---------------------------------------------------------------------

-- 1 row per event
CREATE TEMP TABLE tmp_h ON COMMIT DROP AS
SELECT a.id                                   AS id_asset,
       a.id_kategori,
       a.id_status                            AS st_asset,
       f.tipe,
       a.tanggal_pembelian                    AS tgl_beli,
       a.garansi,
       (DATE '2026-10-23' - a.tanggal_pembelian) AS span,
       f.n_hist                               AS n,
       g.i,
       random()                               AS r,
       random()                               AS rg
FROM asset a
JOIN tmp_asset_final f ON f.id = a.id
CROSS JOIN LATERAL generate_series(1, f.n_hist) g(i);

-- Tentukan jenis, status, tanggal event.
-- Event terakhir disesuaikan dengan status aset sekarang.
CREATE TEMP TABLE tmp_h2 ON COMMIT DROP AS
SELECT h.*,
       CASE
           WHEN h.i = h.n AND h.st_asset = 7      THEN 8  -- Penghapusan Aset
           WHEN h.i = h.n AND h.st_asset = 6      THEN 9  -- Laporan Kehilangan
           WHEN h.i = h.n AND h.st_asset IN (3, 5) THEN 3  -- Perbaikan (berjalan / gagal)
           WHEN h.i = h.n AND h.st_asset = 1      THEN 2  -- Pengembalian ke gudang
           WHEN h.i = 1 AND h.tipe IN ('karyawan', 'gudang') THEN 1  -- Serah Terima
           WHEN h.id_kategori IN (1, 2, 3) THEN
               CASE WHEN h.r < 0.35 THEN 3 WHEN h.r < 0.60 THEN 4 WHEN h.r < 0.70 THEN 5
                    WHEN h.r < 0.90 THEN 6 ELSE 7 END
           WHEN h.id_kategori = 4 THEN
               CASE WHEN h.r < 0.30 THEN 3 WHEN h.r < 0.65 THEN 4 WHEN h.r < 0.70 THEN 5
                    WHEN h.r < 0.95 THEN 6 ELSE 7 END
           ELSE
               CASE WHEN h.r < 0.10 THEN 3 WHEN h.r < 0.55 THEN 4 WHEN h.r < 0.75 THEN 5
                    WHEN h.r < 0.95 THEN 6 ELSE 7 END
       END AS id_jenis,
       CASE WHEN h.i = h.n AND h.st_asset IN (3, 5, 6, 7) THEN h.st_asset ELSE 4 END AS id_status_h,
       CASE
           WHEN h.i = 1 AND h.tipe IN ('karyawan', 'gudang')
               THEN h.tgl_beli + floor(random() * least(14, h.span / h.n))::int
           ELSE h.tgl_beli + floor(((h.i - 1) + random()) / h.n * h.span)::int
       END AS tanggal
FROM tmp_h h;

CREATE TEMP TABLE tmp_h3 ON COMMIT DROP AS
SELECT h.*,
       1 + floor(random() * g.cnt)::int AS pick,
       random() AS rf,
       (h.id_jenis IN (3, 6) AND h.id_status_h = 4 AND h.tanggal <= h.garansi AND h.rg < 0.6) AS klaim_garansi,
       h.tanggal + make_interval(hours => 8 + floor(random() * 9)::int, mins => floor(random() * 60)::int) AS ts
FROM tmp_h2 h
JOIN tmp_tmpl_grp g ON g.id_kategori = h.id_kategori AND g.id_jenis = h.id_jenis;

INSERT INTO asset_history (id_asset, tanggal, id_jenis, keluhan, tindakan, id_teknisi, id_status,
                           id_sparepart, biaya, foto_sebelum, foto_sesudah, notes, create_at, update_at)
SELECT h.id_asset,
       h.tanggal,
       h.id_jenis,
       t.keluhan,
       CASE h.id_status_h
           WHEN 3 THEN 'Dalam pengerjaan: ' || t.tindakan
           WHEN 5 THEN 'Kerusakan berat, tidak ekonomis untuk diperbaiki. Direkomendasikan penghapusan aset.'
           ELSE t.tindakan
       END,
       CASE WHEN h.id_jenis IN (3, 4, 5, 6, 8) THEN 1 + floor(random() * 200)::int END,
       h.id_status_h,
       CASE WHEN h.id_status_h = 5 THEN NULL ELSE t.id_sparepart END,
       CASE
           WHEN h.id_status_h = 3 THEN NULL
           WHEN h.id_status_h = 5 OR h.klaim_garansi THEN 0
           ELSE round((t.bmin + random() * (t.bmax - t.bmin)) / 1000) * 1000
       END,
       CASE WHEN h.id_jenis IN (3, 5, 6) AND h.rf < 0.6
            THEN 'uploads/history/' || h.id_asset || '-' || h.i || '-sebelum.jpg' END,
       CASE WHEN h.id_jenis IN (3, 5, 6) AND h.rf < 0.6 AND h.id_status_h = 4
            THEN 'uploads/history/' || h.id_asset || '-' || h.i || '-sesudah.jpg' END,
       CASE
           WHEN h.klaim_garansi THEN 'Ditangani melalui klaim garansi vendor'
           WHEN h.rg > 0.92 THEN (ARRAY['Dikerjakan di tempat (onsite)',
                                        'Dibawa ke service center resmi',
                                        'Sudah dikonfirmasi oleh pengguna',
                                        'Perlu monitoring lanjutan',
                                        'Dikerjakan di luar jam kerja'])[1 + floor(random() * 5)::int]
       END,
       h.ts,
       CASE WHEN h.id_status_h = 4 AND h.id_jenis IN (3, 5, 6)
            THEN least(h.ts + make_interval(days => floor(random() * 4)::int, hours => floor(random() * 5)::int),
                       TIMESTAMP '2026-10-23 17:00')
            ELSE h.ts
       END
FROM tmp_h3 h
JOIN tmp_tmpl t ON t.id_kategori = h.id_kategori AND t.id_jenis = h.id_jenis AND t.rn = h.pick
ORDER BY h.tanggal, h.id_asset, h.i;

DO $$
DECLARE
    expected bigint;
    actual   bigint;
BEGIN
    SELECT count(*) INTO expected FROM tmp_h;
    SELECT count(*) INTO actual   FROM asset_history;
    IF expected <> actual THEN
        RAISE EXCEPTION 'Jumlah history tidak sesuai: expected %, actual %', expected, actual;
    END IF;
END $$;

-- update_at aset = aktivitas history terakhir
UPDATE asset a
SET update_at = h.terakhir
FROM (SELECT id_asset, max(update_at) AS terakhir FROM asset_history GROUP BY id_asset) h
WHERE a.id = h.id_asset;

-- ---------------------------------------------------------------------
-- SINKRONKAN SEQUENCE
-- ---------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('status', 'id'),        (SELECT max(id) FROM status));
SELECT setval(pg_get_serial_sequence('kategori', 'id'),      (SELECT max(id) FROM kategori));
SELECT setval(pg_get_serial_sequence('jenis_history', 'id'), (SELECT max(id) FROM jenis_history));
SELECT setval(pg_get_serial_sequence('lokasi', 'id'),        (SELECT max(id) FROM lokasi));
SELECT setval(pg_get_serial_sequence('asset', 'id'),         (SELECT max(id) FROM asset));

COMMIT;

ANALYZE;

-- ---------------------------------------------------------------------
-- RINGKASAN
-- ---------------------------------------------------------------------
SELECT 'users' AS tabel, count(*) AS jumlah FROM users
UNION ALL SELECT 'karyawan',      count(*) FROM karyawan
UNION ALL SELECT 'status',        count(*) FROM status
UNION ALL SELECT 'lokasi',        count(*) FROM lokasi
UNION ALL SELECT 'kategori',      count(*) FROM kategori
UNION ALL SELECT 'jenis_history', count(*) FROM jenis_history
UNION ALL SELECT 'sparepart',     count(*) FROM sparepart
UNION ALL SELECT 'teknisi',       count(*) FROM teknisi
UNION ALL SELECT 'asset',         count(*) FROM asset
UNION ALL SELECT 'asset_history', count(*) FROM asset_history;
