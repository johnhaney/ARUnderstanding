//
//  CapturedDeviceAnchor+PackCodable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

import RealityKit
import simd
#if canImport(ARKit)
import ARKit
#endif

extension CapturedWorldAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try originFromAnchorTransform.pack())
        return output
    }
}

extension CapturedWorldAnchor: AnchorPackDecodable {
    public static func unpack(data: Data, timestamp: TimeInterval) throws -> (Self, Int) {
        guard data.count >= 16 + 1 + 16
        else {
            throw UnpackError.needsMoreData(16 + 1 + 16)
        }
        let (id, consumed) = try UUID.unpack(data: data)
        var offset = consumed
        let originFromAnchorTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            originFromAnchorTransform = transform
            offset += consumed
        }
        
        return (
            CapturedWorldAnchor(
                id: id,
                originFromAnchorTransform: originFromAnchorTransform,
                isTracked: true,
                timestamp: timestamp
            ),
            offset
        )
    }
}
