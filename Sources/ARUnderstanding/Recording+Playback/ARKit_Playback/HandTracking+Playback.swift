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

@available(iOS 18.0, tvOS 18.0, *)
public protocol HandTrackingProviderRepresentable {
    var anchorUpdates: AsyncSequence<CapturedAnchorUpdate<CapturedHandAnchor>, Never> { get }
    var latestAnchors: ((any HandAnchorRepresentable)?, (any HandAnchorRepresentable)?) { get }
    var description: String { get }
}

@available(iOS 18.0, tvOS 18.0, *)
extension AnchorPlayback {
    final class HandTrackingPlaybackProvider: HandTrackingProviderRepresentable {
        var latestAnchors: ((any HandAnchorRepresentable)?, (any HandAnchorRepresentable)?) { (nil, nil) }
        
        let playback: AnchorPlayback

        init(playback: AnchorPlayback) {
            self.playback = playback
        }
        
        public var anchorUpdates: AsyncSequence<CapturedAnchorUpdate<CapturedHandAnchor>, Never> {
            playback.handUpdates
        }
        
        var description: String { "HandTrackingProvider+playback" }
    }
}
