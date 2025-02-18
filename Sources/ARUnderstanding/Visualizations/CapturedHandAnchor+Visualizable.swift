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

extension CapturedHandAnchor: Visualizable {
    struct CapturedHandComponent: Component {
        let entities: [JointName: Entity]
    }
    
    @MainActor public func visualize(with materials: [Material]) -> Entity {
        let entity = Entity()
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        guard let handSkeleton else { return entity }
        
        let model = visualizationModel(materials: materials)
        
        for joint in handSkeleton.allJoints {
            let ball = model.clone(recursive: false)
            ball.name = joint.name.description
            ball.transform = Transform(matrix: joint.anchorFromJointTransform)
            entity.addChild(ball)
        }
        
        return entity
    }
    
    @MainActor private func visualizationModel(materials: [Material]) -> Entity {
        let mesh = MeshResource.generateSphere(radius: 0.005)
        let model = ModelEntity(mesh: mesh, materials: materials)
        return model
    }
    
    @MainActor private func createJointVisualization<Joint: HandSkeletonJointRepresentable>(joint: Joint, materials: [Material]) -> Entity {
        let ball = visualizationModel(materials: materials)
        
        ball.name = joint.name.description
        ball.transform = Transform(matrix: joint.anchorFromJointTransform)
        return ball
    }
    
    @MainActor public func update(visualization entity: Entity, with materials: @autoclosure () -> [Material]) {
        entity.transform = Transform(matrix: self.originFromAnchorTransform)
        
        guard let handSkeleton else { return }
        
        var jointEntities: [JointName: Entity] = entity.components[CapturedHandComponent.self]?.entities ?? [:]
        
        var generatedMaterials: [Material] = []
        
        for joint in handSkeleton.allJoints {
            if let existing = jointEntities[joint.name] {
                existing.transform = Transform(matrix: joint.anchorFromJointTransform)
            } else {
                generatedMaterials = generatedMaterials.isEmpty ? materials() : generatedMaterials
                let newEntity = Entity()
                let ball = createJointVisualization(joint: joint, materials: generatedMaterials)
                entity.addChild(ball)
                newEntity.transform = Transform(matrix: joint.anchorFromJointTransform)
                jointEntities[joint.name] = ball
            }
        }
        
        entity.components.set(CapturedHandComponent(entities: jointEntities))
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
