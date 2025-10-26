//
//  AccessoryTracking+Record.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/6/25.
//

#if os(visionOS)
import ARKit

extension AnchorRecorder {
    @MainActor public func anchorUpdates(_ originalAnchorUpdates: AnchorUpdateSequence<AccessoryAnchor>) async -> AsyncStream<CapturedAnchorUpdate<CapturedAccessoryAnchor>> {
        await AnchorRecorder.AccessoryTrackingRecordingAdapter(
            recorder: AnchorRecorder(outputName: outputName),
            originalAnchorUpdates: originalAnchorUpdates
        ).anchorUpdates
    }
    
    final class AccessoryTrackingRecordingAdapter {
        private let recorder: AnchorRecorder
        @MainActor private let originalAnchorUpdates: AnchorUpdateSequence<AccessoryAnchor>
        
        @MainActor init(recorder: AnchorRecorder, originalAnchorUpdates: AnchorUpdateSequence<AccessoryAnchor>) {
            self.recorder = recorder
            self.originalAnchorUpdates = originalAnchorUpdates
        }

        @MainActor var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedAccessoryAnchor>> {
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
    
    nonisolated func accessoryTrackingProvider(_ accessoryTrackingProvider: ARKit.AccessoryTrackingProvider) -> AccessoryTrackingProviderRepresentable {
        AccessoryTrackingRecordingProvider(recorder: self, accessoryTrackingProvider: accessoryTrackingProvider)
    }
    
    struct AccessoryTrackingRecordingProvider: AccessoryTrackingProviderRepresentable {
        private let recorder: AnchorRecorder
        private let accessoryTrackingProvider: AccessoryTrackingProvider
        
        init(recorder: AnchorRecorder, accessoryTrackingProvider: AccessoryTrackingProvider) {
            self.recorder = recorder
            self.accessoryTrackingProvider = accessoryTrackingProvider
        }
        
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedAccessoryAnchor>> {
            AsyncStream { continuation in
                let task = Task {
                    defer { continuation.finish() }
                    for await update in accessoryTrackingProvider.anchorUpdates {
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
        
        var state: DataProviderState {
            accessoryTrackingProvider.state
        }
        
        var description: String {
            accessoryTrackingProvider.description
        }
    }
}
#endif
