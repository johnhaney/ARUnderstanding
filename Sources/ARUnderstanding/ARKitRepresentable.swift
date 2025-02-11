//
//  ARKitRepresentable.swift
//
//
//  Created by John Haney on 5/11/24.
//

#if os(visionOS)
import ARKit

protocol ARKitRepresentable {
    func handTrackingProvider(_:ARKit.HandTrackingProvider) -> HandTrackingProviderRepresentable
    func worldTrackingProvider(_:ARKit.WorldTrackingProvider) -> WorldTrackingProviderRepresentable
    func sceneReconstructionProvider(_:ARKit.SceneReconstructionProvider) -> SceneReconstructionProviderRepresentable
    func planeDetectionProvider(_:ARKit.PlaneDetectionProvider) -> PlaneDetectionProviderRepresentable
    func imageDetectionProvider(_:ARKit.ImageTrackingProvider) -> ImageTrackingProviderRepresentable
    func objectTrackingProvider(_:ARKit.ObjectTrackingProvider) -> ObjectTrackingProviderRepresentable
}
#endif
