# Şehir ve hayat stratejisi — tasarım taslağı

Durum: Kullanıcı tarafından 2026-11-06 tarihinde onaylandı. Uygulama planı hazırlanıyor; ürün kodu henüz yazılmadı.

## Amaç

1960'lardan esinlenen, Türkiye havası taşıyan kurgusal bir ülkede sıradan bir insanın güç ve sorumluluk kazanmasını konu alan tek oyunculu hayat ve şehir stratejisi. Eğlence; odaklar, kişisel ilişkiler, kaynak kararları ve aynı mahallede çatışan kurumların doğurduğu hikâyelerden gelir. Oyuncu karakteri dünyanın merkezi değildir: seçilmeyen kariyerler ve diğer kişiler yaşamaya devam eder.

Suç yolu yükselmeye izin verir fakat risksiz, mutlu bir başarı vaadi sunmaz. Kullanıcının amacı mafyaya özendirmek değil, bu hayatın bedellerini göstermektir. Karanlık kariyerin nihai trajik sonu uzun vadeli içerik hedefidir; ilk sürümde her karanlık karaktere otomatik rastgele ölüm uygulanmaz. Hapis, ilişkilerin bozulması ve ölüm riskleri kararlarla ve dünya koşullarıyla bağlantılı, anlaşılabilir sonuçlar üretmelidir.

## Kesinleşen kararlar

- Windows, Godot 4 ve GDScript.
- Başlangıç yaşı 17 yıl 6 ay. Çocukluk oynanmaz; seçilen yola uygun bilinen geçmiş başlangıçta oluşturulur.
- Aydınlık geçmiş: lise mezunu, üniversiteye hazırlanan genç. Karanlık geçmiş: okuldan uzaklaşmış/liseyi bırakmış genç. Bu, genel toplum hakkında bir nedensellik iddiası değildir.
- HOI4 esintili süreli odak ağacı: karanlık ve aydınlık ana yollar. Aydınlık içinde kamu yönetimi ve polislik ayrı kariyerlerdir.
- Üniversite hazırlık odağı bittiğinde üniversiteye giriş gerçekleşir; mezuniyet sonraki aşamadır. Hukuk, kamu yönetimi ve siyaset temaları bulunur; mühendislik kapsam dışıdır. Polisliğin giriş/eğitim koşulları kurgusal ülkeye göre ayrıca veri olarak tanımlanır.
- Kamu yönetimi kolunun şimdilik en üst makamı vali. Polislik valiliğe terfi eden bir dal değildir; kendi yöneticileri ve kararları vardır. Valiyle birlikte çalışabilir veya önceliklerde anlaşamayabilir.
- Oyuncu hem kişisel hayatını hem makamı/örgütü ölçüsünde ekip ve bölgeleri yönetir.
- Hazır kurulmuş 3B şehir. Nova Roma esintisi: yüksek açıdan görülen stilize yapılar, yollar ve hareketli şehir hayatı. Roma mimarisi veya kaynak varlıkları kopyalanmaz.
- Karakter doğrudan hareket ettirilmez. Bina, mahalle ve karakter panelleri üzerinden karar verilir.
- Her insanın sınırlı ömrü vardır. Oyuncu öldüğünde o hayat kapanır, özet gösterilir. Aynı dünyada farklı bir karakterle devam edilebilir; servet ve makam otomatik devredilmez. Eski hayatın dünya üzerindeki etkileri korunur.
- İleride çift taraflı çalışma ve kariyerler arası gizli bağlantılar desteklenecek.

## Yaklaşımlar

Godot + GDScript seçildi: 3B şehir, arayüz ve simülasyonu aynı projede geliştirmek ve küçük Windows sürümüyle başlamak için. Unity + C# güçlü hazır araç ekosistemiyle alternatifti; bu proje için seçilmedi. Tarayıcı + Three.js paylaşılabilir önizlemeyi kolaylaştırır, ancak tam oyun araçlarının daha fazlasını kendimiz oluşturmamızı gerektirir; ana oyun için seçilmedi. Önceki HTML önizlemesi yalnızca arayüz konuşmasıdır, oyun kodunun temeli değildir.

