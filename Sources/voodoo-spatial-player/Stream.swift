import Foundation

public extension VoodooPlayer {
    struct Stream {
        enum StreamType: String {
            case live
            case live2
            case vod
        }

        let id: String
        let userId: String
        let url: URL
        let placeholderUrl: URL?

        public init(url: URL, placeholderUrl: URL? = nil, configuaration: VoodooPlayer.Configuration = .default) throws {
            guard let (type, userId, streamId) = Self.parseURL(url, configuaration: configuaration) else {
                throw VoodooPlayerError.invalidStreamURL
            }

            self.id = streamId
            self.userId = userId
            self.url = Self.constructStreamURL(type: type, userId: userId, streamId: streamId, configuaration: configuaration)
            self.placeholderUrl = placeholderUrl
        }
    }
}

extension VoodooPlayer.Stream {
    private static func parseURL(_ url: URL, configuaration: VoodooPlayer.Configuration) -> (type: StreamType, userId: String, streamId: String)? {
        guard url.host == configuaration.host,
              url.pathComponents.count == 4,
              let type = try? StreamType(rawValue: url.pathComponents[1]) else { return nil }

        let userId = url.pathComponents[2]
        let streamId = url.pathComponents[3]

        return (type, userId, streamId)
    }

    private static func constructStreamURL(type: StreamType, userId: String, streamId: String, configuaration: VoodooPlayer.Configuration) -> URL {
        var newURLString: String

        switch type {
        case .live:
            newURLString = "https://\(configuaration.cloudHost)/\(userId)/\(streamId)/prog_index.m3u8"
        case .live2:
            newURLString = "https://\(configuaration.host)/api/stream/\(userId)/\(streamId)"
        case .vod:
            newURLString = "https://\(configuaration.host))/api/vod/\(userId)/\(streamId)"
        }

        return URL(string: newURLString)!
    }
}
