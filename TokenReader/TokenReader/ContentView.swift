//
//  ContentView.swift
//  TokenReader
//
//  Created by Gilberto Magno on 21/11/25.
//

import SwiftUI

struct ContentView: View {
    @Bindable private var model = ChatViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(model.items) { item in
                                messageBubble(for: item)
                                    .id(item.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    .background(Color.clear)
                    .onChange(of: model.items.count) { _, _ in
                        if let last = model.items.last { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }

                Divider()

                bottomComposer
                    .background(.ultraThinMaterial)
            }
            .navigationTitle("Chat")
//            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func messageBubble(for item: ChatItem) -> some View {
        HStack(alignment: .bottom) {
            if item.role == .assistant { Spacer(minLength: 32) }
            VStack(alignment: .leading, spacing: 6) {
                Text(item.text.isEmpty ? "…" : item.text)
                    .textSelection(.enabled)
                    .padding(10)
                    .background(item.role == .user ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            if item.role == .user { Spacer(minLength: 32) }
        }
        .animation(.default, value: item.text)
    }

    private var bottomComposer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("Message", text: $model.composing, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...6)
                    .focused($isFocused)

                if model.liveMetrics.isStreaming {
                    Button(role: .destructive) {
                        model.cancelStreaming()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                } else {
                    Button {
                        model.send()
                        isFocused = false
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(model.composing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Live token & streaming meter
            HStack(spacing: 16) {
                Label("In: \(model.liveMetrics.estimatedInputTokens)", systemImage: "arrow.down.circle")
                Label("Out: \(model.liveMetrics.estimatedOutputTokens)", systemImage: "arrow.up.circle")
                Label("Snaps: \(model.liveMetrics.snapshotCount)", systemImage: "sparkles")
                if let ttfb = model.liveMetrics.formattedTTFB {
                    Label("TTFB: \(ttfb)s", systemImage: "timer")
                }
                Label(String(format: "T: %.2fs", model.liveMetrics.elapsed), systemImage: "clock")
                Spacer()
                Circle()
                    .fill(model.liveMetrics.isStreaming ? Color.green : Color.secondary)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.3)))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    ContentView()
}
