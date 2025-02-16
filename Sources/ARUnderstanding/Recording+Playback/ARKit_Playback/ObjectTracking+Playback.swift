//
//  ObjectTracking+Playback.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/10/25.
//

#if canImport(ARKit)
import ARKit
#endif
import ARUnderstanding

public protocol ObjectTrackingProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedObjectAnchor>> { get }
}

extension AnchorPlayback {
    struct ObjectTrackingPlaybackProvider: ObjectTrackingProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedObjectAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .object(update) = anchor {
                            continuation.yield(update)
                        }
                    }
                }
            }
        }
    }
}
