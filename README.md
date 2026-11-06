# Şehir ve Hayat

Godot 4 ile hazırlanmış Windows hayat ve şehir stratejisi ilk oynanabilir prototipi. 1 Eylül 1962’de aydınlık veya karanlık bir yol seçin; zaman, odaklar, olaylar, ilişkiler ve şehirdeki bağımsız aktörler dünyayı değiştirir. Oyun duraklatılmış başlar.

## Oyunu başlatma

Hazırlanmış Windows paketinde `OyunuBaslat.bat` dosyasını açın veya `build/windows/SehirHayat.exe` dosyasını çalıştırın. EXE ve yanındaki `SehirHayat.pck` birlikte gereklidir. Paket Git tarafından izlenmez; yoksa aşağıdaki export adımını çalıştırın. Kaynak projeyi Godot ile açmak için `scripts/run.ps1` veya editörde `game/project.godot` kullanın.

Sol tıklama mahalle seçer; sol tuşla sürükleme kamerayı taşır, sağ tuşla sürükleme döndürür, fare tekerleği yakınlaştırır. Üst çubuktan duraklatma ve hız seçimi yapılır. Kişisel ve kurum panelleri açıldığında zaman otomatik durur; panel kapandıktan sonra üst çubuktan yeniden başlatılabilir. Odak, olay, ilişkiler ve kayıt panelleri üst çubuktadır. Başlangıç menüsündeki yetişkin senaryoları vali, polis ve ağ lideri yetkilerini denemek içindir.

## Kurulum ve geliştirme

Godot **4.7.2 stable standard Windows x86_64** gerekir. Sabit sürüm, resmî bağlantılar ve SHA-512 değerleri `tools/toolchain.json` içindedir. Motor ZIP dosyasını indirip SHA-512 özetini doğrulayın ve iki yürütülebiliri `tools/godot/` içine çıkarın. Export için aynı dosyadaki `export_templates.download_url` dosyasını indirip `export_templates.archive_sha512` ile doğrulayın; TPZ içindeki `templates` klasörünün içeriğini `tools/godot/templates/` içine çıkarın. Araçlar ve build Git'e alınmaz.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run.ps1
powershell -ExecutionPolicy Bypass -File scripts/test.ps1 -Suite integration
powershell -ExecutionPolicy Bypass -File scripts/test.ps1 -Suite all
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

Test çalıştırıcısı tek suite veya tüm suite'leri çalıştırır; başarısızlıkta sıfır dışı çıkış döndürür. Export `Windows Desktop` presetini kullanarak `build/windows/SehirHayat.exe` ve `.pck` üretir. `game/content/` altındaki JSON dosyaları odak, olay, karakter, kurum, şehir ve senaryo içeriğini barındırır; değişikliklerden sonra testleri ve export'u yeniden çalıştırın.

## Kapsam ve doğrulama

Romantik içerik tanışma ve görüşmeyle sınırlıdır; evlilik ve çocuk simülasyonu yoktur. Bu sürüm tam üniversite hayatı, çift taraflı çalışma veya normal kariyer üzerinden tüm üst makamlara yükselme sunmaz. Üniversite hazırlığı kayıt sağlar, mezuniyet sağlamaz. Makam ve yetki örnekleri geliştirme senaryolarındadır. Doğrulama yöntemi ve sınırlamaları [ilk oynanabilir raporunda](docs/validation/first-playable.md) açıklanır.
