//
//  CapturedFaceAnchor+Visualizable.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if canImport(ARKit)
import ARKit
#endif
import RealityKit

extension CapturedFaceAnchor: Visualizable {
    @MainActor public func visualize(in rootEntity: Entity, with materials: [Material]) async {
        rootEntity.transform = Transform(matrix: self.originFromAnchorTransform)
        if !rootEntity.components.has(ModelComponent.self) {
            guard let mesh: MeshResource = await mesh(name: "Visualization")
            else { return }
            let model = ModelComponent(mesh: mesh, materials: materials)
            rootEntity.components.set(model)
        }
    }
}

#warning("TODO: Implement mesh generation maybe")

extension FaceAnchorRepresentable {
    func mesh(name: String) async -> MeshResource? {
        let mesh = await MeshResource.generateBox(width: 0.14, height: 0.22, depth: 0.14, cornerRadius: 0.02)
        return mesh
    }
}

//extension FaceGeometryRepresentable {
//    func mesh(name: String) async -> MeshResource? {
//        var mesh = MeshDescriptor(name: name)
//        let faces = triangleIndices.map(UInt32.init)
//        let positions = MeshBuffers.Positions(vertices)
//        do {
//            let triangles = MeshDescriptor.Primitives.triangles(faces)
////            let normals = MeshBuffers.Normals(normals)
//            
//            mesh.positions = positions
//            mesh.primitives = triangles
////            mesh.normals = normals
//        }
//        
//        do {
//            let resource = try await MeshResource(from: [mesh])
//            return resource
//        } catch {
//            print("Error creating mesh resource: \(error.localizedDescription)")
//            return nil
//        }
//    }
//}


extension Dictionary {
    func mapKeys<NewKey: Hashable>(_ keyMapping: (Key) -> NewKey) -> [NewKey: Value] {
        Dictionary<NewKey, Value>(uniqueKeysWithValues: self.map({ (key, value) in
            (keyMapping(key), value)
        }))
    }
}

#if os(iOS)
extension ARFaceAnchor.BlendShapeLocation {
    init(capturedBlendShapeLocation: CapturedFaceAnchor.BlendShapeLocation) {
        switch capturedBlendShapeLocation {
        case .eyeBlinkLeft: self = .eyeBlinkLeft
        case .eyeLookDownLeft: self = .eyeLookDownLeft
        case .eyeLookInLeft: self = .eyeLookInLeft
        case .eyeLookOutLeft: self = .eyeLookOutLeft
        case .eyeLookUpLeft: self = .eyeLookUpLeft
        case .eyeSquintLeft: self = .eyeSquintLeft
        case .eyeWideLeft: self = .eyeWideLeft
        case .eyeBlinkRight: self = .eyeBlinkRight
        case .eyeLookDownRight: self = .eyeLookDownRight
        case .eyeLookInRight: self = .eyeLookInRight
        case .eyeLookOutRight: self = .eyeLookOutRight
        case .eyeLookUpRight: self = .eyeLookUpRight
        case .eyeSquintRight: self = .eyeSquintRight
        case .eyeWideRight: self = .eyeWideRight
        case .jawForward: self = .jawForward
        case .jawLeft: self = .jawLeft
        case .jawRight: self = .jawRight
        case .jawOpen: self = .jawOpen
        case .mouthClose: self = .mouthClose
        case .mouthFunnel: self = .mouthFunnel
        case .mouthPucker: self = .mouthPucker
        case .mouthLeft: self = .mouthLeft
        case .mouthRight: self = .mouthRight
        case .mouthSmileLeft: self = .mouthSmileLeft
        case .mouthSmileRight: self = .mouthSmileRight
        case .mouthFrownLeft: self = .mouthFrownLeft
        case .mouthFrownRight: self = .mouthFrownRight
        case .mouthDimpleLeft: self = .mouthDimpleLeft
        case .mouthDimpleRight: self = .mouthDimpleRight
        case .mouthStretchLeft: self = .mouthStretchLeft
        case .mouthStretchRight: self = .mouthStretchRight
        case .mouthRollLower: self = .mouthRollLower
        case .mouthRollUpper: self = .mouthRollUpper
        case .mouthShrugLower: self = .mouthShrugLower
        case .mouthShrugUpper: self = .mouthShrugUpper
        case .mouthPressLeft: self = .mouthPressLeft
        case .mouthPressRight: self = .mouthPressRight
        case .mouthLowerDownLeft: self = .mouthLowerDownLeft
        case .mouthLowerDownRight: self = .mouthLowerDownRight
        case .mouthUpperUpLeft: self = .mouthUpperUpLeft
        case .mouthUpperUpRight: self = .mouthUpperUpRight
        case .browDownLeft: self = .browDownLeft
        case .browDownRight: self = .browDownRight
        case .browInnerUp: self = .browInnerUp
        case .browOuterUpLeft: self = .browOuterUpLeft
        case .browOuterUpRight: self = .browOuterUpRight
        case .cheekPuff: self = .cheekPuff
        case .cheekSquintLeft: self = .cheekSquintLeft
        case .cheekSquintRight: self = .cheekSquintRight
        case .noseSneerLeft: self = .noseSneerLeft
        case .noseSneerRight: self = .noseSneerRight
        }
    }
}
#endif
