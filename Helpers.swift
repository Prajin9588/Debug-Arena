import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    func playSuccess() {
        // Subtle success shimmer
        AudioServicesPlaySystemSound(1052)
    }
}

struct IdentifiableInt: Identifiable {
    let id = UUID()
    let value: Int
}