## İlk oynanabilir kapsam — tasarımcı önerisi

Tek küçük şehir: birbirine bağlı üç mahalle; ev, kahvehane/çarşı, eğitim binası, karakol ve hükümet binası. İlk modeller sade geometriler olabilir; nihai sanat üretimi bu aşamanın koşulu değildir. Sokaklar görünür, fakat şehir inşası ve her binanın iç mekânı yoktur.

Oyuncu başlangıçta yol seçer; geçmiş buna göre oluşturulur. İlk içerik her kariyerin başlangıcını gösteren az sayıda odaktan oluşur. Tam üniversite ve onlarca yıllık makam ilerleyişi ilk sürümün zorunlu içeriği değildir. Oyuncu dışındaki vali, polis yöneticisi, suç lideri ve birkaç aile/mahalle kişisi baştan vardır. Makam yönetimini erken deneyebilmek için ayrı geliştirme senaryoları hazırlanabilir; bunlar normal oyunda kariyer atlatmaz.

İlk sürümün temel başarı döngüsü: mahalle/bina seç → panelden mevcut koşulları gör → odak veya olay kararı ver → zaman ilerlesin → kişi ve bölge durumunda nedenli sonuç gör. Eğitim odağı üniversiteye girişi, polis senaryosu soruşturma tercihini, suç senaryosu kazanç ile yakalanma riskini göstermeli. NPC eylemleri oyuncu seçiminden bağımsız en az bir dünya değişikliği üretmeli.

## Arayüz ve kontrol

Üst çubuk: tarih, duraklatma ve zaman hızları. Şehir: kamera kaydırma, döndürme ve yakınlaştırma; tıklanan bina veya mahallede seçim vurgusu. Yan panel: karakter, yaş, sağlık, para ve aktif odak. Açılan paneller: odak ağacı, hayat/ilişkiler, mahalle, kamu görevi ve polislik. İşlevler karakterin yetkisine göre açılır; başlangıç karakteri emniyet bütçesi yönetemez.

Şema:

    Tarih | Duraklat / Hız | Karakter / Odaklar / İlişkiler
    ---------------------------------------------------
    Yaşayan 3B şehir                 Seçilen yer paneli
    yollar, evler, yayalar           kişiler / etki / karar
    ---------------------------------------------------
    Olay bildirimi / kararın sonucu

Harita katmanları ilerleyen aşamada resmî yetki, suç etkisi ve halk güvenini ayrı gösterir. Aynı mahallede bu güçler farklı aktörlere ait olabilir.

## Simülasyon mimarisi — tasarımcı önerisi

