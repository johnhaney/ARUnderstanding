//
//  CapturedRoomAnchor+Visualizable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/9/25.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit

extension CapturedRoomAnchor: Visualizable {
    @MainActor public func visualize(in rootEntity: Entity, with materials: [Material]) async {
        rootEntity.transform = Transform(matrix: self.originFromAnchorTransform)
        guard let mesh: MeshResource = await mesh(name: "Visualization")
        else { return }
        let model = ModelComponent(mesh: mesh, materials: materials)
        rootEntity.components.set(model)
    }
}

extension RoomAnchorRepresentable {
    func mesh(name: String) async -> MeshResource? {
        await geometry.mesh.mesh(name: name)
    }
}

//extension AnyRoomAnchorRepresentable: Visualizable {
//    @MainActor public func visualize(in rootEntity: Entity, with materials: [Material]) async {
//        rootEntity.transform = Transform(matrix: self.originFromAnchorTransform)
//        guard let mesh: MeshResource = await mesh(name: "Visualization")
//        else { return }
//        let model = ModelComponent(mesh: mesh, materials: materials)
//        rootEntity.components.set(model)
//    }
//}
//
//extension RoomAnchorRepresentable {
//    func mesh(name: String) async -> MeshResource? {
//        await geometry.mesh(name: name)
//    }
//}
