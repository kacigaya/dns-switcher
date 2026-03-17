import Foundation

struct DnsProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var servers: [String]

    init(id: UUID = UUID(), name: String, servers: [String]) {
        self.id = id
        self.name = name
        self.servers = servers
    }

    static let defaults: [DnsProfile] = [
        DnsProfile(name: "Cloudflare", servers: ["1.1.1.1", "1.0.0.1"]),
        DnsProfile(name: "Quad9", servers: ["9.9.9.9", "149.112.112.112"]),
        DnsProfile(name: "AdGuard", servers: ["94.140.14.14", "94.140.15.15"]),
    ]
}
