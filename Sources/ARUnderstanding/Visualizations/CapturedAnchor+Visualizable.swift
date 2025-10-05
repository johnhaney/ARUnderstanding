//
//  CapturedAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

import Foundation
#if canImport(ARKit)
import ARKit
#endif
#if canImport(RealityKit)
import RealityKit

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
public protocol Visualizable {
    @MainActor func visualize(in: Entity, with materials: [Material]) async
}

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
extension CapturedAnchor: Visualizable {
    struct CapturedAnchorVisualizedComponent: Component {
        let anchor: CapturedAnchor
        let entity: Entity
    }

    @MainActor public func visualize(in entity: Entity, with materials: [Material]) async {
        switch self {
        case .body(let capturedBodyAnchor):
            await capturedBodyAnchor.visualize(in: entity, with: materials)
        case .device(let capturedDeviceAnchor):
            await capturedDeviceAnchor.visualize(in: entity, with: materials)
        case .face(let capturedFaceAnchor):
            await capturedFaceAnchor.visualize(in: entity, with: materials)
        case .hand(let capturedHandAnchor):
            let leftEntity = entity.findEntity(named: "LeftHand") ?? {
                let e = Entity()
                e.name = "LeftHand"
                entity.addChild(e)
                return e }()
            let rightEntity = entity.findEntity(named: "RightHand") ?? {
                let e = Entity()
                e.name = "RightHand"
                entity.addChild(e)
                return e }()

            await capturedHandAnchor.visualize(in: (capturedHandAnchor.anchor.chirality == .left) ? leftEntity : rightEntity, with: materials)
        case .image(let capturedImageAnchor):
            await capturedImageAnchor.visualize(in: entity, with: materials)
        case .mesh(let capturedMeshAnchor):
            await capturedMeshAnchor.visualize(in: entity, with: materials)
        case .object(let capturedObjectAnchor):
            await capturedObjectAnchor.visualize(in: entity, with: materials)
        case .plane(let capturedPlaneAnchor):
            await capturedPlaneAnchor.visualize(in: entity, with: materials)
        case .room(let capturedRoomAnchor):
            await capturedRoomAnchor.visualize(in: entity, with: materials)
        case .world(let capturedWorldAnchor):
            await capturedWorldAnchor.visualize(in: entity, with: materials)
        }
    }
    
    public var defaultMaterial: Material {
        switch self {
        case .body:
            return SimpleMaterial(color: .purple, isMetallic: false)
        case .device:
            return SimpleMaterial(color: .yellow, isMetallic: false)
        case .face:
            return SimpleMaterial(color: .purple, isMetallic: false)
        case .hand:
            return SimpleMaterial(color: .purple, isMetallic: false)
        case .image:
            return SimpleMaterial(color: .green, isMetallic: false)
        case .mesh:
            return SimpleMaterial(color: SimpleMaterial.Color(hue: 0.0, saturation: 0.0, brightness: 0.5, alpha: 1), isMetallic: false)
        case .object:
            return SimpleMaterial(color: .orange, isMetallic: false)
        case .plane:
            return SimpleMaterial(color: SimpleMaterial.Color(hue: 0.5, saturation: 0.2, brightness: 0.5, alpha: 1), isMetallic: false)
        case .room:
            return SimpleMaterial(color: SimpleMaterial.Color(hue: 0.5, saturation: 0.2, brightness: 0.5, alpha: 1), isMetallic: false)
        case .world:
            return SimpleMaterial(color: .cyan, isMetallic: false)
        }
    }
}

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
extension CapturedAnchorUpdate: Visualizable where AnchorType: Visualizable {
    public func visualize(in rootEntity: Entity, with materials: [any Material]) async {
        await anchor.visualize(in: rootEntity, with: materials)
    }
}
#endif
