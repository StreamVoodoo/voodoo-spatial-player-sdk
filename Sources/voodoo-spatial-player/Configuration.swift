import Foundation

extension VoodooPlayer {
    public struct Configuration: Sendable{
        let host: String
        let cloudHost: String
        let previewPath: String
    }
}

public extension VoodooPlayer.Configuration{
    static let `default`: Self = .init(
        host: "spatial.streamvoodoo.com",
        cloudHost: "voodoospatial-nyc.nyc3.digitaloceanspaces.com",
        previewPath: "/intro/prog_index.m3u8")
}
