# TODO — Vortex Dashboard

## Quick Wins (Kerjain Dulu)

- [ ] Bump NDK ke 27.0 di `setup_fresh.py` (fix CI build)
- [ ] Hapus dependensi gak dipake: `fl_chart`, `geocoding`, `equatable`, `freezed_annotation`, `smooth_page_indicator`, `freezed`, `json_serializable`
- [ ] Battery: kirim nilai real dari device, bukan hardcode 85
- [ ] Skip bikin personal group kalo user udah punya grup lain
- [ ] Fix tombol "+" di navbar — jangan pindahin IndexedStack ke SizedBox kosong
- [ ] Extract rumus haversine ke satu utility bersama (`LocationUtils` atau pake `geolocator.distanceBetween`)
- [ ] Naikin timer screen-pos dari 100ms → 250ms

## Arsitektur & Refactoring

- [ ] Pisah MapScreen (1429 baris) jadi file lebih kecil:
  - `map_markers_layer.dart` — marker building + clustering
  - `map_controls.dart` — tombol kamera, 3D/terrain/globe/heatmap
  - `map_overlays.dart` — geofence + heatmap painter
  - `map_debug.dart` — panel debug
- [ ] Rename `currentUserProvider` di `partner_provider.dart` biar gak bentrok dengan `tracking_provider.dart`
- [ ] Normalisasi key `id` vs `user_id` di layer API, bukan di model `MemberInfo.fromJson`

## User Experience

- [ ] Tampilin data member terakhir dari Hive kalo API offline ("Terakhir update X yang lalu")
- [ ] Bisa ganti grup langsung dari map (dropdown atau swipe)
- [ ] Pull-to-refresh di groups, notifications, geofence screens
- [ ] Loading state tiap ganti tab/grup (jangan langsung kosong)

## Performa

- [ ] Heatmap processing pindah ke isolate/background, jangan di main thread
- [ ] Manfaatin `AnimatedPositioned` key biar marker yang sama gak rebuild tiap frame
- [ ] Pisah overlay berat (heatmap) ke RepaintBoundary sendiri

## Fitur Kurang (Prioritas Tinggi)

- [ ] Android foreground service — tracking tetep jalan kalo app di-kill
- [ ] Push notification (FCM) — geofence alerts, member join/leave, SOS
- [ ] Notifikasi geofence beneran — ada bunyi + system notification, bukan cuma event stream
- [ ] SOS kirim ke kontak darurat (SMS/API/call)
- [ ] Crash detection — subscribe event-nya, kirim alert ke grup/kontak darurat
- [ ] Upload foto profil beneran (kirim file ke server, bukan cuma path lokal)

## CI / Build Stability

- [ ] Tambah `android { ndkVersion = "27.0.12077973" }` di `setup_fresh.py`
- [ ] Commit file generated build_runner atau tambah `|| true` fallback
- [ ] GitHub Actions caching buat `.gradle`, `pub-cache`, `build/`

## Technical Debt

- [ ] Pilih satu gaya opacity: `withAlpha` (0-255) atau `withValues(alpha:)` (0.0-1.0), konsisten semua file
- [ ] Hapus folder screen kosong: `altimeter/`, `compass/`, `gps_status/`, `performance/`, `ride_history/`, `tracking/`, `trip_analytics/`
