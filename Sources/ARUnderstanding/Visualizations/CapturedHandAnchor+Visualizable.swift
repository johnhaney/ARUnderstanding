//
//  CapturedHandAnchor+Visualizable.swift
//
//
//  Created by John Haney on 4/14/24.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit
import Spatial

extension CapturedHandAnchor: Visualizable {
    struct CapturedHandComponent: Component {
        let entities: [JointName: Entity]
        let boneEntities: [JointName: Entity]
    }
    
    @MainActor public func visualize(with materials: [Material]) -> Entity {
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        
        let model = visualizationModel(materials: materials)
        let boneModel = boneModel(materials: materials)
        
        let jointEntities: [JointName: Entity] = Dictionary(uniqueKeysWithValues: JointName.allJointNames.map { joint in
            let ball = model.clone(recursive: false)
            ball.name = joint.description
            entity.addChild(ball)
            return (joint, ball)
        })

        let boneEntities: [JointName: Entity] = Dictionary(uniqueKeysWithValues: JointName.allJointNames.compactMap { joint in
            guard joint.parentName != nil else { return nil }
            let bone = boneModel.clone(recursive: false)
            entity.addChild(bone)
            return (joint, bone)
        })
        entity.components.set(CapturedHandComponent(entities: jointEntities, boneEntities: boneEntities))
        update(visualization: entity, with: materials)
        return entity
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
//    init(rawValue: String) throws {
//        switch rawValue {
//        case "wrist":
//            self = .wrist
//        case "thumbKnuckle":
//            self = .thumbKnuckle
//        case "thumbIntermediateBase":
//            self = .thumbIntermediateBase
//        case "thumbIntermediateTip":
//            self = .thumbIntermediateTip
//        case "thumbTip":
//            self = .thumbTip
//        case "indexFingerMetacarpal":
//            self = .indexFingerMetacarpal
//        case "indexFingerKnuckle":
//            self = .indexFingerKnuckle
//        case "indexFingerIntermediateBase":
//            self = .indexFingerIntermediateBase
//        case "indexFingerIntermediateTip":
//            self = .indexFingerIntermediateTip
//        case "indexFingerTip":
//            self = .indexFingerTip
//        case "middleFingerMetacarpal":
//            self = .middleFingerMetacarpal
//        case "middleFingerKnuckle":
//            self = .middleFingerKnuckle
//        case "middleFingerIntermediateBase":
//            self = .middleFingerIntermediateBase
//        case "middleFingerIntermediateTip":
//            self = .middleFingerIntermediateTip
//        case "middleFingerTip":
//            self = .middleFingerTip
//        case "ringFingerMetacarpal":
//            self = .ringFingerMetacarpal
//        case "ringFingerKnuckle":
//            self = .ringFingerKnuckle
//        case "ringFingerIntermediateBase":
//            self = .ringFingerIntermediateBase
//        case "ringFingerIntermediateTip":
//            self = .ringFingerIntermediateTip
//        case "ringFingerTip":
//            self = .ringFingerTip
//        case "littleFingerMetacarpal":
//            self = .littleFingerMetacarpal
//        case "littleFingerKnuckle":
//            self = .littleFingerKnuckle
//        case "littleFingerIntermediateBase":
//            self = .littleFingerIntermediateBase
//        case "littleFingerIntermediateTip":
//            self = .littleFingerIntermediateTip
//        case "littleFingerTip":
//            self = .littleFingerTip
//        case "forearmWrist":
//            self = .forearmWrist
//        case "forearmArm":
//            self = .forearmArm
//        default:
//            throw Error.decodingError
//        }
//    }
    
    public var rawValue: String { description }
    
    enum Error: Swift.Error {
        case decodingError
    }
}
