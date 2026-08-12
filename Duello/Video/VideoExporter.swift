import AVFoundation
import UIKit

enum VideoExportError: Error {
    case noVideoTrack
    case compositionTrackCreationFailed
    case exportSessionCreationFailed
    case exportFailed(Error?)
    case exportCancelled
}

/// Bölüm 9'daki en kritik teknik adım: ham (overlay'siz) kaydı + event log'u alıp,
/// overlay'i `CALayer` olarak videoya "yakan", paylaşıma hazır bir 1080x1920 MP4
/// üreten pipeline. Üçüncü taraf kütüphane (ffmpeg vb.) KULLANILMIYOR — tamamen
/// Apple native `AVFoundation`/`CoreAnimation` (playbook Bölüm 2, minimum bağımlılık).
///
/// NOT: `exportAsynchronously` kasıtlı olarak tercih edildi — daha yeni,
/// parametresiz `async throws export()` API'si iOS 16'da mevcut olmayabilir
/// (Xcode SDK'sı olmadan bu ortamda doğrulanamadı); `exportAsynchronously`
/// iOS 16 deployment target'ıyla kesin uyumlu, uzun süredir stabil API.
enum VideoExporter {

    static func export(
        rawVideoURL: URL,
        overlayEvents: [OverlayEvent],
        outputURL: URL,
        watermarkText: String = "⚡ Duello",
        progressHandler: ((Float) -> Void)? = nil,
        completion: @escaping (Result<URL, VideoExportError>) -> Void
    ) {
        let asset = AVURLAsset(url: rawVideoURL)

        Task {
            do {
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                guard let sourceVideoTrack = videoTracks.first else {
                    await MainActor.run { completion(.failure(.noVideoTrack)) }
                    return
                }

                let composition = AVMutableComposition()
                guard let compositionVideoTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    await MainActor.run { completion(.failure(.compositionTrackCreationFailed)) }
                    return
                }

                let duration = try await asset.load(.duration)
                let timeRange = CMTimeRange(start: .zero, duration: duration)
                try compositionVideoTrack.insertTimeRange(timeRange, of: sourceVideoTrack, at: .zero)

                let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
                compositionVideoTrack.preferredTransform = preferredTransform

                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                if let sourceAudioTrack = audioTracks.first,
                   let compositionAudioTrack = composition.addMutableTrack(
                       withMediaType: .audio,
                       preferredTrackID: kCMPersistentTrackID_Invalid
                   ) {
                    try compositionAudioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: .zero)
                }

                // preferredTransform uygulanmış GERÇEK render boyutu. naturalSize'ı
                // transform'suz kullanmak yatay/dikey ters bir composition üretir —
                // Bölüm 9'daki bilinen risk sınıfının tam burada devreye girdiği yer.
                let naturalSize = try await sourceVideoTrack.load(.naturalSize)
                let transformedRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
                let renderSize = CGSize(width: abs(transformedRect.width), height: abs(transformedRect.height))

                let videoComposition = AVMutableVideoComposition()
                videoComposition.renderSize = renderSize
                videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = timeRange
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                layerInstruction.setTransform(preferredTransform, at: .zero)
                instruction.layerInstructions = [layerInstruction]
                videoComposition.instructions = [instruction]

                let videoLayer = CALayer()
                videoLayer.frame = CGRect(origin: .zero, size: renderSize)

                let overlayLayer = OverlayCompositionBuilder.buildOverlayLayer(
                    events: overlayEvents,
                    totalDuration: CMTimeGetSeconds(duration),
                    renderSize: renderSize,
                    watermarkText: watermarkText
                )

                let parentLayer = CALayer()
                parentLayer.frame = CGRect(origin: .zero, size: renderSize)
                parentLayer.addSublayer(videoLayer)
                parentLayer.addSublayer(overlayLayer)

                videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
                    postProcessingAsVideoLayer: videoLayer,
                    in: parentLayer
                )

                guard let exportSession = AVAssetExportSession(
                    asset: composition,
                    presetName: AVAssetExportPresetHighestQuality
                ) else {
                    await MainActor.run { completion(.failure(.exportSessionCreationFailed)) }
                    return
                }
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mp4
                exportSession.videoComposition = videoComposition

                if FileManager.default.fileExists(atPath: outputURL.path) {
                    try? FileManager.default.removeItem(at: outputURL)
                }

                let progressTimer = DispatchSource.makeTimerSource(queue: .main)
                progressTimer.schedule(deadline: .now(), repeating: 0.2)
                progressTimer.setEventHandler { [weak exportSession] in
                    guard let exportSession else { return }
                    progressHandler?(exportSession.progress)
                }
                progressTimer.resume()

                exportSession.exportAsynchronously {
                    progressTimer.cancel()
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            completion(.success(outputURL))
                        case .cancelled:
                            completion(.failure(.exportCancelled))
                        default:
                            completion(.failure(.exportFailed(exportSession.error)))
                        }
                    }
                }
            } catch {
                await MainActor.run { completion(.failure(.exportFailed(error))) }
            }
        }
    }

    /// Standart çıktı konumu: her export öncesi temizlenen, uygulamanın kendi
    /// temp klasöründeki tek bir dosya adı.
    static func makeOutputURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("duello-export-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
    }
}
