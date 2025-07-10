//
//  ARKit+Playback.swift
//  ARUnderstandingPlus
//
//  Created by John Haney on 5/7/24.
//

#if os(visionOS)
import ARKit

extension HandTrackingProvider {
    public func playback(fileName: String) -> HandTrackingProviderRepresentable {
        return AnchorPlayback(fileName: fileName).handTrackingProvider(self)
    }
}

extension ImageTrackingProvider {
    public func playback(fileName: String) -> ImageTrackingProviderRepresentable {
        AnchorPlayback(fileName: fileName).imageDetectionProvider(self)
    }
}

extension PlaneDetectionProvider {
    public func playback(fileName: String) -> PlaneDetectionProviderRepresentable {
        AnchorPlayback(fileName: fileName).planeDetectionProvider(self)
    }
}

extension SceneReconstructionProvider {
    public func playback(fileName: String) -> SceneReconstructionProviderRepresentable {
        AnchorPlayback(fileName: fileName).sceneReconstructionProvider(self)
    }
}

extension WorldTrackingProvider {
    public func playback(fileName: String) -> WorldTrackingProviderRepresentable {
        AnchorPlayback(fileName: fileName).worldTrackingProvider(self)
    }
}

extension RoomTrackingProvider {
    public func playback(fileName: String) -> RoomTrackingProviderRepresentable {
        AnchorPlayback(fileName: fileName).roomTrackingProvider(self)
    }
}

extension AnchorPlayback: ARKitRepresentable {
    func handTrackingProvider(_: HandTrackingProvider) -> any HandTrackingProviderRepresentable {
        AnchorPlayback.HandTrackingPlaybackProvider(playback: self)
    }
    
    func worldTrackingProvider(_: WorldTrackingProvider) -> any WorldTrackingProviderRepresentable {
        AnchorPlayback.WorldTrackingPlaybackProvider(playback: self)
    }
    
    func sceneReconstructionProvider(_ sceneReconstructionProvider: SceneReconstructionProvider) -> any SceneReconstructionProviderRepresentable {
        AnchorPlayback.SceneReconstructionPlaybackProvider(playback: self)
    }
    
    func planeDetectionProvider(_: PlaneDetectionProvider) -> any PlaneDetectionProviderRepresentable {
        AnchorPlayback.PlaneDetectionPlaybackProvider(playback: self)
    }
    
    func imageDetectionProvider(_: ImageTrackingProvider) -> any ImageTrackingProviderRepresentable {
        AnchorPlayback.ImageTrackingPlaybackProvider(playback: self)
    }
    
    func objectTrackingProvider(_: ObjectTrackingProvider) -> any ObjectTrackingProviderRepresentable {
        AnchorPlayback.ObjectTrackingPlaybackProvider(playback: self)
    }
    
    func roomTrackingProvider(_: RoomTrackingProvider) -> any RoomTrackingProviderRepresentable {
        AnchorPlayback.RoomTrackingPlaybackProvider(playback: self)
    }
}
#endif
