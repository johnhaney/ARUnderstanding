//
//  ARKit+Record.swift
//  ARUnderstandingPlus
//
//  Created by John Haney on 5/9/24.
//

#if os(visionOS)
import ARKit

extension HandTrackingProvider {
    public func record(outputName: String? = nil) async -> HandTrackingProviderRepresentable {
        AnchorRecorder(outputName: outputName).handTrackingProvider(self)
    }
}

extension WorldTrackingProvider {
    public func record(outputName: String? = nil) async -> WorldTrackingProviderRepresentable {
        AnchorRecorder(outputName: outputName).worldTrackingProvider(self)
    }
}

extension AnchorUpdateSequence<WorldAnchor> {
    @MainActor public func record(outputName: String? = nil) async -> AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> {
        await AnchorRecorder(outputName: outputName).anchorUpdates(self)
    }
}

extension SceneReconstructionProvider {
    public func record(outputName: String? = nil) async -> SceneReconstructionProviderRepresentable {
        await AnchorRecorder(outputName: outputName).sceneReconstructionProvider(self)
    }
}

extension AnchorUpdateSequence<MeshAnchor> {
    @MainActor public func record(outputName: String? = nil) async -> AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
        await AnchorRecorder(outputName: outputName).anchorUpdates(self)
    }
}

extension ImageTrackingProvider {
    public func record(outputName: String? = nil) async -> ImageTrackingProviderRepresentable {
        await AnchorRecorder(outputName: outputName).imageTrackingProvider(self)
    }
}

extension AnchorUpdateSequence<ImageAnchor> {
    @MainActor public func record(outputName: String? = nil) async -> AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> {
        await AnchorRecorder(outputName: outputName).anchorUpdates(self)
    }
}

extension PlaneDetectionProvider {
    public func record(outputName: String? = nil) async -> PlaneDetectionProviderRepresentable {
        AnchorRecorder(outputName: outputName).planeDetectionProvider(self)
    }
}

extension AnchorUpdateSequence<PlaneAnchor> {
    @MainActor public func record(outputName: String? = nil) async -> AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> {
        await AnchorRecorder(outputName: outputName).anchorUpdates(self)
    }
}

extension AnchorUpdate where AnchorType: CapturableAnchor {
    var captured: CapturedAnchorUpdate<AnchorType.CapturedType> {
        let capturedAnchor: AnchorType.CapturedType = anchor.captured
        
        return CapturedAnchorUpdate<AnchorType.CapturedType>(anchor: capturedAnchor, timestamp: self.timestamp, event: self.event.captured)
    }
}

extension AnchorUpdate.Event where AnchorType: CapturableAnchor {
    var captured: CapturedAnchorEvent {
        switch self {
        case .added:
            .added
        case .updated:
            .updated
        case .removed:
            .removed
        }
    }
}
#endif
