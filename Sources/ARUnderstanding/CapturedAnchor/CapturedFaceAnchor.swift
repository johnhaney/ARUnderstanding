//
//  CapturedFaceAnchor.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

import Foundation
#if canImport(ARKit)
import ARKit
#endif
#if canImport(RealityKit)
import RealityKit
#endif
import simd

public protocol FaceAnchorRepresentable: CapturableAnchor {
    associatedtype BlendShapeLocation: BlendShapeLocationRepresentable
    var identifier: UUID { get }
    var transform: simd_float4x4 { get }
    var leftEyeTransform: simd_float4x4 { get }
    var rightEyeTransform: simd_float4x4 { get }
    var lookAtPoint: simd_float3 { get }
    var blendShapes: [BlendShapeLocation: NSNumber] { get }
    var description: String { get }
//    var geometry: FaceGeometry { get }
}

//protocol FaceGeometryRepresentable: Hashable {
//    var vertices: [simd_float3] { get }
//    var textureCoordinates: [vector_float2] { get }
//    var triangleCount: Int { get }
//    var triangleIndices: [Int16] { get }
//}

public protocol BlendShapeLocationRepresentable: Hashable {
    static var eyeBlinkLeft: Self { get }
    static var eyeLookDownLeft: Self { get }
    static var eyeLookInLeft: Self { get }
    static var eyeLookOutLeft: Self { get }
    static var eyeLookUpLeft: Self { get }
    static var eyeSquintLeft: Self { get }
    static var eyeWideLeft: Self { get }
    static var eyeBlinkRight: Self { get }
    static var eyeLookDownRight: Self { get }
    static var eyeLookInRight: Self { get }
    static var eyeLookOutRight: Self { get }
    static var eyeLookUpRight: Self { get }
    static var eyeSquintRight: Self { get }
    static var eyeWideRight: Self { get }
    static var jawForward: Self { get }
    static var jawLeft: Self { get }
    static var jawRight: Self { get }
    static var jawOpen: Self { get }
    static var mouthClose: Self { get }
    static var mouthFunnel: Self { get }
    static var mouthPucker: Self { get }
    static var mouthLeft: Self { get }
    static var mouthRight: Self { get }
    static var mouthSmileLeft: Self { get }
    static var mouthSmileRight: Self { get }
    static var mouthFrownLeft: Self { get }
    static var mouthFrownRight: Self { get }
    static var mouthDimpleLeft: Self { get }
    static var mouthDimpleRight: Self { get }
    static var mouthStretchLeft: Self { get }
    static var mouthStretchRight: Self { get }
    static var mouthRollLower: Self { get }
    static var mouthRollUpper: Self { get }
    static var mouthShrugLower: Self { get }
    static var mouthShrugUpper: Self { get }
    static var mouthPressLeft: Self { get }
    static var mouthPressRight: Self { get }
    static var mouthLowerDownLeft: Self { get }
    static var mouthLowerDownRight: Self { get }
    static var mouthUpperUpLeft: Self { get }
    static var mouthUpperUpRight: Self { get }
    static var browDownLeft: Self { get }
    static var browDownRight: Self { get }
    static var browInnerUp: Self { get }
    static var browOuterUpLeft: Self { get }
    static var browOuterUpRight: Self { get }
    static var cheekPuff: Self { get }
    static var cheekSquintLeft: Self { get }
    static var cheekSquintRight: Self { get }
    static var noseSneerLeft: Self { get }
    static var noseSneerRight: Self { get }
}

