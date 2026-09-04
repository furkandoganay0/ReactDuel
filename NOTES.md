# Duello — Handoff Notları

Bu proje, `DUELLO_TEKNIK_PROMPT.md` ve `IOS_APP_PLAYBOOK.md`'ye göre, **Xcode/macOS
olmayan bir ortamda** (Linux sandbox, Claude Code değil) yazıldı. Aşağıdakiler
**hiç derlenmedi/çalıştırılmadı** — ilk gerçek build senin tarafından yapılmalı.

## İlk adımlar

1. `brew install xcodegen` (yoksa) → proje kökünde `xcodegen generate`
2. Xcode'da `Duello.xcodeproj`'u aç, **Signing & Capabilities**'den kendi
   Development Team'ini seç (`project.yml`'de bilinçli olarak boş bırakıldı —
   playbook Bölüm 4: bu adım CLI/XcodeGen ile headless yapılamıyor).
3. Gerçek bir iPhone'a bağla ve çalıştır — **Simulator kamera akışı vermez**,
   bu proje kamera/kayıt ağırlıklı olduğu için gerçek cihaz şart.
4. `xcodebuild test` ya da Xcode'da ⌘U ile `DuelloTests`'i çalıştır.

## En riskli nokta — Bölüm 9 overlay burn-in (mutlaka gerçek cihazda doğrula)

`Duello/Video/OverlayCompositionBuilder.swift` + `VideoExporter.swift`, ham
kaydı overlay'siz alıp `AVMutableComposition` + `CALayer` +
`AVVideoCompositionCoreAnimationTool` ile videoya "yakıyor". Kod, yaygın/bilinen
çalışan bir Apple deseni izliyor (top-left origin sublayer'lar,
`AVCoreAnimationBeginTimeAtZero` ofsetli mutlak zamanlı `CABasicAnimation`,
`preferredTransform` uygulanmış render boyutu) — **ama hiç gerçek cihazda test
edilmedi**. Tek bir statik metin overlay'iyle kısa bir kayıt al, çıktı MP4'te:

- Overlay'in beklenen yerde (üst/orta/alt) çıktığını,
- Zamanlamanın (prompt → reveal geçişi, pick/turn/result kartları) canlı
  önizlemeyle eşleştiğini,
- Yönün (dikey/portre) doğru olduğunu (90° ters çıkarsa `preferredTransform`
  hesaplaması şüpheli)

bizzat kontrol et. Ters bir şey çıkarsa playbook Bölüm 5'teki gibi davran:
rastgele deneme yapma, hangi eksenin/aşamanın ters olduğunu netleştiren bir
regresyon testi/debug adımı ile ilerle.

## Bilinen varsayımlar (Xcode olmadan doğrulanamadı)

- **DuelloTests host application**: `ContentLoaderTests`, bundle kaynaklı JSON
  yükleme testleri içeriyor. `ContentLoader.duelloModule` (`Bundle(for:)`
  tabanlı) kullanılıyor — bu, DuelloTests'in Duello uygulamasına "host" olarak
  bağlı olduğu standart XcodeGen/Xcode kurulumunda doğru çalışır
  (`project.yml`'deki `dependencies: [{target: Duello}]` bunu genelde otomatik
  kurar). İlk `xcodegen generate` + test çalıştırmasında `ContentLoaderTests`
  gerçekten geçiyor mu kontrol et; geçmezse Target → Build Settings'te
  `TEST_HOST`/`BUNDLE_LOADER`'ın Duello'yu gösterdiğini doğrula.
- **Info.plist / sources çakışması**: `Duello/Info.plist`, hem `info.path`
  (XcodeGen'in ürettiği dosya) hem de `sources: [{path: Duello}]` klasör
  taramasının içinde. XcodeGen bunu normalde otomatik hariç tutuyor; ilk build'de
  "multiple commands produce Info.plist" hatası çıkarsa `sources` altına
  `excludes: ["Info.plist"]` ekle.
- **Bundle ID**: `com.reactduel.app` olarak sabitlendi (`com.duello.app`
  Apple Developer'da zaten alınmış çıktığı için değiştirildi; henüz App Store
  Connect'e hiç gönderilmedi). İlk gönderimden SONRA bunu asla değiştirme
  (playbook Bölüm 1).

## İçerik durumu (Bölüm 14'teki açık soru)

- Metin/veri: **gerçek** (futbolcu/film isimleri, ipuçları, elle küratörlü
  `cost` değerleri) — `content_tr.json` / `content_en.json`, 2 tahmin + 2 draft
  paketi.
- Görseller: **placeholder**. `PlaceholderCoverView`, `imageName` bundle'da
  gerçekten varsa onu gösteriyor, yoksa isimden renk+baş harf üretiyor. Gerçek
  fotoğraf/afiş eklemek istersen sadece Assets.xcassets'e aynı isimle asset
  eklemen yeterli — kod değişikliği gerekmiyor. (Not: gerçek kişi/film
  görselleri lisans/telif riski taşır, playbook Bölüm 7.)

## Bilinçli basitleştirmeler

- **Draft kayıt ekranında "köşe PIP kamera"** (Bölüm 7.4'teki öneri) yerine
  kamera her zaman tam ekran kalıyor, pick onayı ekranın alt yarısını kaplayan
  yarı saydam bir kart olarak açılıyor — aynı ürün amacına (seçim anındaki
  tepkinin kadrajda kalması) daha az animasyon-state riskiyle ulaşıyor. Gerçek
  cihazda denedikten sonra köşe-PIP'e geçmek istersen `DraftRecordingView`'daki
  yorum bunu işaretliyor.
- **String Catalog kapsamı kısmi**: `Localizable.xcstrings`, sabit UI
  metinlerinin çoğunu (buton/başlık/durum etiketleri) kapsıyor. Sayı
  interpolasyonu içeren birkaç `Text` (örn. "\(count) soru") ve
  `DraftRecordingView`'daki programatik oyuncu etiketleri ("Oyuncu 1'in sırası")
  henüz katalogda değil — İngilizce'de de Türkçe görünürler. v2 cilası.
- **Onboarding'de izin reddi kurtarma akışı yok**: kullanıcı izni reddederse
  şu an sadece kırmızı "Reddedildi" etiketi gösteriliyor, Ayarlar'a yönlendiren
  bir buton yok. Küçük ama gerçek bir UX eksiği.

## Test kapsamı (yazıldı, hiç çalıştırılmadı)

`DuelloTests/`: `DraftScoreCalculatorTests`, `BudgetValidatorTests`,
`PredictionTimerStateMachineTests`, `DraftStateMachineTests`,
`ContentLoaderTests` — Swift Testing (`@Test`/`#expect`), playbook Bölüm 5'e
uygun. Teknik promptun istediği senaryolar (eşit skor, boş roster, tek item,
bütçe tam kullanılmamış) `DraftScoreCalculatorTests` içinde kapsanıyor.

## Geliştirme sırası — nerede kaldık

Teknik prompt Bölüm 13'ün 1-9. adımları kod olarak yazıldı. 10. adım (uçtan
uca gerçek cihaz testi, overlay zamanlama/okunabilirlik gözden geçirmesi) ve
11. adım (UI cilası) senin elinle, gerçek cihazda yapılmalı — bu ortamda
yapılamayan kısım tam olarak bu.
