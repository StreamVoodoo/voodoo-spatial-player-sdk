# VoodooSpatialPlayer

`VoodooSpatialPlayer` is a Swift package for video streaming playback,.

## Installation

Add `VoodooSpatialPlayer` to your project via Swift Package Manager.

```swift
dependencies: [
    .package(url: "https://github.com/StreamVoodoo/voodoo-spatial-player-sdk", from: "1.0.0")
]
```

## Usage

### Initialization

Create a `VoodooPlayer` instance and load a `Stream`:

```swift
import VoodooSpatialPlayer

let player = VoodooPlayer(configuration: .default)

```

### SwiftUI Integration

Use the `.voodooPlayer()` modifier in your SwiftUI view:

```swift
import SwiftUI

struct ContentView: View {
    @State private var player = VoodooPlayer()

    var body: some View {
        Button("Play Stream") {
            try? player.load(userId: "UserId", streamId: "StreamId", showPreview: true)
        }
        .voodooPlayer(player)
    }
}
```

### Playback Controls

```swift
player.play()
player.pause()
```
