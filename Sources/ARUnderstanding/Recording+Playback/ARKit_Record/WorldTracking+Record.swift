//
//  WorldTracking+Record.swift
//  ARUnderstandingPlus
//
//  Created by John Haney on 5/11/24.
//

#if os(visionOS)
import ARKit

extension AnchorRecorder {
    nonisolated func worldTrackingProvider(_ worldTrackingProvider: ARKit.WorldTrackingProvider) -> WorldTrackingProviderRepresentable {
        WorldTrackingRecordingProvider(recorder: self, worldTrackingProvider: worldTrackingProvider)
    }

    @MainActor public func anchorUpdates(_ originalAnchorUpdates: AnchorUpdateSequence<WorldAnchor>) async -> AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> {
        await AnchorRecorder.WorldTrackingRecordingAdapter(
            recorder: AnchorRecorder(outputName: outputName),
            originalAnchorUpdates: originalAnchorUpdates
        ).anchorUpdates
    }
    
    final class WorldTrackingRecordingAdapter {
        private let recorder: AnchorRecorder
        @MainActor private let originalAnchorUpdates: AnchorUpdateSequence<WorldAnchor>
        
        @MainActor init(recorder: AnchorRecorder, originalAnchorUpdates: AnchorUpdateSequence<WorldAnchor>) {
            self.recorder = recorder
            self.originalAnchorUpdates = originalAnchorUpdates
        }
        
        @MainActor var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> {
            AsyncStream { continuation in
                let originalAnchorUpdates = originalAnchorUpdates
                let recorder = recorder
                Task {
                    defer { continuation.finish() }
                    for await update in originalAnchorUpdates {
                        let captured = update.captured
                        await recorder.record(anchor: update)
                        continuation.yield(captured)
                    }
                }
            }
        }
    }
    
    struct WorldTrackingRecordingProvider: WorldTrackingProviderRepresentable {
        private let recorder: AnchorRecorder
        private let worldTrackingProvider: WorldTrackingProvider
        
        init(recorder: AnchorRecorder, worldTrackingProvider: WorldTrackingProvider) {
            self.recorder = recorder
            self.worldTrackingProvider = worldTrackingProvider
        }
        
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> {
            AsyncStream { continuation in
                Task {
                    defer { continuation.finish() }
                    for await update in worldTrackingProvider.anchorUpdates {
                        let captured = update.captured
                        await recorder.record(anchor: update)
                        continuation.yield(captured)
                    }
                }
            }
        }

        func queryDeviceAnchor(atTimestamp timestamp: TimeInterval) -> CapturedDeviceAnchor? {
            worldTrackingProvider.queryDeviceAnchor(atTimestamp: timestamp)?.captured
        }
    }
}
#endif