extension BlendShapeLocationRepresentable {
    public static var allCases: [Self] {
        [
            .eyeBlinkLeft,
                .eyeLookDownLeft,
                .eyeLookInLeft,
                .eyeLookOutLeft,
                .eyeLookUpLeft,
                .eyeSquintLeft,
                .eyeWideLeft,
                .eyeBlinkRight,
                .eyeLookDownRight,
                .eyeLookInRight,
                .eyeLookOutRight,
                .eyeLookUpRight,
                .eyeSquintRight,
                .eyeWideRight,
                .jawForward,
                .jawLeft,
                .jawRight,
                .jawOpen,
                .mouthClose,
                .mouthFunnel,
                .mouthPucker,
                .mouthLeft,
                .mouthRight,
                .mouthSmileLeft,
                .mouthSmileRight,
                .mouthFrownLeft,
                .mouthFrownRight,
                .mouthDimpleLeft,
                .mouthDimpleRight,
                .mouthStretchLeft,
                .mouthStretchRight,
                .mouthRollLower,
                .mouthRollUpper,
                .mouthShrugLower,
                .mouthShrugUpper,
                .mouthPressLeft,
                .mouthPressRight,
                .mouthLowerDownLeft,
                .mouthLowerDownRight,
                .mouthUpperUpLeft,
                .mouthUpperUpRight,
                .browDownLeft,
                .browDownRight,
                .browInnerUp,
                .browOuterUpLeft,
                .browOuterUpRight,
                .cheekPuff,
                .cheekSquintLeft,
                .cheekSquintRight,
                .noseSneerLeft,
                .noseSneerRight,
        ]
    }
}

public struct CapturedFaceAnchor: CapturableAnchor, FaceAnchorRepresentable, Sendable, Equatable {
    public static func == (lhs: CapturedFaceAnchor, rhs: CapturedFaceAnchor) -> Bool {
        lhs.identifier == rhs.identifier &&
        lhs.transform == rhs.transform &&
        lhs.leftEyeTransform == rhs.leftEyeTransform &&
        lhs.rightEyeTransform == rhs.rightEyeTransform &&
        lhs.lookAtPoint == rhs.lookAtPoint &&
        lhs.blendShapes == rhs.blendShapes
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(transform)
        hasher.combine(leftEyeTransform)
        hasher.combine(rightEyeTransform)
        hasher.combine(lookAtPoint)
        hasher.combine(blendShapes)
    }
    
    public typealias BlendShapeLocation = CapturedBlendShapeLocation
    public var blendShapes: [CapturedBlendShapeLocation : NSNumber] { _blendShapes() }
    let _blendShapes: @Sendable () -> [CapturedBlendShapeLocation : NSNumber]
    public var identifier: UUID
    public var transform: simd_float4x4
    public var leftEyeTransform: simd_float4x4
    public var rightEyeTransform: simd_float4x4
    public var lookAtPoint: simd_float3
    public var description: String
    public var id: UUID { identifier }
    public var originFromAnchorTransform: simd_float4x4 { transform }
    
    init<T: FaceAnchorRepresentable>(captured: T) {
        _blendShapes = { captured.blendShapes.captured }
        identifier = captured.identifier
        transform = captured.transform
        leftEyeTransform = captured.leftEyeTransform
        rightEyeTransform = captured.rightEyeTransform
        lookAtPoint = captured.lookAtPoint
        description = "Face \(captured.transform)"
    }
}

public struct SavedFaceAnchor: CapturableAnchor, FaceAnchorRepresentable, Sendable, Equatable {
    public typealias BlendShapeLocation = CapturedBlendShapeLocation
    
    public var originFromAnchorTransform: simd_float4x4 { transform }
    
    public var id: UUID { identifier }
    public var identifier: UUID
    public var description: String { "Face \(transform)"}
    public var transform: simd_float4x4
    public var leftEyeTransform: simd_float4x4
    public var rightEyeTransform: simd_float4x4
    public var lookAtPoint: simd_float3
    public var floatBlendShapes: [BlendShapeLocation: Float]
    public var blendShapes: [BlendShapeLocation: NSNumber] { floatBlendShapes.mapValues(NSNumber.init) }
}

public enum CapturedBlendShapeLocation: BlendShapeLocationRepresentable, CaseIterable, Sendable {
    case eyeBlinkLeft
    case eyeLookDownLeft
    case eyeLookInLeft
    case eyeLookOutLeft
    case eyeLookUpLeft
    case eyeSquintLeft
    case eyeWideLeft
    case eyeBlinkRight
    case eyeLookDownRight
    case eyeLookInRight
    case eyeLookOutRight
    case eyeLookUpRight
    case eyeSquintRight
    case eyeWideRight
    case jawForward
    case jawLeft
    case jawRight
    case jawOpen
    case mouthClose
    case mouthFunnel
    case mouthPucker
    case mouthLeft
    case mouthRight
    case mouthSmileLeft
    case mouthSmileRight
    case mouthFrownLeft
    case mouthFrownRight
    case mouthDimpleLeft
    case mouthDimpleRight
    case mouthStretchLeft
    case mouthStretchRight
    case mouthRollLower
    case mouthRollUpper
    case mouthShrugLower
    case mouthShrugUpper
    case mouthPressLeft
    case mouthPressRight
    case mouthLowerDownLeft
    case mouthLowerDownRight
    case mouthUpperUpLeft
    case mouthUpperUpRight
    case browDownLeft
    case browDownRight
    case browInnerUp
    case browOuterUpLeft
    case browOuterUpRight
    case cheekPuff
    case cheekSquintLeft
    case cheekSquintRight
    case noseSneerLeft
    case noseSneerRight
}

