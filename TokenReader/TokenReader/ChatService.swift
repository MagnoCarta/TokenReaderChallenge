import Foundation
import FoundationModels

actor ChatService {
  private let session: LanguageModelSession

  init() {
    self.session = .init()
  }

  nonisolated static func roughTokenEstimate(for text: String) -> Int {
    // Very rough rule-of-thumb: ~4 chars per token in English-ish text
    max(0, Int(ceil(Double(text.count) / 4.0)))
  }

  func streamReply(
    for prompt: String
  ) -> AsyncThrowingStream<(partial: StreamedReply, metrics: LiveMetrics), Error> {
    AsyncThrowingStream { continuation in
      Task {
        let start = CFAbsoluteTimeGetCurrent()

        let promptText = #"""
          You are a helpful assistant. Respond clearly and succinctly.

          User: \#(prompt)
          """#
        let prompt = Prompt(promptText)

        let options = GenerationOptions(temperature: 0.7, maximumResponseTokens: 256)

        var snapshots = 0
        var ttfb: TimeInterval? = nil
        var lastReply: StreamedReply? = nil
        var lastOutputTokens: Int = 0

        do {
          let stream = session.streamResponse(
            to: prompt,
            generating: StreamedReply.self,
            includeSchemaInPrompt: true,
            options: options
          )

          let inputTokens = Self.roughTokenEstimate(for: promptText)

          for try await snapshot in stream {
            snapshots += 1

            let now = CFAbsoluteTimeGetCurrent()

            if ttfb == nil {
              ttfb = now - start
            }

            let elapsed = now - start
            let reply = StreamedReply(text: snapshot.content.text ?? "")
            let outputTokens = Self.roughTokenEstimate(for: reply.text)
            lastOutputTokens = outputTokens
            lastReply = reply

            let metrics = LiveMetrics(
              estimatedInputTokens: inputTokens,
              estimatedOutputTokens: outputTokens,
              snapshotCount: snapshots,
              timeToFirstSnapshot: ttfb ?? 0,
              elapsed: elapsed,
              isStreaming: true
            )

            continuation.yield((reply, metrics))
          }

          let finalMetrics = LiveMetrics(
            estimatedInputTokens: Self.roughTokenEstimate(for: promptText),
            estimatedOutputTokens: lastOutputTokens,
            snapshotCount: snapshots,
            timeToFirstSnapshot: ttfb ?? 0,
            elapsed: CFAbsoluteTimeGetCurrent() - start,
            isStreaming: false
          )

          // Yield final metrics with last partial if available, else empty
          continuation.yield((
            partial: lastReply ?? StreamedReply(text: ""),
            metrics: finalMetrics
          ))
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }
}

