//
//  CapturedFaceAnchor+PackCodable.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

import Foundation
#if canImport(RealityKit)
import RealityKit
#endif
import simd

extension CapturedFaceAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try identifier.pack())
        output.append(try transform.pack())
        output.append(try leftEyeTransform.pack())
        output.append(try rightEyeTransform.pack())
        output.append(try lookAtPoint.pack())
        for shape in BlendShapeLocation.allCases {
            output.append(try Float(blendShapes[shape] ?? 0).pack())
        }
        return output
    }
}

extension CapturedFaceAnchor: PackDecodable {
    public static func unpack(data: Data) throws -> (CapturedFaceAnchor, Int) {
        guard data.count >= 16 + 64 + 64 + 64 + 12 + 51*4
        else {
            throw UnpackError.needsMoreData(16 + 64 + 64 + 64 + 12 + 51*4)
        }
        let (id, consumed) = try UUID.unpack(data: data)
        var offset = consumed
        let originFromAnchorTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            originFromAnchorTransform = transform
            offset += consumed
        }
        let leftEyeTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            leftEyeTransform = transform
            offset += consumed
        }
        let rightEyeTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            rightEyeTransform = transform
            offset += consumed
        }
        let lookAtPoint: simd_float3
        do {
            let (point, consumed) = try simd_float3.unpack(data: data[(data.startIndex + offset)...])
            lookAtPoint = point
            offset += consumed
        }

        let floatBlendShapes: [CapturedFaceAnchor.BlendShapeLocation: Float]
        do {
            let (locations, consumed) = try Float.unpack(data: data[(data.startIndex + offset)...], count: 51)
            floatBlendShapes = [
                .eyeBlinkLeft: locations[0],
                .eyeLookDownLeft: locations[1],
                .eyeLookInLeft: locations[2],
                .eyeLookOutLeft: locations[3],
                .eyeLookUpLeft: locations[4],
                .eyeSquintLeft: locations[5],
                .eyeWideLeft: locations[6],
                .eyeBlinkRight: locations[7],
                .eyeLookDownRight: locations[8],
                .eyeLookInRight: locations[9],
                .eyeLookOutRight: locations[10],
                .eyeLookUpRight: locations[11],
                .eyeSquintRight: locations[12],
                .eyeWideRight: locations[13],
                .jawForward: locations[14],
                .jawLeft: locations[15],
                .jawRight: locations[16],
                .jawOpen: locations[17],
                .mouthClose: locations[18],
                .mouthFunnel: locations[19],
                .mouthPucker: locations[20],
                .mouthLeft: locations[21],
                .mouthRight: locations[22],
                .mouthSmileLeft: locations[23],
                .mouthSmileRight: locations[24],
                .mouthFrownLeft: locations[25],
                .mouthFrownRight: locations[26],
                .mouthDimpleLeft: locations[27],
                .mouthDimpleRight: locations[28],
                .mouthStretchLeft: locations[29],
                .mouthStretchRight: locations[30],
                .mouthRollLower: locations[31],
                .mouthRollUpper: locations[32],
                .mouthShrugLower: locations[33],
                .mouthShrugUpper: locations[34],
                .mouthPressLeft: locations[35],
                .mouthPressRight: locations[36],
                .mouthLowerDownLeft: locations[37],
                .mouthLowerDownRight: locations[38],
                .mouthUpperUpLeft: locations[39],
                .mouthUpperUpRight: locations[40],
                .browDownLeft: locations[41],
                .browDownRight: locations[42],
                .browInnerUp: locations[43],
                .browOuterUpLeft: locations[44],
                .browOuterUpRight: locations[45],
                .cheekPuff: locations[46],
                .cheekSquintLeft: locations[47],
                .cheekSquintRight: locations[48],
                .noseSneerLeft: locations[49],
                .noseSneerRight: locations[50]
            ]
            offset += consumed
        }
        
        return (
            SavedFaceAnchor(
                identifier: id,
                transform: originFromAnchorTransform,
                leftEyeTransform: leftEyeTransform,
                rightEyeTransform: rightEyeTransform,
                lookAtPoint: lookAtPoint,
                floatBlendShapes: floatBlendShapes
            ).captured,
            offset
        )
    }
}

//extension SavedFaceAnchor.Geometry: PackCodable {
//    public func pack() throws -> Data {
//        var output: Data = Data()
//        output.append(try vertices.count.pack())
//        for v in vertices {
//            output.append(try v.pack())
//        }
//        return output
//    }
//    
//    public static func unpack(data: Data) throws -> (SavedFaceAnchor.Geometry, Int) {
//        guard data.count >= 8
//        else {
//            throw UnpackError.needsMoreData(8)
//        }
//        let (numVertices, consumed) = try Int.unpack(data: data)
//        var offset = consumed
//        let vertices: [SIMD3<Float>]
//        do {
//            let (v, consumed) = try SIMD3<Float>.unpack(data: data[(data.startIndex + offset)...], count: numVertices)
//            offset += consumed
//            vertices = v
//        }
//        
//        let geometry = SavedFaceAnchor.Geometry(vertices: vertices)
//        return (geometry, offset)
//    }
//    
//}
