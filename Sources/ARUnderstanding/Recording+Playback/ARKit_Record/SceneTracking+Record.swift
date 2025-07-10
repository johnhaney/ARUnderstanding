//
//  SceneTracking+Record.swift
//  ARUnderstandingPlus
//
//
//  Created by John Haney on 5/11/24.
//

#if os(visionOS)
import ARKit

extension AnchorRecorder {
    nonisolated func sceneReconstructionProvider(_ sceneReconstructionProvider: ARKit.SceneReconstructionProvider) -> any SceneReconstructionProviderRepresentable {
        SceneReconstructionRecordingProvider(recorder: self, sceneReconstructionProvider: sceneReconstructionProvider)
    }
    
    @MainActor public func anchorUpdates(_ originalAnchorUpdates: AnchorUpdateSequence<MeshAnchor>) async -> AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
        await AnchorRecorder.SceneReconstructionRecordingAdapter(
            recorder: AnchorRecorder(outputName: outputName),
            originalAnchorUpdates: originalAnchorUpdates
        ).anchorUpdates
    }
    
    final class SceneReconstructionRecordingAdapter {
        private let recorder: AnchorRecorder
        @MainActor private let originalAnchorUpdates: AnchorUpdateSequence<MeshAnchor>
        
        @MainActor init(recorder: AnchorRecorder, originalAnchorUpdates: AnchorUpdateSequence<MeshAnchor>) {
            self.recorder = recorder
            self.originalAnchorUpdates = originalAnchorUpdates
        }

        @MainActor var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
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

    struct SceneReconstructionRecordingProvider: SceneReconstructionProviderRepresentable {
        private let recorder: AnchorRecorder
        private let sceneReconstructionProvider: SceneReconstructionProvider
        
        init(recorder: AnchorRecorder, sceneReconstructionProvider: SceneReconstructionProvider) {
            self.recorder = recorder
            self.sceneReconstructionProvider = sceneReconstructionProvider
        }
        
        var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
            AsyncStream { continuation in
                let task = Task {
                    defer { continuation.finish() }
                    for await update in sceneReconstructionProvider.anchorUpdates {
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
}
#endif
