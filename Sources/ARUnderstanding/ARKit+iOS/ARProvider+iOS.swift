//
//  ARProvider.swift
//  
//
//  Created by John Haney on 3/1/25.
//

#if os(iOS)
import ARKit
import Foundation
import RealityKit

public enum ARProvider {
    case device(DeviceTrackingProvider)
    case face(FaceTrackingProvider)
    case meshes(SceneReconstructionProvider)
    case planes(PlaneDetectionProvider)
    case image(ImageTrackingProvider)
    case object(ObjectTrackingProvider)
    case body(BodyTrackingProvider)
    case world(WorldTrackingProvider)
}

public enum ARProviderDefinition: Equatable, Sendable {
    case device
    case meshes
    case unclassifiedMeshes
    case planes
    case verticalPlanes
    case horizontalPlanes
//    case room
    case image(resourceGroupName: String)
    case object(referenceObjects: [ARReferenceObject])
    case world
    case face
    case body
}

public enum QueryDeviceAnchor {
    case enabled
    case none
}

extension ARProvider {
    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> {
        self.dataProvider.anchorCapabilities
    }
    
    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> {
        self.dataProvider.sceneUnderstanding
    }
}

extension ARProviderDefinition {
    var provider: ARProvider {
        switch self {
        case .body:
            .body(BodyTrackingProvider())
        case .device:
            .device(DeviceTrackingProvider())
        case .face:
            .face(FaceTrackingProvider())
        case .horizontalPlanes:
            .planes(PlaneDetectionProvider([.horizontal]))
        case .image(let resourceGroupName):
            .image(ImageTrackingProvider(resourceGroupName: resourceGroupName))
        case .meshes:
                .meshes(SceneReconstructionProvider(.meshWithClassification))
        case .object(let referenceObjects):
            .object(ObjectTrackingProvider(referenceObjects: referenceObjects))
        case .planes:
            .planes(PlaneDetectionProvider([.horizontal, .vertical]))
        case .unclassifiedMeshes:
            .meshes(SceneReconstructionProvider(.mesh))
        case .verticalPlanes:
            .planes(PlaneDetectionProvider([.vertical]))
        case .world:
            .world(WorldTrackingProvider())
        }
    }
}

extension ARProvider {
    func matches(rhs: ARProvider) -> Bool {
        switch (self, rhs) {
        case (.body, .body):
            return true
        case (.device, .device):
            return true
        case (.face, .face):
            return true
        case (.image, .image):
            return true
        case (.meshes, .meshes):
            return true
        case (.object, .object):
            return true
        case (.planes, .planes):
            return true
        case (.world, .world):
            return true
        case (.body, _):
            return false
        case (.device, _):
            return false
        case (.face, _):
            return false
        case (.image, _):
            return false
        case (.meshes, _):
            return false
        case (.object, _):
            return false
        case (.planes, _):
            return false
        case (.world, _):
            return false
        }
    }
    
    var isReadyToRun: Bool {
        switch self {
        case .body(let provider):
            return provider.state == .initialized
        case .device(let provider):
            return provider.state == .initialized
        case .face(let provider):
            return provider.state == .initialized
        case .image(let provider):
            return provider.state == .initialized
        case .meshes(let provider):
            return provider.state == .initialized
        case .object(let provider):
            return provider.state == .initialized
        case .planes(let provider):
            return provider.state == .initialized
        case .world(let provider):
            return provider.state == .initialized
        }
    }
    
    var isSupported: Bool {
        switch self {
        case .body(_):
            return BodyTrackingProvider.isSupported
        case .device(_):
            return DeviceTrackingProvider.isSupported
        case .face(_):
            return FaceTrackingProvider.isSupported
        case .image(_):
            return ImageTrackingProvider.isSupported
        case .meshes(_):
            return SceneReconstructionProvider.isSupported
        case .object(_):
            return ObjectTrackingProvider.isSupported
        case .planes(_):
            return PlaneDetectionProvider.isSupported
        case .world(_):
            return WorldTrackingProvider.isSupported
        }
    }
    
    var dataProvider: any ARDataProvider {
        switch self {
        case .body(let bodyTrackingProvider):
            bodyTrackingProvider
        case .device(let deviceTrackingProvider):
            deviceTrackingProvider
        case .face(let faceTrackingProvider):
            faceTrackingProvider
        case .image(let imageTrackingProvider):
            imageTrackingProvider
        case .meshes(let sceneReconstructionProvider):
            sceneReconstructionProvider
        case .object(let objectTrackingProvider):
            objectTrackingProvider
        case .planes(let planeDetectionProvider):
            planeDetectionProvider
        case .world(let worldTrackingProvider):
            worldTrackingProvider
       }
    }
    
    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
        dataProvider.configure(&configuration)
    }
    func configure(_ configuration: inout ARBodyTrackingConfiguration) {
        dataProvider.configure(&configuration)
    }
}
#endif
