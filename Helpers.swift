import Foundation

struct IdentifiableInt: Identifiable {
    let id = UUID()
    let value: Int
}
