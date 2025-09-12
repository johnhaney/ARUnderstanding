//
//  HandTracking+Record.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if os(visionOS)
import ARKit

extension AnchorRecorder {
    @MainActor public func anchorUpdates(_ originalAnchorUpdates: AnchorUpdateSequence<HandAnchor>) async -> AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> {
        await AnchorRecorder.HandTrackingRecordingAdapter(
            recorder: AnchorRecorder(outputName: outputName),
            originalAnchorUpdates: originalAnchorUpdates
        ).anchorUpdates
    }
    
    final class HandTrackingRecordingAdapter {
        private let recorder: AnchorRecorder
        @MainActor private let originalAnchorUpdates: AnchorUpdateSequence<HandAnchor>
        
        @MainActor init(recorder: AnchorRecorder, originalAnchorUpdates: AnchorUpdateSequence<HandAnchor>) {
            self.recorder = recorder
            self.originalAnchorUpdates = originalAnchorUpdates
        }

        @MainActor var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> {
            AsyncStream { continuation in
                let originalAnchorUpdates = originalAnchorUpdates
                let recorder = recorder
                let task = Task {
                    defer { continuation.finish() }
                    for await update in originalAnchorUpdates {
                        let captured = update.captured
                        await recorder.record(anchor: update)
                        continuation.yield(captured)
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
    }
    
    nonisolated func handTrackingProvider(_ handTrackingProvider: ARKit.HandTrackingProvider) -> HandTrackingProviderRepresentable {
        HandTrackingRecordingProvider(recorder: self, handTrackingProvider: handTrackingProvider)
    }
    
    struct HandTrackingRecordingProvider: HandTrackingProviderRepresentable {
        
        private let recorder: AnchorRecorder
        private let handTrackingProvider: HandTrackingProvider
        
        init(recorder: AnchorRecorder, handTrackingProvider:HandTrackingProvider) {
            self.recorder = recorder
            self.handTrackingProvider = handTrackingProvider
        }
        
        var anchorUpdates: AsyncSequence<CapturedAnchorUpdate<CapturedHandAnchor>, Never> {
            handTrackingProvider.anchorUpdates.map { update in
                let captured = update.captured
                await recorder.record(anchor: update)
                return captured
            }
        }
        
        public var latestAnchors: ((any HandAnchorRepresentable)?, (any HandAnchorRepresentable)?) {
            handTrackingProvider.latestAnchors
        }
        
        var state: DataProviderState {
            handTrackingProvider.state
        }
        
        var description: String {
            handTrackingProvider.description
        }
    }
}
#endif
