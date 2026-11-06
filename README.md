# Şehir ve Hayat

Windows için Godot 4 standard ve GDScript ile geliştirilen hayat ve şehir stratejisi prototipi. Bu ilk adım yalnızca boş bir Node3D ana sahne ve bağımlılıksız test altyapısı içerir.

## Kurulum

Godot **4.7.2 stable standard Windows x86_64** kullanılır. Kesin `--version` çıktısı ve resmî indirme bağlantıları `tools/toolchain.json` içindedir; başlatıcılar farklı sürümü reddeder. .NET sürümü veya harici test eklentisi gerekmez.

1. `tools/toolchain.json` içindeki `download_url` bağlantısından resmî ZIP dosyasını indirin.
2. PowerShell `Get-FileHash -Algorithm SHA512 <dosya.zip>` çıktısını `archive_sha512` ile karşılaştırın.
3. ZIP içindeki iki yürütülebiliri `tools/godot/` klasörüne çıkarın.

Araçlar Git'e alınmaz. Dışa aktarma şablonlarının aynı sürümü ve özeti de sabitlenmiştir; bu bootstrap adımı şablonları indirmez veya oyun dışa aktarmaz.

## Çalıştırma

Proje kökünde PowerShell ile:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run.ps1
powershell -ExecutionPolicy Bypass -File scripts/test.ps1 -Suite boot
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
```

Son komut tüm `game/tests/test_*.gd` dosyalarını sıralı çalıştırır. Betikler başka çalışma klasöründen de mutlak yollarıyla çağrılabilir. Oyun Compatibility renderer ve 1280×720 başlangıç penceresi kullanır. Henüz şehir veya oynanış yoktur.

## Test sözleşmesi

Her `game/tests/test_<suite>.gd` dosyası `RefCounted` tabanlıdır ve `run() -> Array[String]` ile hata listesi döndürür. Boş liste başarıdır. `-Suite <suite>` tek dosyayı, varsayılan `-Suite all` tüm dosyaları seçer. Çalıştırıcı `PASS <suite>` ve exit 0 veya hata ayrıntılarıyla `FAIL <suite>` ve exit 1 üretir. Bilinmeyen/boş test kümesi başarısız olur. PowerShell başlatıcısı motorun çıkış kodunu aynen iletir; motor eksikse veya sürüm eşleşmiyorsa anlaşılır hata ve exit 1 döndürür.

Çıplak motor komutu:

```powershell
./tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/run_tests.gd -- --suite=boot
```

Godot editöründe açmak için `game/project.godot` dosyasını seçin. Tasarım ve uygulama planı `docs/superpowers/` altındadır.
