import AVFoundation
import UIKit

/// Kayıt sırasında toplanan event log'dan (Bölüm 9, adım 2) bir `CALayer`
/// hiyerarşisi üretir. Bu katman `VideoExporter` tarafından
/// `AVVideoCompositionCoreAnimationTool` ile videoya "yakılır".
///
/// Canlı ekranda gördüğün arayüzle (oyuncu renkleri, ilerleme/şık bilgisi)
/// videoya yakılanın BİREBİR aynı görünmesi hedefleniyor — kartların rengi
/// `playerIndex`e göre (Oyuncu 1 = indigo, Oyuncu 2 = turuncu, tek kişilik =
/// nötr siyah) `PredictionOverlayView`/`ThisOrThatOverlayView`'daki
/// `turnBanner` rengiyle aynı paleti kullanıyor.
///
/// BİLİNEN RİSK (teknik prompt Bölüm 9 + playbook Bölüm 3'teki CIImage/UIKit
/// orijin sorunuyla aynı sınıf hata): burada kullanılan "üstten-orijin, normal
/// frame koordinatları" deseni (`CALayer` sublayer'ları `postProcessingAsVideoLayer`
/// parent'ına normal top-left frame'lerle eklemek) yaygın, çalıştığı bilinen bir
/// desendir — ama bu projede gerçek cihazda DOĞRULANMADI. Bölüm 13 Adım 7'de
/// tek bir statik metin overlay'iyle gerçek kayıt alıp overlay'in ekranın
/// beklenen bölgesinde (üst/orta/alt) çıktığını bizzat kontrol et. Ters çıkarsa
/// önce hangi eksenin ters olduğunu (Y mi, X mi) net biçimde tespit et, sonra
/// düzelt — rastgele deneme yapma (playbook Bölüm 5).
enum OverlayCompositionBuilder {

    /// - Parameters:
    ///   - events: Kayıt sırasında toplanan, kayıt başlangıcına göre zaman damgalı olaylar.
    ///   - totalDuration: Videonun toplam süresi (saniye) — son event'in ne zaman kaybolacağını belirler.
    ///   - renderSize: Composition'ın piksel boyutu (preferredTransform uygulanmış natural size).
    ///   - watermarkText: Köşedeki filigranda gösterilecek metin — kullanıcı Ayarlar'dan kendi
    ///     rumuzunu girdiyse onu, girmediyse varsayılan "⚡ Duello" markasını taşır
    ///     (bkz. `AppState.creatorHandle`). Boş string verilmesi durumunda çağıran taraf
    ///     zaten varsayılanı doldurmuş olmalı — burada tekrar dile göre seçim YAPILMAZ
    ///     (export zamanının `Locale` erişimi yok, bkz. dosya başı NOT).
    static func buildOverlayLayer(
        events: [OverlayEvent],
        totalDuration: TimeInterval,
        renderSize: CGSize,
        watermarkText: String
    ) -> CALayer {
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: renderSize)
        overlayLayer.masksToBounds = true

        let sortedEvents = events.sorted { $0.timestamp < $1.timestamp }

        for (index, event) in sortedEvents.enumerated() {
            let start = event.timestamp
            let end = index + 1 < sortedEvents.count ? sortedEvents[index + 1].timestamp : totalDuration
            let duration = max(end - start, 0.05)

            guard let content = OverlayContent(kind: event.kind) else {
                continue // .hideAll — bir sonraki event'e kadar overlay boş kalır
            }

            let card = makeCardLayer(content: content, renderSize: renderSize)
            applyVisibility(to: card, start: start, duration: duration)
            overlayLayer.addSublayer(card)
        }

        overlayLayer.addSublayer(makeWatermarkLayer(text: watermarkText, renderSize: renderSize))

