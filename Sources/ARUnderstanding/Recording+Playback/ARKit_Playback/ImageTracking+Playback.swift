//
//  ImageTracking+Playback.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if canImport(ARKit)
import ARKit
#endif
import ARUnderstanding

public protocol ImageTrackingProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> { get }
}

extension AnchorPlayback {
    struct ImageTrackingPlaybackProvider: ImageTrackingProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .image(update) = anchor {
                            continuation.yield(update)
                        }
                    }
                }
            }
        }
    }
}

