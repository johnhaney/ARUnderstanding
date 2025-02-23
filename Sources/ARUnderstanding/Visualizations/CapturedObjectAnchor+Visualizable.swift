//
//  CapturedObjectAnchor+Visualizable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/10/25.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit

extension CapturedObjectAnchor: Visualizable {
    @MainActor public func visualize(with materials: [Material]) -> Entity {
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        
        let model = visualizationModel(materials: materials)
        
        entity.addChild(model)
        
        return entity
    }
    
    @MainActor private func visualizationModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generatePlane(width: 1, height: 1)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }
    
    public func update(visualization entity: Entity, with materials: () -> [Material]) {
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
    }
}
