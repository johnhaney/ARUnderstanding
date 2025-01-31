//
//  HandTracking+Playback.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if canImport(ARKit)
import ARKit
#endif

public protocol HandTrackingProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> { get }
    var latestAnchors: ((any HandAnchorRepresentable)?, (any HandAnchorRepresentable)?) { get }
    var description: String { get }
}

extension AnchorPlayback {
    final class HandTrackingPlaybackProvider: HandTrackingProviderRepresentable {
        var latestAnchors: ((any HandAnchorRepresentable)?, (any HandAnchorRepresentable)?) { (nil, nil) }
        
        let playback: AnchorPlayback

        init(playback: AnchorPlayback) {
            self.playback = playback
        }
        
        public var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> {
            AsyncStream { continuation in
                let handUpdates = playback.handUpdates
                Task {
                    defer {
                        continuation.finish()
                    }
                    for await update in handUpdates {
                        continuation.yield(update)
                    }
                }
            }
        }
        
        var description: String { "HandTrackingProvider+playback" }
    }
}
