//
//  PlaneTracking+Record.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if os(visionOS)
import ARKit

extension AnchorRecorder {
    nonisolated func planeDetectionProvider(_ planeDetectionProvider: ARKit.PlaneDetectionProvider) -> PlaneDetectionProviderRepresentable {
        PlaneDetectionRecordingProvider(recorder: self, planeDetectionProvider: planeDetectionProvider)
    }

    @MainActor public func anchorUpdates(_ originalAnchorUpdates: AnchorUpdateSequence<PlaneAnchor>) async -> AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> {
        await AnchorRecorder.PlaneDetectionRecordingAdapter(
            recorder: AnchorRecorder(outputName: outputName),
            originalAnchorUpdates: originalAnchorUpdates
        ).anchorUpdates
    }
    
    final class PlaneDetectionRecordingAdapter {
        private let recorder: AnchorRecorder
        @MainActor private let originalAnchorUpdates: AnchorUpdateSequence<PlaneAnchor>
        
        @MainActor init(recorder: AnchorRecorder, originalAnchorUpdates: AnchorUpdateSequence<PlaneAnchor>) {
            self.recorder = recorder
            self.originalAnchorUpdates = originalAnchorUpdates
        }

        @MainActor var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> {
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
    
    struct PlaneDetectionRecordingProvider: PlaneDetectionProviderRepresentable {
        private let recorder: AnchorRecorder
        private let planeDetectionProvider: PlaneDetectionProvider
        
        init(recorder: AnchorRecorder, planeDetectionProvider: PlaneDetectionProvider) {
            self.recorder = recorder
            self.planeDetectionProvider = planeDetectionProvider
        }
        
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> {
            AsyncStream { continuation in
                Task {
                    defer { continuation.finish() }
                    for await update in planeDetectionProvider.anchorUpdates {
                        let captured = update.captured
                        await recorder.record(anchor: update)
                        continuation.yield(captured)
                    }
                }
            }
        }
    }
}
#endif