        return overlayLayer
    }

    /// `start`/`duration` aralığında opaklık 0→1→0 ve hafif bir "pop" (0.85→1 ölçek)
    /// uygulayan, export'un MUTLAK zaman modeline (`AVCoreAnimationBeginTimeAtZero`
    /// ofseti) bağlı bir animasyon. Bu ofseti unutmak, Core Animation'ın canlı-UI
    /// zaman modeliyle export zaman modelinin senkronize OLMAMASININ en yaygın sebebidir.
    private static func applyVisibility(to layer: CALayer, start: TimeInterval, duration: TimeInterval) {
        layer.opacity = 0
        layer.transform = CATransform3DMakeScale(0.85, 0.85, 1)

        let appearDuration = min(0.28, duration / 2)
        let disappearDuration = min(0.2, duration / 2)
        let popTiming = CAMediaTimingFunction(name: .easeOut)

        let appearOpacity = CABasicAnimation(keyPath: "opacity")
        appearOpacity.fromValue = 0
        appearOpacity.toValue = 1
        appearOpacity.duration = appearDuration
        appearOpacity.beginTime = AVCoreAnimationBeginTimeAtZero + start
        appearOpacity.fillMode = .forwards
        appearOpacity.isRemovedOnCompletion = false

        let appearScale = CABasicAnimation(keyPath: "transform.scale")
        appearScale.fromValue = 0.85
        appearScale.toValue = 1.0
        appearScale.duration = appearDuration
        appearScale.timingFunction = popTiming
        appearScale.beginTime = AVCoreAnimationBeginTimeAtZero + start
        appearScale.fillMode = .forwards
        appearScale.isRemovedOnCompletion = false

        let disappearOpacity = CABasicAnimation(keyPath: "opacity")
        disappearOpacity.fromValue = 1
        disappearOpacity.toValue = 0
        disappearOpacity.duration = disappearDuration
        disappearOpacity.beginTime = AVCoreAnimationBeginTimeAtZero + start + duration - disappearDuration
        disappearOpacity.fillMode = .forwards
        disappearOpacity.isRemovedOnCompletion = false

        layer.add(appearOpacity, forKey: "appearOpacity")
        layer.add(appearScale, forKey: "appearScale")
        layer.add(disappearOpacity, forKey: "disappear")
    }

    private static func makeCardLayer(content: OverlayContent, renderSize: CGSize) -> CALayer {
        let container = CALayer()
        let width = renderSize.width * 0.88
        let cardHeight: CGFloat = renderSize.height * content.heightRatio
        container.frame = CGRect(
            x: (renderSize.width - width) / 2,
            y: content.verticalAnchor.yOrigin(renderSize: renderSize, cardHeight: cardHeight),
            width: width,
            height: cardHeight
        )
        container.shadowColor = UIColor.black.cgColor
        container.shadowOpacity = 0.32
        container.shadowRadius = 18
        container.shadowOffset = CGSize(width: 0, height: 10)

        let shape = CAShapeLayer()
        shape.frame = container.bounds
        shape.path = UIBezierPath(roundedRect: container.bounds, cornerRadius: 28).cgPath

        let gradient = CAGradientLayer()
        gradient.frame = container.bounds
        gradient.colors = content.gradientColors.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.mask = shape
        container.addSublayer(gradient)

        let border = CAShapeLayer()
        border.frame = container.bounds
        border.path = UIBezierPath(roundedRect: container.bounds.insetBy(dx: 0.75, dy: 0.75), cornerRadius: 28).cgPath
        border.fillColor = UIColor.clear.cgColor
        border.strokeColor = UIColor.white.withAlphaComponent(0.28).cgColor
        border.lineWidth = 1.5
        container.addSublayer(border)

        let text = CATextLayer()
        // CATextLayer dikeyde kendiliğinden ortalamıyor (UIKit'in NSAttributedString
        // vertical centering'iyle karıştırılmamalı) — bu yüzden container'ı text'in
        // gerçek yüksekliğine göre biraz büyük tutup, insetBy ile görsel olarak
        // ortalamaya yakın bir yerleşim hedefliyoruz. Tam dikey merkezleme
        // gerekiyorsa font yüksekliğine göre dinamik inset hesaplanabilir (v2).
        text.frame = container.bounds.insetBy(dx: 26, dy: cardHeight * 0.1)
        text.string = content.text
        text.foregroundColor = content.textColor.cgColor
        text.alignmentMode = .center
        text.isWrapped = true
        text.truncationMode = .end
        text.contentsScale = UIScreen.main.scale
        text.font = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, 0, nil)
        text.fontSize = content.fontSize
        text.shadowColor = UIColor.black.cgColor
        text.shadowOpacity = 0.25
        text.shadowRadius = 3
        text.shadowOffset = CGSize(width: 0, height: 1)
        container.addSublayer(text)

        return container
    }

    /// Videonun tamamında sabit kalan, küçük ve göze batmayan marka/rumuz rozeti —
    /// paylaşılan videonun nereden geldiğini belli eder (organik keşif/viral döngü),
    /// ya da kullanıcı kendi rumuzunu girdiyse onu taşır.
    private static func makeWatermarkLayer(text watermarkText: String, renderSize: CGSize) -> CALayer {
        let width: CGFloat = renderSize.width * 0.4
        let height: CGFloat = renderSize.height * 0.032
        let container = CALayer()
        container.frame = CGRect(
            x: renderSize.width - width - renderSize.width * 0.04,
            y: renderSize.height - height - renderSize.height * 0.045,
            width: width,
            height: height
        )
        container.opacity = 0.85

        let background = CAShapeLayer()
        background.frame = container.bounds
        background.path = UIBezierPath(roundedRect: container.bounds, cornerRadius: container.bounds.height / 2).cgPath
        background.fillColor = UIColor.black.withAlphaComponent(0.4).cgColor
        container.addSublayer(background)

        let text = CATextLayer()
        text.frame = container.bounds
        text.string = watermarkText
        text.foregroundColor = UIColor.white.withAlphaComponent(0.9).cgColor
        text.alignmentMode = .center
        text.truncationMode = .end
        text.contentsScale = UIScreen.main.scale
        text.font = CTFontCreateWithName("HelveticaNeue-Semibold" as CFString, 0, nil)
        text.fontSize = height * 0.42
        container.addSublayer(text)

        return container
    }
}

