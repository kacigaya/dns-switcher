import Foundation
// Required for inet_pton, AF_INET/AF_INET6, and sockaddr types.
import Darwin

/// IPv4/IPv6 parsing helpers backed by `inet_pton`, so validation matches what
/// the networking stack itself accepts.
enum IPAddress {
    static func isValid(_ string: String) -> Bool {
        normalized(string) != nil
    }

    /// The address in binary form, or nil if `string` is not a valid IP address.
    /// Two textually different strings for the same address (for example
    /// `2001:db8::1` and `2001:0db8::1`) normalize to identical data.
    static func normalized(_ string: String) -> Data? {
        string.withCString { cString in
            var ipv4Address = in_addr()
            if inet_pton(AF_INET, cString, &ipv4Address) == 1 {
                return Data(bytes: &ipv4Address, count: MemoryLayout<in_addr>.size)
            }

            var ipv6Address = in6_addr()
            if inet_pton(AF_INET6, cString, &ipv6Address) == 1 {
                return Data(bytes: &ipv6Address, count: MemoryLayout<in6_addr>.size)
            }

            return nil
        }
    }
}
