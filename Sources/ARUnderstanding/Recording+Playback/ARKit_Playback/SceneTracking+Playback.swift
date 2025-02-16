//
//  SceneTracking+Playback.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if canImport(ARKit)
import ARKit
#endif
import ARUnderstanding

public protocol SceneReconstructionProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> { get }
}

extension AnchorPlayback {
    struct SceneReconstructionPlaybackProvider: SceneReconstructionProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .mesh(update) = anchor {
                            continuation.yield(update)
                        }
                    }
                }
            }
        }
    }
}

