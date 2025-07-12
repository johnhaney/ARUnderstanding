//
//  CapturedDeviceAnchor+PackCodable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

#if canImport(RealityKit)
import RealityKit
#endif
import simd
#if canImport(ARKit)
import ARKit
#endif

extension CapturedDeviceAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try originFromAnchorTransform.pack())
        return output
    }
}

extension CapturedDeviceAnchor: PackDecodable {
    public static func unpack(data: Data) throws -> (Self, Int) {
        guard data.count >= 16 + 64
        else {
            throw UnpackError.needsMoreData(16 + 64)
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
            CapturedDeviceAnchor(
                id: id,
                originFromAnchorTransform: originFromAnchorTransform,
                isTracked: true
            ),
            offset
        )
    }
}