extension BlendShapeLocationRepresentable {
    var captured: CapturedBlendShapeLocation? {
        CapturedBlendShapeLocation(rawValue: rawValue)
    }
}

extension Dictionary where Key: BlendShapeLocationRepresentable {
    var captured: Dictionary<CapturedBlendShapeLocation, Value> {
        Dictionary<CapturedBlendShapeLocation, Value>(uniqueKeysWithValues: compactMap { (key, value) in
            if let newKey = key.captured {
                (newKey, value)
            } else {
                nil
            }
        })
    }
}

extension BlendShapeLocationRepresentable {
    init?(_ shape: any BlendShapeLocationRepresentable) {
        self.init(rawValue: shape.rawValue)
    }
    
    var rawValue: Int {
        switch self {
        case .eyeBlinkLeft: 1
        case .eyeLookDownLeft: 2
        case .eyeLookInLeft: 3
        case .eyeLookOutLeft: 4
        case .eyeLookUpLeft: 5
        case .eyeSquintLeft:6
        case .eyeWideLeft: 7
        case .eyeBlinkRight: 8
        case .eyeLookDownRight:9
        case .eyeLookInRight: 10
        case .eyeLookOutRight: 11
        case .eyeLookUpRight: 12
        case .eyeSquintRight:13
        case .eyeWideRight:14
        case .jawForward:15
        case .jawLeft: 16
        case .jawRight: 17
        case .jawOpen: 18
        case .mouthClose: 19
        case .mouthFunnel: 20
        case .mouthPucker:21
        case .mouthLeft: 22
        case .mouthRight: 23
        case .mouthSmileLeft: 24
        case .mouthSmileRight: 25
        case .mouthFrownLeft: 26
        case .mouthFrownRight: 27
        case .mouthDimpleLeft: 28
        case .mouthDimpleRight: 29
        case .mouthStretchLeft: 30
        case .mouthStretchRight:31
        case .mouthRollLower: 32
        case .mouthRollUpper: 33
        case .mouthShrugLower: 34
        case .mouthShrugUpper: 35
        case .mouthPressLeft: 36
        case .mouthPressRight: 37
        case .mouthLowerDownLeft: 38
        case .mouthLowerDownRight:39
        case .mouthUpperUpLeft: 40
        case .mouthUpperUpRight:41
        case .browDownLeft: 42
        case .browDownRight:43
        case .browInnerUp: 44
        case .browOuterUpLeft: 45
        case .browOuterUpRight:46
        case .cheekPuff: 47
        case .cheekSquintLeft: 48
        case .cheekSquintRight:49
        case .noseSneerLeft: 50
        case .noseSneerRight: 51
        default: 0
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
        case 1: self = .eyeBlinkLeft
        case 2: self = .eyeLookDownLeft
        case 3: self = .eyeLookInLeft
        case 4: self = .eyeLookOutLeft
        case 5: self = .eyeLookUpLeft
        case 6: self = .eyeSquintLeft
        case 7: self = .eyeWideLeft
        case 8: self = .eyeBlinkRight
        case 9: self = .eyeLookDownRight
        case 10: self = .eyeLookInRight
        case 11: self = .eyeLookOutRight
        case 12: self = .eyeLookUpRight
        case 13: self = .eyeSquintRight
        case 14: self = .eyeWideRight
        case 15: self = .jawForward
        case 16: self = .jawLeft
        case 17: self = .jawRight
        case 18: self = .jawOpen
        case 19: self = .mouthClose
        case 20: self = .mouthFunnel
        case 21: self = .mouthPucker
        case 22: self = .mouthLeft
        case 23: self = .mouthRight
        case 24: self = .mouthSmileLeft
        case 25: self = .mouthSmileRight
        case 26: self = .mouthFrownLeft
        case 27: self = .mouthFrownRight
        case 28: self = .mouthDimpleLeft
        case 29: self = .mouthDimpleRight
        case 30: self = .mouthStretchLeft
        case 31: self = .mouthStretchRight
        case 32: self = .mouthRollLower
        case 33: self = .mouthRollUpper
        case 34: self = .mouthShrugLower
        case 35: self = .mouthShrugUpper
        case 36: self = .mouthPressLeft
        case 37: self = .mouthPressRight
        case 38: self = .mouthLowerDownLeft
        case 39: self = .mouthLowerDownRight
        case 40: self = .mouthUpperUpLeft
        case 41: self = .mouthUpperUpRight
        case 42: self = .browDownLeft
        case 43: self = .browDownRight
        case 44: self = .browInnerUp
        case 45: self = .browOuterUpLeft
        case 46: self = .browOuterUpRight
        case 47: self = .cheekPuff
        case 48: self = .cheekSquintLeft
        case 49: self = .cheekSquintRight
        case 50: self = .noseSneerLeft
        case 51: self = .noseSneerRight
        default: return nil
        }
    }
}

