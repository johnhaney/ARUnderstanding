//
//  CapturedAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit

protocol Visualizable {
    @MainActor func visualize(with materials: [Material]) -> Entity
    @MainActor func update(visualization entity: Entity, with materials: () -> [Material])
}

extension CapturedAnchor: Visualizable {
    @MainActor public func visualize(in baseEntity: Entity) {
        if let existing = baseEntity.findEntity(named: id.uuidString) {
            update(visualization: existing)
        } else {
            let visualization = self.visualization
            visualization.name = id.uuidString
            baseEntity.addChild(visualization)
        }
    }
    
    @MainActor public var visualization: Entity {
        visualize(with: [defaultMaterial])
    }

    @MainActor public func update(visualization: Entity) {
        update(visualization: visualization, with: [defaultMaterial])
    }

    @MainActor public func visualize(with materials: [Material]) -> Entity {
        switch self {
        case .hand(let capturedHandAnchor):
            capturedHandAnchor.visualize(with: materials)
        case .mesh(let capturedMeshAnchor):
            capturedMeshAnchor.visualize(with: materials)
        case .plane(let capturedPlaneAnchor):
            capturedPlaneAnchor.visualize(with: materials)
        case .image(let capturedImageAnchor):
            capturedImageAnchor.visualize(with: materials)
        case .object(let capturedObjectAnchor):
            capturedObjectAnchor.visualize(with: materials)
        case .world(let capturedWorldAnchor):
            capturedWorldAnchor.visualize(with: materials)
        case .device(let capturedDeviceAnchor):
            capturedDeviceAnchor.visualize(with: materials)
        case .room(let capturedRoomAnchor):
            capturedRoomAnchor.visualize(with: materials)
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
        case .object(let capturedObjectAnchor):
            capturedObjectAnchor.update(visualization: visualization, with: materials)
        case .world(let capturedWorldAnchor):
            capturedWorldAnchor.update(visualization: visualization, with: materials)
        case .device(let capturedDeviceAnchor):
            capturedDeviceAnchor.update(visualization: visualization, with: materials)
        case .room(let capturedRoomAnchor):
            capturedRoomAnchor.update(visualization: visualization, with: materials)
        }
    }
    
    var defaultMaterial: Material {
        switch self {
        case .hand:
            return SimpleMaterial(color: .purple, isMetallic: false)
        case .mesh:
            return SimpleMaterial(color: SimpleMaterial.Color(hue: 0.0, saturation: 0.0, brightness: 0.5, alpha: 0.4), isMetallic: false)
        case .plane:
            return SimpleMaterial(color: SimpleMaterial.Color(hue: 0.5, saturation: 0.2, brightness: 0.5, alpha: 0.6), isMetallic: false)
        case .image:
            return SimpleMaterial(color: .green, isMetallic: false)
        case .object:
            return SimpleMaterial(color: .orange, isMetallic: false)
        case .world:
            return SimpleMaterial(color: .cyan, isMetallic: false)
        case .device:
            return SimpleMaterial(color: .purple, isMetallic: false)
        case .room:
            return SimpleMaterial(color: SimpleMaterial.Color(hue: 0.5, saturation: 0.2, brightness: 0.5, alpha: 0.6), isMetallic: false)
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
