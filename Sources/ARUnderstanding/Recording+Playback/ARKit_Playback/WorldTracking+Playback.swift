//
//  WorldTracking+Playback.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation

public protocol WorldTrackingProviderRepresentable {
    var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> { get }
    func queryDeviceAnchor(atTimestamp timestamp: TimeInterval) -> CapturedDeviceAnchor?
}

extension AnchorPlayback {
    struct WorldTrackingPlaybackProvider: WorldTrackingProviderRepresentable {
        let playback: AnchorPlayback
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> {
            AsyncStream { continuation in
                let anchorUpdates = playback.anchorUpdates
                let task = Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .world(update) = anchor {
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
        func queryDeviceAnchor(atTimestamp timestamp: TimeInterval) -> CapturedDeviceAnchor? {
            playback.queryDeviceAnchor(atTimestamp: timestamp)
        }
    }
}

