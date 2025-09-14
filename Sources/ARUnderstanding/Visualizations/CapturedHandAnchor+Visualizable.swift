//
//  CapturedHandAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if canImport(ARKit)
import ARKit
#endif
#if canImport(RealityKit)
import RealityKit
import Spatial

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
extension CapturedHandAnchor: Visualizable {
    struct CapturedHandComponent: Component {
        let entities: [JointName: Entity]
        let boneEntities: [JointName: Entity]
    }
    
    public func visualize(in rootEntity: Entity, with materials: [Material]) {
        switch chirality {
        case .left:
            let left = rootEntity.findEntity(named: "left") ?? Entity()
            if left.parent == nil {
                left.name = "left"
                rootEntity.addChild(left)
            }
            visualize(handIn: left, with: materials)
        case .right:
            let right = rootEntity.findEntity(named: "right") ?? Entity()
            if right.parent == nil {
                right.name = "right"
                rootEntity.addChild(right)
            }
            visualize(handIn: right, with: materials)
        }
    }
    
    @MainActor
    func visualize(handIn rootEntity: Entity, with materials: [Material]) {
        rootEntity.transform = Transform(matrix: self.originFromAnchorTransform)
        
        if !rootEntity.components.has(CapturedHandComponent.self) {
            let model = visualizationModel(materials: materials)
            let boneModel = boneModel(materials: materials)
            
            let jointEntities: [JointName: Entity] = Dictionary(uniqueKeysWithValues: JointName.allJointNames.map { joint in
                let ball = model.clone(recursive: false)
                ball.name = joint.description
                rootEntity.addChild(ball)
                return (joint, ball)
            })
            
            let boneEntities: [JointName: Entity] = Dictionary(uniqueKeysWithValues: JointName.allJointNames.compactMap { joint in
                guard joint.parentName != nil else { return nil }
                let bone = boneModel.clone(recursive: false)
                rootEntity.addChild(bone)
                return (joint, bone)
            })
            rootEntity.components.set(CapturedHandComponent(entities: jointEntities, boneEntities: boneEntities))
        }
        update(visualization: rootEntity, with: materials)
    }
    
    @MainActor private func visualizationModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generateSphere(radius: 0.005)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }
    
    @MainActor private func boneModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generateCylinder(height: 1, radius: 0.005)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }
    
    @MainActor public func update(visualization entity: Entity, with materials: @autoclosure () -> [Material]) {
        guard let component = entity.components[CapturedHandComponent.self]
        else { return }
        
        let jointEntities = component.entities
        let boneEntities = component.boneEntities
        
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        
        guard let handSkeleton else { return }
        
        for joint in handSkeleton.allJoints {
            if let existing = jointEntities[joint.name] {
                existing.transform = Transform(matrix: joint.anchorFromJointTransform)

                if let parent = joint.name.parentName,
                   let bone = boneEntities[joint.name],
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

extension HandSkeleton.JointName {
    public var rawValue: String { description }
    
    enum Error: Swift.Error {
        case decodingError
    }
}
#endif
