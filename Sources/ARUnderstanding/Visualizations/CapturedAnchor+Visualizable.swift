//
//  CapturedAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if os(visionOS)
import ARKit
import RealityKit

protocol Visualizable {
    func visualize(with materials: [Material]) -> Entity
    func update(visualization entity: Entity, with materials: () -> [Material])
}

extension CapturedAnchor: Visualizable {
    public var visualization: Entity {
        visualize(with: [defaultMaterial])
    }

    public func update(visualization: Entity) {
        update(visualization: visualization, with: [defaultMaterial])
    }

    public func visualize(with materials: [Material]) -> Entity {
        switch self {
        case .hand(let capturedHandAnchor):
            capturedHandAnchor.visualize(with: materials)
        case .mesh(let capturedMeshAnchor):
            capturedMeshAnchor.visualize(with: materials)
        case .plane(let capturedPlaneAnchor):
            capturedPlaneAnchor.visualize(with: materials)
        case .image(let capturedImageAnchor):
            capturedImageAnchor.visualize(with: materials)
        case .world(let capturedWorldAnchor):
            capturedWorldAnchor.visualize(with: materials)
        case .device(let capturedDeviceAnchor):
            capturedDeviceAnchor.visualize(with: materials)
        }
    }
    
    public func update(visualization: Entity, with materials: @autoclosure () -> [Material]) {
        switch self {
        case .hand(let capturedHandAnchor):
            capturedHandAnchor.update(visualization: visualization, with: materials)
        case .mesh(let capturedMeshAnchor):
            capturedMeshAnchor.update(visualization: visualization, with: materials)
        case .plane(let capturedPlaneAnchor):
            capturedPlaneAnchor.update(visualization: visualization, with: materials)
        case .image(let capturedImageAnchor):
            capturedImageAnchor.update(visualization: visualization, with: materials)
        case .world(let capturedWorldAnchor):
            capturedWorldAnchor.update(visualization: visualization, with: materials)
        case .device(let capturedDeviceAnchor):
            capturedDeviceAnchor.update(visualization: visualization, with: materials)
        }
    }
    
    var defaultMaterial: Material {
        switch self {
        case .hand:
            return SimpleMaterial(color: .purple, isMetallic: false)
        case .mesh:
            return SimpleMaterial(color: SimpleMaterial.Color(hue: 0.1, saturation: 1, brightness: 1, alpha: 0.2), isMetallic: false)
        case .plane:
            return SimpleMaterial(color: SimpleMaterial.Color(hue: 0.66, saturation: 1, brightness: 1, alpha: 0.2), isMetallic: false)
        case .image:
            return SimpleMaterial(color: .green, isMetallic: false)
        case .world:
            return SimpleMaterial(color: .cyan, isMetallic: false)
        case .device:
            return SimpleMaterial(color: .magenta, isMetallic: false)
        }
    }
}

extension CapturedAnchorUpdate: Visualizable where AnchorType: Visualizable {
    func visualize(with materials: [any Material]) -> Entity {
        anchor.visualize(with: materials)
    }
    
    func update(visualization: Entity, with materials: () -> [Material]) {
        anchor.update(visualization: visualization, with: materials)
    }
}
#endif
