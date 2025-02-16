//
//  PlaneTracking+Playback.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if canImport(ARKit)
import ARKit
#endif
import ARUnderstanding

public protocol PlaneDetectionProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> { get }
}

extension AnchorPlayback {
    struct PlaneDetectionPlaybackProvider: PlaneDetectionProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .plane(update) = anchor {
                            continuation.yield(update)
                        }
                    }
                }
            }
        }
    }
}