- Görsel sahneler dünya durumunun sunumudur; yetki ve para gibi gerçek durum sahne düğümlerinde tutulmaz.
- Takvim günlük simülasyon adımlarıyla ilerler. Gerçek zaman hızı ayarlanabilir ve durdurulabilir. İlk prototipte başlangıç/bitiş tarihleri belirlenmiş kısa odaklar kullanılır; gerçek süre ve denge değerleri veriyle değişir.
- Karakterler benzersiz kimlik, doğum tarihi, sağlık, para, geçmiş, eğitim, meslek/makam ve ilişkilere sahiptir. Yaş tarihten türetilir; tüm karakterlere eşit şekilde zaman işler. Ömür sonu/sağlık ve olay kaynaklı ölüm ayrı nedenlerdir.
- Mahallelerde nüfus özeti, refah, halk güveni ve aktör etkileri bulunur. Başlangıçta yalnızca önemli isimler ayrıntılı simüle edilir; diğer nüfus özetlenir.
- NPC kararları kurallı ve sınırlı aralıklarla hesaplanır. Yürüyen kalabalık görsel temsildir; her yayanın ayrı ömür simülasyonu gerekmez.
- Odak verisi: kimlik, kariyer dalı, ön koşullar, süre, maliyet, açılan eylemler ve tamamlanma etkileri. İlk aşamada bir aktif odak; geçersiz veya tamamlanmış odak tekrar başlatılamaz.
- Olay verisi: tetikleyici, katılımcılar, seçenekler, uygunluk ve etkiler. Rasgele sonuçlar tohumlanabilir; riskin varlığı ve ilgili nedenler oyuncuya açıklanır.
- Vali bütçe ve güvenlik önceliklerini; polis soruşturma ve operasyon tercihlerini yönetir. Kesin yetki matrisi uygulama planında kurgusal oyun kuralları olarak yazılır; Türkiye mevzuatının birebir simülasyonu hedeflenmez.
- Eğitim uzmanlık ve uygun eylem avantajları verir. Sayısal bonuslar, eşikler ve süreler dengeleme verisidir; henüz kesinleşmemiştir.
- Kayıt sürümü, takvim, karakterler, aktörler, mahalleler, aktif odak/olaylar ve rastgelelik durumu birlikte saklanır. Yeni karakter aynı dünya durumunda oluşturulur; eski kimlikler silinmez.

## Aşamalar

1. Şehir, kamera, seçim ve boş olmayan bilgi panelleri.
2. Takvim, başlangıç karakteri, yol/geçmiş oluşturma ve ilk odak.
3. Karar olayları, ilişkiler ve oyuncudan bağımsız NPC eylemleri.
4. Üç kariyer için küçük oynanabilir örnekler; vali/polis yetki ayrımı.
5. Sonuçların mahalle göstergelerine ve şehir sunumuna yansıması.
6. Kayıt/yükleme, ölüm özeti ve aynı dünyada yeni karakter.

## Doğrulama

Günlük simülasyon ve odak ön koşulları görselsiz çalıştırılabilir olmalı. Tarih ilerlemesi, bir kez tamamlama, geçersiz seçimlerin reddi, NPC bağımsız eylemi, rol yetkileri ve kayıt sonrası durum eşitliği kontrol edilir. Ölüm sonrası yeni karakterde eski dünya etkilerinin korunması kontrol edilir. Kamera, tıklama, panel okunabilirliği ve zaman kontrolleri çalışan oyun içinde elle incelenir. Hedef donanım ve performans bütçesi ölçümle belirlenecek; henüz FPS garantisi yoktur.

## Kapsam dışı ve kaçınılacak sonuçlar

İlk sürümde çok oyunculu, açık dünyada karakter kontrolü, bina inşa sistemi, çocukluk oynanışı, bütün ülke, tam ekonomi simülasyonu, aileden otomatik miras, double agent sistemi ve tüm kariyerlerin onlarca yıllık içeriği yoktur. Uzun vadeli vizyonda yer alabilirler.

Suçun yalnızca yüksek gelir ve güç veren en iyi stratejiye dönüşmesi; oyuncunun nedenini anlayamadığı sürekli rastgele ölüm; NPC'lerin oyuncuyu beklemesi; mahallelerin yalnızca dekor olması; görsel kalabalığın simülasyonu yavaşlatması başarısızlık sayılır.

## Uygulayıcıya bırakılan kararlar

Godot'un kullanılacak kararlı 4.x sürümü, renderer ve dışa aktarma aracı kurulum incelemesinde seçilir. Dizinler, kaynak sınıfları, test aracı, örnek isimler, ilk harita geometrisi, geçici sanat ve başlangıç denge sayıları planı hazırlayanın kararıdır. Yeni bağımlılık yalnızca somut ihtiyaçla eklenir. Mevcut klasörde oyun projesi veya Git deposu yoktur; şu anda .agents ve .specify klasörleri bulunur. Bu belge henüz commit edilmemiştir.
