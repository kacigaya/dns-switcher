import Foundation

extension DnsProfile {
    static let maxNameLength = 50

    /// Why a profile cannot be saved. Also used to discard corrupt profiles
    /// when they are read back from disk.
    enum ValidationError: Error, Equatable {
        case emptyName
        case nameTooLong(maximum: Int)
        case noServers
        case invalidServer(String)

        var message: String {
            switch self {
            case .emptyName:
                "Profile name cannot be empty."
            case .nameTooLong(let maximum):
                "Profile name must be \(maximum) characters or fewer."
            case .noServers:
                "At least one DNS server is required."
            case .invalidServer(let server):
                "\"\(server)\" is not a valid IPv4 or IPv6 address."
            }
        }
    }

    /// Splits user input into DNS servers. Commas, spaces, and newlines all
    /// separate entries, so pasted lists work regardless of formatting.
    static func parseServers(_ text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet(charactersIn: ",").union(.whitespacesAndNewlines))
            .filter { !$0.isEmpty }
    }

    /// The first problem preventing this profile from being used, if any.
    var validationError: ValidationError? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return .emptyName
        }

        if trimmedName.count > Self.maxNameLength {
            return .nameTooLong(maximum: Self.maxNameLength)
        }

        if servers.isEmpty {
            return .noServers
        }

        if let invalid = servers.first(where: { !IPAddress.isValid($0) }) {
            return .invalidServer(invalid)
        }

        return nil
    }

    var isValid: Bool {
        validationError == nil
    }
}
