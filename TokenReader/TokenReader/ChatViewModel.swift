import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
    var items: [ChatItem] = []
    var composing: String = ""
    var liveMetrics: LiveMetrics = .empty

    private let service = ChatService()
    private var streamingTask: Task<Void, Never>?

    func send() {
        let prompt = composing.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        items.append(ChatItem(role: .user, text: prompt))
        composing = ""

        streamingTask?.cancel()

        streamingTask = Task { [weak self] in
            guard let self = self else { return }
            self.liveMetrics.isStreaming = true
            // Append placeholder assistant item and get its index
            let assistantIndex = self.items.count
            self.items.append(ChatItem(role: .assistant, text: ""))

            do {
                for try await (partial, metrics) in await self.service.streamReply(for: prompt) {
                    try Task.checkCancellation()
                    self.items[assistantIndex].text = partial.text
                    self.liveMetrics = metrics
                }
                self.liveMetrics.isStreaming = false
            } catch {
                // Handle cancellation silently
                if (error as? CancellationError) == nil {
                    // Handle other errors if needed
                }
                self.liveMetrics.isStreaming = false
            }
        }
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        liveMetrics.isStreaming = false
    }

    func reset() {
        items = []
        liveMetrics = .empty
        cancelStreaming()
    }
}
