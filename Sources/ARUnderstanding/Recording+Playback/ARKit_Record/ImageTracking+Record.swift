//
//  ImageTracking+Record.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if os(visionOS)
import ARKit

extension AnchorRecorder {
    @MainActor public func anchorUpdates(_ originalAnchorUpdates: AnchorUpdateSequence<ImageAnchor>) async -> AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> {
        await AnchorRecorder.ImageTrackingRecordingAdapter(
            recorder: AnchorRecorder(outputName: outputName),
            originalAnchorUpdates: originalAnchorUpdates
        ).anchorUpdates
    }
    
    final class ImageTrackingRecordingAdapter {
        private let recorder: AnchorRecorder
        @MainActor private let originalAnchorUpdates: AnchorUpdateSequence<ImageAnchor>
        
        @MainActor init(recorder: AnchorRecorder, originalAnchorUpdates: AnchorUpdateSequence<ImageAnchor>) {
            self.recorder = recorder
            self.originalAnchorUpdates = originalAnchorUpdates
        }

        @MainActor var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> {
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
    
    nonisolated func imageTrackingProvider(_ imageTrackingProvider: ARKit.ImageTrackingProvider) -> ImageTrackingProviderRepresentable {
        ImageTrackingRecordingProvider(recorder: self, imageTrackingProvider: imageTrackingProvider)
    }
    
    struct ImageTrackingRecordingProvider: ImageTrackingProviderRepresentable {
        private let recorder: AnchorRecorder
        private let imageTrackingProvider: ImageTrackingProvider
        
        init(recorder: AnchorRecorder, imageTrackingProvider: ImageTrackingProvider) {
            self.recorder = recorder
            self.imageTrackingProvider = imageTrackingProvider
        }
        
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> {
            AsyncStream { continuation in
                Task {
                    defer { continuation.finish() }
                    for await update in imageTrackingProvider.anchorUpdates {
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
