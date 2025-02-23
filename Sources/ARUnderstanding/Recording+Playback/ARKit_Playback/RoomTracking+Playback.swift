//
//  RoomTracking+Playback.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/9/25.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation

public protocol RoomTrackingProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedRoomAnchor>> { get }
}

extension AnchorPlayback {
    struct RoomTrackingPlaybackProvider: RoomTrackingProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedRoomAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                let task = Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .room(update) = anchor {
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
