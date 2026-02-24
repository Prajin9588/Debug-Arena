import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    func playCoinScatter() {
        // Subtle coin scatter shimmer
        // Using Tink system sound (1052) for a light metallic effect as requested
        AudioServicesPlaySystemSound(1052)
    }
}

struct IdentifiableInt: Identifiable {
    let id = UUID()
    let value: Int
}
