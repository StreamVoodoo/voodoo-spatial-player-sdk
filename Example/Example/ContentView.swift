import SwiftUI
import VoodooSpatialPlayer

struct ContentView: View {
    @State private var userId = "" //Use your user id
    @State private var player = VoodooPlayer()

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("UserId", text: $userId)
                .textFieldStyle(.roundedBorder)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1 ..< 11) { streamId in
                    Button(action: {
                        do {
                            try player.load(userId: userId, streamId: "\(streamId)", showPreview: true)
                        }catch {
                            print(error.localizedDescription)
                        }
                    }) {
                        Text("\(streamId)")
                            .foregroundStyle(Color(uiColor: .label))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
            }
        }
        .padding(50)
        .voodooPlayer(player)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
