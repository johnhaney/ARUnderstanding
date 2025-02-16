//
//  CapturedMeshAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit

extension CapturedMeshAnchor: Visualizable {
    @MainActor public func visualize(with materials: [Material]) -> Entity {
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        Task {
            if let model = await visualizationModel(materials: materials) {
                entity.addChild(model)
            }
        }
        
        return entity
    }
    
    @MainActor private func visualizationModel(materials: [Material]) async -> Entity? {
        guard let mesh: MeshResource = await mesh(name: "Visualization")
        else { return nil }
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }

    @MainActor public func update(visualization entity: Entity, with materials: () -> [Material]) {
        let transform = Transform(matrix: self.originFromAnchorTransform)
        entity.transform = transform
        // Remove the previous mesh and we will start over each time
        for child in entity.children {
            child.removeFromParent()
        }
        let materials = materials()
        Task {
            if let model = await visualizationModel(materials: materials) {
                update(visualization: entity, with: model, transform: transform)
            }
        }
    }
    
    @MainActor
    private func update(visualization entity: Entity, with model: Entity, transform: Transform) {
        entity.addChild(model)
    }
}

extension MeshAnchorRepresentable {
    func mesh(name: String) async -> MeshResource? {
        await geometry.mesh.mesh(name: name)
    }
}
