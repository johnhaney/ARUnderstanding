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

public protocol SceneReconstructionProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> { get }
}

extension AnchorPlayback {
    struct SceneReconstructionPlaybackProvider: SceneReconstructionProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                let task = Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .mesh(update) = anchor {
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

