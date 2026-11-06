# İlk oynanabilir doğrulaması — 6 Kasım 2026

Godot 4.7.2 stable, Windows x86_64, Compatibility renderer. `scripts/test.ps1 -Suite life` ve `-Suite all` PASS; `scripts/export.ps1` headless editör import ve Windows export işlemlerini başarıyla tamamladı. `build/windows/SehirHayat.exe` (109268480 bayt) ve `SehirHayat.pck` (137736 bayt) üretildi. Export edilmiş EXE grafik aygıtını açtı ve `--quit-after 120` ile çıkış kodu 0 verdi; kayıt: `task10/exported-smoke.log`.

Entegrasyon testi sahne ve gerçek UI sinyalleriyle aydınlık başlangıç, duraklatma, 28 günlük hazırlık, üniversite kaydı, aile kararı, bağımsız NPC etkisi, kayıt/yükleme, kontrollü ölüm ve yeni kişi akışını doğrular. Ayrı karanlık ve polis testleri risk, kanıt ve yetki sınırlarını sınar. Ömür özeti tamamlanan odağın içerik kataloğundaki Türkçe adını gösterir.

`task10/` içindeki 23 görüntü, kaynak projeyi gerçek Godot renderer ile 1280×720 ve 800×640 boyutlarında çalıştıran `game/tests/capture_delivery.gd` tarafından oluşturuldu. Başlangıç, şehir, odak, 28. gün olayı, aile sonucu, yükleme, mahalle, yakınlaştırma, ölüm ve yeni hayat ile üç yetki senaryosu görüntülendi. Komut dosyası UI sinyallerini ve kontrollü ölüm fikstürünü kullanır; fiziksel fare/klavye girdisini veya export edilmiş EXE üzerindeki uçtan uca etkileşimi doğrulamaz. Bu nedenle export üzerinde insan tarafından tüm akışın görsel oynanışı hâlâ doğrulanmalıdır. Ölüm ekranının 800×640 görüntüsünde Türkçe başlık ve kaydırma incelendi. Donanım: Ryzen 5 3400G, GeForce GT 730, OpenGL 3.3.

Tam üniversite yaşamı, çift taraflı çalışma ve normal kariyerle bütün üst makamlara ulaşma kapsam dışıdır. Bu kanıtlar farklı donanım ve pencere boyutlarında davranış garantisi vermez.