extension FaceAnchorRepresentable {
    public var captured: CapturedFaceAnchor {
        if let captured = self as? CapturedFaceAnchor {
            captured
        } else {
            CapturedFaceAnchor(captured: self)
        }
    }
}

//extension FaceGeometryRepresentable {
//    public var captured: CapturedFaceAnchor.Geometry {
//        CapturedFaceAnchor.Geometry(vertices: vertices)
//    }
//}
//
//extension BlendShapeLocationRepresentable {
//    public static var allCases: [Self] {
//        [
//            .eyeBlinkLeft,
//            .eyeLookDownLeft,
//            .eyeLookInLeft,
//            .eyeLookOutLeft,
//            .eyeLookUpLeft,
//            .eyeSquintLeft,
//            .eyeWideLeft,
//            .eyeBlinkRight,
//            .eyeLookDownRight,
//            .eyeLookInRight,
//            .eyeLookOutRight,
//            .eyeLookUpRight,
//            .eyeSquintRight,
//            .eyeWideRight,
//            .jawForward,
//            .jawLeft,
//            .jawRight,
//            .jawOpen,
//            .mouthClose,
//            .mouthFunnel,
//            .mouthPucker,
//            .mouthLeft,
//            .mouthRight,
//            .mouthSmileLeft,
//            .mouthSmileRight,
//            .mouthFrownLeft,
//            .mouthFrownRight,
//            .mouthDimpleLeft,
//            .mouthDimpleRight,
//            .mouthStretchLeft,
//            .mouthStretchRight,
//            .mouthRollLower,
//            .mouthRollUpper,
//            .mouthShrugLower,
//            .mouthShrugUpper,
//            .mouthPressLeft,
//            .mouthPressRight,
//            .mouthLowerDownLeft,
//            .mouthLowerDownRight,
//            .mouthUpperUpLeft,
//            .mouthUpperUpRight,
//            .browDownLeft,
//            .browDownRight,
//            .browInnerUp,
//            .browOuterUpLeft,
//            .browOuterUpRight,
//            .cheekPuff,
//            .cheekSquintLeft,
//            .cheekSquintRight,
//            .noseSneerLeft,
//            .noseSneerRight,
//        ]
//    }
//}
//
//public enum CapturedFaceAnchor: Anchor, Sendable, Equatable, Hashable, Identifiable {
//    #if os(iOS)
//    case live(FaceAnchor)
//    #endif
//    case saved(SavedFaceAnchor)
//    
//    public var anchor: any FaceAnchorRepresentable {
//        switch self {
//        #if os(iOS)
//        case .live(let liveAnchor):
//            liveAnchor
//        #endif
//        case .saved(let savedAnchor):
//            savedAnchor
//        }
//    }
//    
//    public var originFromAnchorTransform: simd_float4x4 { anchor.transform }
//    public var description: String { anchor.description }
//    public var id: UUID { anchor.identifier }
//    
//    // ARAnchor
//    public var transform: simd_float4x4 { anchor.transform }
//    public var identifier: UUID { anchor.identifier }
//}
//
//public struct SavedFaceAnchor: CapturableAnchor, FaceAnchorRepresentable, Sendable, Equatable {
//    public typealias BlendShapeLocation = SavedBlendShapeLocation
//    
//    public var originFromAnchorTransform: simd_float4x4 { transform }
//    
//    public var id: UUID { identifier }
//    public var identifier: UUID
//    public var description: String { "Face \(transform)"}
//    public var transform: simd_float4x4
//    public var leftEyeTransform: simd_float4x4
//    public var rightEyeTransform: simd_float4x4
//    public var lookAtPoint: simd_float3
//    public var floatBlendShapes: [BlendShapeLocation: Float]
//    public var blendShapes: [BlendShapeLocation: NSNumber] { floatBlendShapes.mapValues(NSNumber.init) }
//    
//    public enum SavedBlendShapeLocation: BlendShapeLocationRepresentable, CaseIterable, Sendable {
//        case eyeBlinkLeft
//        case eyeLookDownLeft
//        case eyeLookInLeft
//        case eyeLookOutLeft
//        case eyeLookUpLeft
//        case eyeSquintLeft
//        case eyeWideLeft
//        case eyeBlinkRight
//        case eyeLookDownRight
//        case eyeLookInRight
//        case eyeLookOutRight
//        case eyeLookUpRight
//        case eyeSquintRight
//        case eyeWideRight
//        case jawForward
//        case jawLeft
//        case jawRight
//        case jawOpen
//        case mouthClose
//        case mouthFunnel
//        case mouthPucker
//        case mouthLeft
//        case mouthRight
//        case mouthSmileLeft
//        case mouthSmileRight
//        case mouthFrownLeft
//        case mouthFrownRight
//        case mouthDimpleLeft
//        case mouthDimpleRight
//        case mouthStretchLeft
//        case mouthStretchRight
//        case mouthRollLower
//        case mouthRollUpper
//        case mouthShrugLower
//        case mouthShrugUpper
//        case mouthPressLeft
//        case mouthPressRight
//        case mouthLowerDownLeft
//        case mouthLowerDownRight
//        case mouthUpperUpLeft
//        case mouthUpperUpRight
//        case browDownLeft
//        case browDownRight
//        case browInnerUp
//        case browOuterUpLeft
//        case browOuterUpRight
//        case cheekPuff
//        case cheekSquintLeft
//        case cheekSquintRight
//        case noseSneerLeft
//        case noseSneerRight
//    }
//}
//
//extension BlendShapeLocationRepresentable {
//    init?(_ shape: any BlendShapeLocationRepresentable) {
//        self.init(rawValue: shape.rawValue)
//    }
//    
//    var rawValue: Int {
//        switch self {
//        case .eyeBlinkLeft: 1
//        case .eyeLookDownLeft: 2
//        case .eyeLookInLeft: 3
//        case .eyeLookOutLeft: 4
//        case .eyeLookUpLeft: 5
//        case .eyeSquintLeft:6
//        case .eyeWideLeft: 7
//        case .eyeBlinkRight: 8
//        case .eyeLookDownRight:9
//        case .eyeLookInRight: 10
//        case .eyeLookOutRight: 11
//        case .eyeLookUpRight: 12
//        case .eyeSquintRight:13
//        case .eyeWideRight:14
//        case .jawForward:15
//        case .jawLeft: 16
//        case .jawRight: 17
//        case .jawOpen: 18
//        case .mouthClose: 19
//        case .mouthFunnel: 20
//        case .mouthPucker:21
//        case .mouthLeft: 22
//        case .mouthRight: 23
//        case .mouthSmileLeft: 24
//        case .mouthSmileRight: 25
//        case .mouthFrownLeft: 26
//        case .mouthFrownRight: 27
//        case .mouthDimpleLeft: 28
//        case .mouthDimpleRight: 29
//        case .mouthStretchLeft: 30
//        case .mouthStretchRight:31
//        case .mouthRollLower: 32
//        case .mouthRollUpper: 33
//        case .mouthShrugLower: 34
//        case .mouthShrugUpper: 35
//        case .mouthPressLeft: 36
//        case .mouthPressRight: 37
//        case .mouthLowerDownLeft: 38
//        case .mouthLowerDownRight:39
//        case .mouthUpperUpLeft: 40
//        case .mouthUpperUpRight:41
//        case .browDownLeft: 42
//        case .browDownRight:43
//        case .browInnerUp: 44
//        case .browOuterUpLeft: 45
//        case .browOuterUpRight:46
//        case .cheekPuff: 47
//        case .cheekSquintLeft: 48
//        case .cheekSquintRight:49
//        case .noseSneerLeft: 50
//        case .noseSneerRight: 51
//        default: 0
//        }
//    }
//    
//    init?(rawValue: Int) {
//        switch rawValue {
//        case 1: self = .eyeBlinkLeft
//        case 2: self = .eyeLookDownLeft
//        case 3: self = .eyeLookInLeft
//        case 4: self = .eyeLookOutLeft
//        case 5: self = .eyeLookUpLeft
//        case 6: self = .eyeSquintLeft
//        case 7: self = .eyeWideLeft
//        case 8: self = .eyeBlinkRight
//        case 9: self = .eyeLookDownRight
//        case 10: self = .eyeLookInRight
//        case 11: self = .eyeLookOutRight
//        case 12: self = .eyeLookUpRight
//        case 13: self = .eyeSquintRight
//        case 14: self = .eyeWideRight
//        case 15: self = .jawForward
//        case 16: self = .jawLeft
//        case 17: self = .jawRight
//        case 18: self = .jawOpen
//        case 19: self = .mouthClose
//        case 20: self = .mouthFunnel
//        case 21: self = .mouthPucker
//        case 22: self = .mouthLeft
//        case 23: self = .mouthRight
//        case 24: self = .mouthSmileLeft
//        case 25: self = .mouthSmileRight
//        case 26: self = .mouthFrownLeft
//        case 27: self = .mouthFrownRight
//        case 28: self = .mouthDimpleLeft
//        case 29: self = .mouthDimpleRight
//        case 30: self = .mouthStretchLeft
//        case 31: self = .mouthStretchRight
//        case 32: self = .mouthRollLower
//        case 33: self = .mouthRollUpper
//        case 34: self = .mouthShrugLower
//        case 35: self = .mouthShrugUpper
//        case 36: self = .mouthPressLeft
//        case 37: self = .mouthPressRight
//        case 38: self = .mouthLowerDownLeft
//        case 39: self = .mouthLowerDownRight
//        case 40: self = .mouthUpperUpLeft
//        case 41: self = .mouthUpperUpRight
//        case 42: self = .browDownLeft
//        case 43: self = .browDownRight
//        case 44: self = .browInnerUp
//        case 45: self = .browOuterUpLeft
//        case 46: self = .browOuterUpRight
//        case 47: self = .cheekPuff
//        case 48: self = .cheekSquintLeft
//        case 49: self = .cheekSquintRight
//        case 50: self = .noseSneerLeft
//        case 51: self = .noseSneerRight
//        default: return nil
//        }
//    }
//}
//
//extension FaceAnchorRepresentable {
//    public var captured: CapturedFaceAnchor {
//        #if os(iOS)
//        if let self = self as? FaceAnchor {
//            CapturedFaceAnchor.live(self)
//        } else {
//            CapturedFaceAnchor.saved(self.saved)
//        }
//        #else
//        CapturedFaceAnchor.saved(self.saved)
//        #endif
//    }
//    
//    public var saved: SavedFaceAnchor {
//        if let saved = self as? SavedFaceAnchor {
//            return saved
//        } else {
//            let savedBlendShapes: [SavedFaceAnchor.BlendShapeLocation: Float] = Dictionary(uniqueKeysWithValues: blendShapes.compactMap({
//                if let key = SavedFaceAnchor.BlendShapeLocation($0.key) {
//                    return (key, $0.value.floatValue)
//                } else {
//                    return nil
//                }
//            }))
//            return SavedFaceAnchor(
//                identifier: identifier,
//                transform: transform,
//                leftEyeTransform: leftEyeTransform,
//                rightEyeTransform: rightEyeTransform,
//                lookAtPoint: lookAtPoint,
//                floatBlendShapes: savedBlendShapes
//            )
//        }
//    }
//}
//
////extension FaceGeometryRepresentable {
////    public var captured: CapturedFaceAnchor.Geometry {
////        CapturedFaceAnchor.Geometry(vertices: vertices)
////    }
////}
