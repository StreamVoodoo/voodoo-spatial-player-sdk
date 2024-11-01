import AVKit
import SwiftUI
struct SystemPlayerView: UIViewControllerRepresentable {
    private var player: VoodooPlayer

    let showContextualActions: Bool

    public init(player: VoodooPlayer, showContextualActions: Bool = false) {
        self.showContextualActions = showContextualActions
        self.player = player
    }

    public func makeUIViewController(context _: Context) -> AVPlayerViewController {
        let controller = player.makePlayerUI()
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = true

        return controller
    }

    public func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}

struct PlayerViewModifier: ViewModifier {
    var player: VoodooPlayer

    func body(content: Content) -> some View {
        ZStack {
            content
            if player.isPresented {
                SystemPlayerView(player: player)
            }
        }
    }
}

public extension View {
    func voodooPlayer(_ player: VoodooPlayer) -> some View {
        self.modifier(PlayerViewModifier(player: player))
    }
}