/// Canlı ekranda oyuncu 1/2'yi ayırt eden renkler — `PredictionOverlayView`/
/// `ThisOrThatOverlayView`'daki `currentPlayerColor` ile AYNI palet (indigo/turuncu).
/// Videoya yakılan kartların canlı ekranla renk açısından da birebir eşleşmesi için.
private enum PlayerPalette {
    static func gradient(for playerIndex: Int?) -> [UIColor] {
        switch playerIndex {
        case 0: return [UIColor.systemIndigo, UIColor(red: 0.30, green: 0.20, blue: 0.75, alpha: 1)]
        case 1: return [UIColor.systemOrange, UIColor(red: 0.85, green: 0.45, blue: 0.05, alpha: 1)]
        default: return [UIColor.black.withAlphaComponent(0.82), UIColor.black.withAlphaComponent(0.62)]
        }
    }
}

/// Bir `OverlayEventKind`'ı ekranda gösterilecek metne/renge/konuma çevirir.
private struct OverlayContent {
    let text: String
    let gradientColors: [UIColor]
    let textColor: UIColor
    let fontSize: CGFloat
    let heightRatio: CGFloat
    let verticalAnchor: VerticalAnchor

    enum VerticalAnchor {
        case top, center, bottom

        func yOrigin(renderSize: CGSize, cardHeight: CGFloat) -> CGFloat {
            switch self {
            case .top: return renderSize.height * 0.09
            case .center: return (renderSize.height - cardHeight) / 2
            case .bottom: return renderSize.height * 0.80 - cardHeight
            }
        }
    }

    init?(kind: OverlayEventKind) {
        switch kind {
        case .showIntro(let introText):
            text = introText
            gradientColors = [UIColor.systemIndigo, UIColor(red: 0.55, green: 0.25, blue: 0.85, alpha: 1)]
            textColor = .white
            fontSize = 44
            heightRatio = 0.22
            verticalAnchor = .center
        case .showPrompt(let promptText, let playerIndex):
            text = promptText
            gradientColors = PlayerPalette.gradient(for: playerIndex)
            textColor = .white
            fontSize = 34
            heightRatio = 0.17
            verticalAnchor = .top
        case .showChoices(let choicesText, let playerIndex):
            text = choicesText
            gradientColors = PlayerPalette.gradient(for: playerIndex)
            textColor = .white
            fontSize = 24
            heightRatio = 0.16
            verticalAnchor = .bottom
        case .showAnswer(let answerText, let playerIndex):
            text = answerText
            gradientColors = playerIndex != nil
                ? PlayerPalette.gradient(for: playerIndex)
                : [UIColor.systemGreen, UIColor(red: 0.05, green: 0.55, blue: 0.35, alpha: 1)]
            textColor = .white
            fontSize = 42
            heightRatio = 0.22
            verticalAnchor = .center
        case .showTurn(let turnText, let playerIndex):
            text = turnText
            gradientColors = PlayerPalette.gradient(for: playerIndex)
            textColor = .white
            fontSize = 29
            heightRatio = 0.10
            verticalAnchor = .top
        case .showPick(let pickText, let playerIndex):
            text = pickText
            gradientColors = playerIndex != nil
                ? PlayerPalette.gradient(for: playerIndex)
                : [UIColor.systemBlue, UIColor(red: 0.25, green: 0.35, blue: 0.9, alpha: 1)]
            textColor = .white
            fontSize = 30
            heightRatio = 0.12
            verticalAnchor = .bottom
        case .showResult(let resultText, let playerIndex):
            text = resultText
            gradientColors = playerIndex != nil
                ? PlayerPalette.gradient(for: playerIndex)
                : [UIColor.systemOrange, UIColor(red: 0.85, green: 0.25, blue: 0.35, alpha: 1)]
            textColor = .white
            fontSize = 36
            heightRatio = 0.28
            verticalAnchor = .center
        case .hideAll:
            return nil
        }
    }
}
