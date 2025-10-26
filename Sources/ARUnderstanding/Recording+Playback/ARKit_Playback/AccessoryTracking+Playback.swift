//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/5/25.
//

import Foundation

public protocol AccessoryTrackingProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedAccessoryAnchor>> { get }
}

extension AnchorPlayback {
    struct AccessoryTrackingPlaybackProvider: AccessoryTrackingProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedAccessoryAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                let task = Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .accessory(update) = anchor {
                            continuation.yield(update)
                        }
                    }
                }
                continuation.onTermination = { @Sendable termination in
                    switch termination {
                    case .cancelled: task.cancel()
                    default: break
                    }
                }
            }
        }
    }
}
