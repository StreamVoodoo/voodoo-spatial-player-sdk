import AVFoundation
import AVKit
import GroupActivities
import os
import SwiftUI

@MainActor @Observable public final class VoodooPlayer {
    private(set) var isPresented = false
    private(set) var isPlaying = false
    private(set) var isPlaybackComplete = false
    private(set) var currentItem: URL?

    private var player: AVPlayer
    private var playerUI: AnyObject?
    private var playerUIDelegate: AnyObject?

    private(set) var shouldAutoPlay = false
    private var shouldVideoLoop = false

    private var playerObservationToken: NSKeyValueObservation?
    private var streamAvailableObservationTask: Task<Void, Never>?

    private let configuration: VoodooPlayer.Configuration

    public init(configuration: VoodooPlayer.Configuration = .default) {
        self.configuration = configuration
        self.player = AVPlayer()

        observePlayback()
        configureAudioSession()
    }

    public func load(userId: String, streamId: String, showPreview: Bool = false) throws {
        guard !userId.isEmpty else { throw VoodooPlayerError.wrongUserId }
        let streamURL = "https://\(configuration.host)/live2/\(userId)/\(streamId)"
        let previewURL = "https://\(configuration.cloudHost)\(configuration.previewPath)"
        
        let stream = try VoodooPlayer.Stream(
            url: URL(string: streamURL)!,
            placeholderUrl: showPreview ? URL(string: previewURL) : nil
        )
        
        load(stream: stream)
    }
    public func load(stream: Stream, autoplay _: Bool = false) {
        if let placeholder = stream.placeholderUrl {
            shouldAutoPlay = true
            shouldVideoLoop = true
            streamAvailableObservationTask = Task {
                try! await observeStreamAvailability(stream: stream)
            }
            load(url: placeholder)

        } else {
            load(url: stream.url)
        }

        isPresented = true
    }

    private func load(url: URL) {
        isPlaybackComplete = false
        currentItem = url
        replaceCurrentItem(with: url)

        configureAudioExperience()
    }

    public func play() {
        player.play()
    }

    public func pause() {
        player.pause()
    }

    public func togglePlayback() {
        player.timeControlStatus == .paused ? play() : pause()
    }

    func makePlayerUI() -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player

        playerUI = controller

        #if os(visionOS)
            @MainActor
            class PlayerViewObserver: NSObject, AVPlayerViewControllerDelegate {
                private var continuation: CheckedContinuation<Void, Never>?

                func willEndFullScreenPresentation() async {
                    await withCheckedContinuation {
                        continuation = $0
                    }
                }

                nonisolated func playerViewController(
                    _: AVPlayerViewController,
                    willEndFullScreenPresentationWithAnimationCoordinator _: any UIViewControllerTransitionCoordinator
                ) {
                    Task { @MainActor in
                        continuation?.resume()
                    }
                }
            }

            let observer = PlayerViewObserver()
            controller.delegate = observer
            playerUIDelegate = observer

            Task {
                await observer.willEndFullScreenPresentation()
                reset()
            }
        #endif

        return controller
    }

    private func observeStreamAvailability(stream: Stream) async throws {
        while !Task.isCancelled {
            logger.debug("Checking live stream availability...")

            do {
                let checkingURL = stream.url

                var request = URLRequest(url: checkingURL)
                request.httpMethod = "HEAD"
                let response = try await URLSession.shared.data(for: request)
                if let httpResponse = response.1 as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    shouldAutoPlay = true
                    load(url: checkingURL)
                    return
                } else {
                    logger.debug("Live stream not available yet. Checking again in 1 second.")
                    print()
                }
            } catch {
                logger.error("Error checking live stream:")
            }
            try await Task.sleep(for: .seconds(1))
        }
    }

    private func observePlayback() {
        // Return early if the model calls this more than once.
        guard playerObservationToken == nil else { return }

        // Observe the time control status to determine whether playback is active.
        playerObservationToken = player.observe(\.timeControlStatus) { observed, _ in
            Task { @MainActor [weak self] in
                self?.isPlaying = observed.timeControlStatus == .playing
            }
        }

        let center = NotificationCenter.default

        // Observe this notification to identify when a video plays to its end.
        Task {
            for await _ in center.notifications(named: .AVPlayerItemDidPlayToEndTime) {
                isPlaybackComplete = true
                if shouldVideoLoop {
                    await player.seek(to: CMTime.zero)
                    await player.play()
                }
            }
        }

        #if !os(macOS)
            // Observe audio session interruptions.
            Task {
                for await notification in center.notifications(named: AVAudioSession.interruptionNotification) {
                    guard let result = InterruptionResult(notification) else { continue }
                    // Resume playback, if appropriate.
                    if result.type == .ended, result.options == .shouldResume {
                        player.play()
                    }
                }
            }
        #endif
    }

    private func configureAudioSession() {
        #if !os(macOS)
            let session = AVAudioSession.sharedInstance()
            do {
                // Configure the audio session for playback. Set the `moviePlayback` mode
                // to reduce the audio's dynamic range to help normalize audio levels.
                try session.setCategory(.playback, mode: .moviePlayback)
            } catch {
                logger.error("Unable to configure audio session: \(error.localizedDescription)")
            }
        #endif
    }

    private func configureAudioExperience() {
        #if os(visionOS)
            do {
                let experience: AVAudioSessionSpatialExperience
                experience = .headTracked(soundStageSize: .large, anchoringStrategy: .automatic)
                try AVAudioSession.sharedInstance().setIntendedSpatialExperience(experience)
            } catch {
                logger.error("Unable to set the intended spatial experience. \(error.localizedDescription)")
            }
        #endif
    }

    private func replaceCurrentItem(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredForwardBufferDuration = 1

        player.replaceCurrentItem(with: playerItem)

        if shouldAutoPlay {
            player.play()
        }
    }

    private func reset() {
        currentItem = nil
        player.replaceCurrentItem(with: nil)
        playerUI = nil
        playerUIDelegate = nil
        streamAvailableObservationTask = nil
        isPresented = false
    }
}

extension Notification: @unchecked Sendable {}

#if !os(macOS)
    // A type that unpacks the relevant values from an `AVAudioSession` interruption event.
    struct InterruptionResult {
        let type: AVAudioSession.InterruptionType
        let options: AVAudioSession.InterruptionOptions

        init?(_ notification: Notification) {
            // Determine the interruption type and options.
            guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType,
                  let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? AVAudioSession.InterruptionOptions
            else {
                return nil
            }
            self.type = type
            self.options = options
        }
    }
#endif

let logger = Logger()
