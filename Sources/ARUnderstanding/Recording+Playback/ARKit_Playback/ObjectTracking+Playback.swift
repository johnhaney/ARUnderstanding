//
//  ObjectTracking+Playback.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/10/25.
//

#if canImport(ARKit)
import ARKit
#endif

public protocol ObjectTrackingProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedObjectAnchor>> { get }
}

extension AnchorPlayback {
    struct ObjectTrackingPlaybackProvider: ObjectTrackingProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedObjectAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                let task = Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .object(update) = anchor {
                            continuation.yield(update)
                        }
                    }
                }
                continuation.onTermination = { @Sendable _ in
                    task.cancel()
                }
            }
        }
    }
}
