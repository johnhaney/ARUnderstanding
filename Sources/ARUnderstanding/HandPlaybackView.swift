//
//  HandPlaybackView.swift
//  HandCapture
//
//  Created by John Haney on 4/29/24.
//

//import SwiftUI
//import RealityKit
//import ARUnderstanding
//import ComponentsFromOuterSpace
//
//struct HandPlaybackView: View {
//    var anchorPlayback: AnchorPlayback
//    let leftHand = Entity()
//    let rightHand = Entity()
//    @State var firstLeft = Transform.identity
//    @State var firstRight = Transform.identity
//    
//    var body: some View {
//        RealityView { content in
//            leftHand.name = "leftHand"
//            content.add(leftHand)
//            
//            rightHand.name = "rightHand"
//            content.add(rightHand)
//            
//            let mesh = MeshResource.generateCylinder(height: 1, radius: 0.005)
//            let skeleton: Entity = {
//                let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .white, isMetallic: false)])
//                return entity
//            }()
//            for pair in [
//                ("thumbTip", "thumbIntermediateTip"),
//                ("thumbIntermediateTip", "thumbIntermediateBase"),
//                ("thumbIntermediateBase", "thumbKnuckle"),
//                ("indexFingerTip", "indexFingerIntermediateTip"),
//                ("indexFingerIntermediateTip", "indexFingerIntermediateBase"),
//                ("indexFingerIntermediateBase", "indexFingerKnuckle"),
//                ("indexFingerKnuckle", "indexFingerMetacarpal"),
//                ("middleFingerTip", "middleFingerIntermediateTip"),
//                ("middleFingerIntermediateTip", "middleFingerIntermediateBase"),
//                ("middleFingerIntermediateBase", "middleFingerKnuckle"),
//                ("middleFingerKnuckle", "middleFingerMetacarpal"),
//                ("ringFingerTip", "ringFingerIntermediateTip"),
//                ("ringFingerIntermediateTip", "ringFingerIntermediateBase"),
//                ("ringFingerIntermediateBase", "ringFingerKnuckle"),
//                ("ringFingerKnuckle", "ringFingerMetacarpal"),
//                ("littleFingerTip", "littleFingerIntermediateTip"),
//                ("littleFingerIntermediateTip", "littleFingerIntermediateBase"),
//                ("littleFingerIntermediateBase", "littleFingerKnuckle"),
//                ("littleFingerKnuckle", "littleFingerMetacarpal"),
//                ("forearmWrist", "forearmArm"),
//            ] {
//                do {
//                    let skeleton = skeleton.clone(recursive: false)
//                    skeleton.components.set(DualAnchorComponent(
//                        bottomEntityPath: ["leftHand", pair.0],
//                        topEntityPath: ["leftHand", pair.1]
//                    ))
//                    content.add(skeleton)
//                }
//                do {
//                    let skeleton = skeleton.clone(recursive: false)
//                    skeleton.components.set(DualAnchorComponent(
//                        bottomEntityPath: ["rightHand", pair.0],
//                        topEntityPath: ["rightHand", pair.1]
//                    ))
//                    content.add(skeleton)
//                }
//            }
//        }
//        .task {
//            for await someUpdate in anchorPlayback.anchorUpdates {
//                let update: CapturedAnchorUpdate<CapturedHandAnchor>
//                let skeleton: CapturedHandSkeleton
//                switch someUpdate {
//                case .hand(let capturedAnchorUpdate):
//                    update = capturedAnchorUpdate
//                    guard let handSkeleton = capturedAnchorUpdate.anchor.handSkeleton else { continue }
//                    skeleton = handSkeleton
//                default:
//                    continue
//                }
//                
//                switch update.anchor.chirality {
//                case .right:
//                    if firstRight == .identity {
//                        firstRight = Transform(matrix: update.anchor.originFromAnchorTransform)
//                    }
//                    rightHand.transform = Transform(matrix: update.anchor.originFromAnchorTransform)
//                    let average = (firstLeft.translation + firstRight.translation)/2
//                    rightHand.position -= average
//                    self.update(rightHand, handSkeleton: skeleton)
//                case .left:
//                    if firstLeft == .identity {
//                        firstLeft = Transform(matrix: update.anchor.originFromAnchorTransform)
//                    }
//                    leftHand.transform = Transform(matrix: update.anchor.originFromAnchorTransform)
//                    let average = (firstLeft.translation + firstRight.translation)/2
//                    leftHand.position -= average
//                    self.update(leftHand, handSkeleton: skeleton)
//                }
//            }
//        }
//    }
//    
//    func update(_ hand: Entity, handSkeleton skeleton: any HandSkeletonRepresentable) {
//        for joint in skeleton.allJoints {
//            let name = joint.name.description
//            let entity = hand.findEntity(named: name) ?? Entity()
//            entity.name = name
//            hand.addChild(entity)
//            entity.transform = Transform(matrix: joint.anchorFromJointTransform)
//        }
//    }
//}
//
////#Preview {
////    HandPlaybackView()
////}
