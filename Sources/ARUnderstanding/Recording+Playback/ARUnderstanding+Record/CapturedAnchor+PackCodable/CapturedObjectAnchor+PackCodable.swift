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

extension CapturedObjectAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try originFromAnchorTransform.pack())
        if let referenceObjectNameData = referenceObjectName.data(using: .utf8) {
            output.append(try referenceObjectNameData.count.pack())
            output.append(referenceObjectNameData)
        } else {
            output.append(try Int.zero.pack())
        }
        return output
    }
}

extension CapturedObjectAnchor: PackDecodable {
    public static func unpack(data: Data) throws -> (Self, Int) {
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
        let referenceObjectName: String
        do {
            let (length, consumed) = try Int.unpack(data: data[(data.startIndex + offset)...])
            offset += consumed
            if length > 0 {
                referenceObjectName = String(data: data[(data.startIndex + offset)..<(data.startIndex + offset + length)], encoding: .utf8) ?? ""
                offset += length
            } else {
                referenceObjectName = ""
            }
        }

        return (
            CapturedObjectAnchor(
                id: id,
                originFromAnchorTransform: originFromAnchorTransform,
                referenceObjectName: referenceObjectName,
                isTracked: true
            ),
            offset
        )
    }
}
