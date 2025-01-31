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
                Task {
                    defer {
                        continuation.finish()
                    }
                    for await anchor in anchorUpdates {
                        if case let .world(update) = anchor {
                            continuation.yield(update)
                        }
                    }
                }
            }
        }
        func queryDeviceAnchor(atTimestamp timestamp: TimeInterval) -> CapturedDeviceAnchor? {
            playback.recording.records.lazy
                .filter({ $0.timestamp <= timestamp })
                .compactMap({
                    switch $0 {
                    case .device(let update):
                        update.anchor
                    case .hand, .image, .mesh, .plane, .world:
                        nil
                    }
                }).last
        }
    }
}

