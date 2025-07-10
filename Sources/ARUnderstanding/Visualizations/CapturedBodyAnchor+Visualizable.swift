//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/5/25.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit
import Spatial

extension CapturedBodyAnchor: Visualizable {
    struct CapturedBodyComponent: Component {
        let rootEntity: Entity
        let entities: [SkeletonJointName: Entity]
        let boneEntities: [SkeletonJointName: Entity]
    }
    @MainActor public func visualize(in rootEntity: Entity, with materials: [Material]) async {
        rootEntity.transform = Transform(scale: SIMD3<Float>(estimatedScaleFactor))
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        rootEntity.addChild(entity)
        let model = visualizationModel(materials: materials)
        let boneModel = boneModel(materials: materials)
        
        let jointEntities: [SkeletonJointName: Entity] = Dictionary(uniqueKeysWithValues: SkeletonJointName.allJointNames.map { joint in
            let ball = model.clone(recursive: false)
            ball.name = joint.description
            entity.addChild(ball)
            return (joint, ball)
        })
        
        let boneEntities: [SkeletonJointName: Entity] = Dictionary(uniqueKeysWithValues: SkeletonJointName.allJointNames.compactMap { joint in
            guard joint.parentName != nil else { return nil }
            let bone = boneModel.clone(recursive: false)
            entity.addChild(bone)
            return (joint, bone)
        })
        rootEntity.components.set(CapturedBodyComponent(rootEntity: rootEntity, entities: jointEntities, boneEntities: boneEntities))
        update(visualization: entity, with: materials)
    }
    
    @MainActor private func visualizationModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }
    
    @MainActor private func boneModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generateCylinder(height: 1, radius: 0.05)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }
    
    @MainActor public func update(visualization entity: Entity, with materials: @autoclosure () -> [Material]) {
        guard let component = entity.components[CapturedBodyComponent.self]
        else { return }
        
        let rootEntity = component.rootEntity
        let jointEntities = component.entities
        let boneEntities = component.boneEntities
        
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        rootEntity.transform = Transform(scale: SIMD3<Float>(estimatedScaleFactor))
        
        for jointName in SkeletonJointName.allJointNames {
            if let existing = jointEntities[jointName] {
                existing.transform = Transform(matrix: skeleton.jointModelTransforms[jointName.index])

                if let parent = jointName.parentName,
                   let bone = boneEntities[jointName],
                   let bottomTranslation = jointEntities[parent]?.position {
                    let topPosition = Point3D(existing.position)
                    let bottomPosition = Point3D(bottomTranslation)
                    let rotation = Rotation3D(angle: .degrees(90), axis: .x).rotated(by: Rotation3D(position: bottomPosition, target: topPosition))
                    
                    bone.transform = Transform(matrix: simd_float4x4(AffineTransform3D(scale: Size3D(width: 1, height: length(topPosition.vector - bottomPosition.vector), depth: 1), rotation: rotation, translation: Vector3D((topPosition.vector + bottomPosition.vector)/2))))
                }
            }
        }
    }
}
