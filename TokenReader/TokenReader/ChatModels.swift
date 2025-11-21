import SwiftUI
import FoundationModels

enum ChatRole: String, Codable, CaseIterable, Sendable {
    case user
    case assistant
}

struct ChatItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let role: ChatRole
    var text: String
    
    init(role: ChatRole, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
    }
}

struct LiveMetrics: Equatable, Sendable {
    let estimatedInputTokens: Int
    let estimatedOutputTokens: Int
    let snapshotCount: Int
    let timeToFirstSnapshot: TimeInterval?
    let elapsed: TimeInterval
    var isStreaming: Bool
    
    static let empty = LiveMetrics(
        estimatedInputTokens: 0,
        estimatedOutputTokens: 0,
        snapshotCount: 0,
        timeToFirstSnapshot: nil,
        elapsed: 0,
        isStreaming: false
    )
    
    var formattedTTFB: String? {
        guard let ttfb = timeToFirstSnapshot else { return nil }
        return String(format: "%.2f", ttfb)
    }
}

@Generable
struct StreamedReply {
    @Guide(description: "Assistant reply text; update progressively during streaming.")
    var text: String
}
