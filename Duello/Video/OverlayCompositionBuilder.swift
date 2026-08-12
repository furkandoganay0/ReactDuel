import AVFoundation
import UIKit

/// Kayıt sırasında toplanan event log'dan (Bölüm 9, adım 2) bir `CALayer`
/// hiyerarşisi üretir. Bu katman `VideoExporter` tarafından
/// `AVVideoCompositionCoreAnimationTool` ile videoya "yakılır".
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
    static func buildOverlayLayer(
        events: [OverlayEvent],
        totalDuration: TimeInterval,
        renderSize: CGSize
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

        return overlayLayer
    }

    /// `start`/`duration` aralığında opaklığı 0→1→0 yapan, export'un MUTLAK zaman
    /// modeline (`AVCoreAnimationBeginTimeAtZero` ofseti) bağlı bir animasyon uygular.
    /// Bu ofseti unutmak, Core Animation'ın canlı-UI zaman modeliyle export zaman
    /// modelinin senkronize OLMAMASININ en yaygın sebebidir.
    private static func applyVisibility(to layer: CALayer, start: TimeInterval, duration: TimeInterval) {
        layer.opacity = 0

        let appearDuration = min(0.25, duration / 2)
        let disappearDuration = min(0.2, duration / 2)

        let appear = CABasicAnimation(keyPath: "opacity")
        appear.fromValue = 0
        appear.toValue = 1
        appear.duration = appearDuration
        appear.beginTime = AVCoreAnimationBeginTimeAtZero + start
        appear.fillMode = .forwards
        appear.isRemovedOnCompletion = false

        let disappear = CABasicAnimation(keyPath: "opacity")
        disappear.fromValue = 1
        disappear.toValue = 0
        disappear.duration = disappearDuration
        disappear.beginTime = AVCoreAnimationBeginTimeAtZero + start + duration - disappearDuration
        disappear.fillMode = .forwards
        disappear.isRemovedOnCompletion = false

        layer.add(appear, forKey: "appear")
        layer.add(disappear, forKey: "disappear")
    }

    private static func makeCardLayer(content: OverlayContent, renderSize: CGSize) -> CALayer {
        let container = CALayer()
        let width = renderSize.width * 0.86
        let cardHeight: CGFloat = renderSize.height * 0.11
        container.frame = CGRect(
            x: (renderSize.width - width) / 2,
            y: content.verticalAnchor.yOrigin(renderSize: renderSize, cardHeight: cardHeight),
            width: width,
            height: cardHeight
        )

        let background = CAShapeLayer()
        background.frame = container.bounds
        background.path = UIBezierPath(roundedRect: container.bounds, cornerRadius: 20).cgPath
        background.fillColor = content.backgroundColor.cgColor
        container.addSublayer(background)

        let text = CATextLayer()
        // CATextLayer dikeyde kendiliğinden ortalamıyor (UIKit'in NSAttributedString
        // vertical centering'iyle karıştırılmamalı) — bu yüzden container'ı text'in
        // gerçek yüksekliğine göre biraz büyük tutup, insetBy ile görsel olarak
        // ortalamaya yakın bir yerleşim hedefliyoruz. Tam dikey merkezleme
        // gerekiyorsa font yüksekliğine göre dinamik inset hesaplanabilir (v2).
        text.frame = container.bounds.insetBy(dx: 20, dy: cardHeight * 0.22)
        text.string = content.text
        text.foregroundColor = content.textColor.cgColor
        text.alignmentMode = .center
        text.isWrapped = true
        text.truncationMode = .end
        text.contentsScale = UIScreen.main.scale
        text.font = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, 0, nil)
        text.fontSize = content.fontSize
        container.addSublayer(text)

        return container
    }
}

/// Bir `OverlayEventKind`'ı ekranda gösterilecek metne/renge/konuma çevirir.
private struct OverlayContent {
    let text: String
    let backgroundColor: UIColor
    let textColor: UIColor
    let fontSize: CGFloat
    let verticalAnchor: VerticalAnchor

    enum VerticalAnchor {
        case top, center, bottom

        func yOrigin(renderSize: CGSize, cardHeight: CGFloat) -> CGFloat {
            switch self {
            case .top: return renderSize.height * 0.10
            case .center: return (renderSize.height - cardHeight) / 2
            case .bottom: return renderSize.height * 0.80 - cardHeight
            }
        }
    }

    init?(kind: OverlayEventKind) {
        switch kind {
        case .showPrompt(let promptText):
            text = promptText
            backgroundColor = UIColor.black.withAlphaComponent(0.72)
            textColor = .white
            fontSize = 34
            verticalAnchor = .top
        case .showAnswer(let answerText):
            text = answerText
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
            textColor = .white
            fontSize = 40
            verticalAnchor = .center
        case .showTurn(let playerLabel, let budgetRemaining):
            text = "\(playerLabel) • Kalan bütçe: \(budgetRemaining)"
            backgroundColor = UIColor.black.withAlphaComponent(0.72)
            textColor = .white
            fontSize = 28
            verticalAnchor = .top
        case .showPick(let playerLabel, let itemName):
            text = "\(playerLabel): \(itemName)"
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.88)
            textColor = .white
            fontSize = 30
            verticalAnchor = .bottom
        case .showResult(let winnerLabel):
            text = winnerLabel
            backgroundColor = UIColor.systemOrange.withAlphaComponent(0.92)
            textColor = .white
            fontSize = 42
            verticalAnchor = .center
        case .hideAll:
            return nil
        }
    }
}
