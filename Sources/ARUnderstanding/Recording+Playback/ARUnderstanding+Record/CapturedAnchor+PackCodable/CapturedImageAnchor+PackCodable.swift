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

extension CapturedImageAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try originFromAnchorTransform.pack())
        output.append(try estimatedPhysicalWidth.pack())
        output.append(try estimatedPhysicalHeight.pack())
        output.append(try estimatedScaleFactor.pack())
        if let referenceImageNameData = referenceImageName?.data(using: .utf8) {
            output.append(try referenceImageNameData.count.pack())
            output.append(referenceImageNameData)
        } else {
            output.append(try Int.zero.pack())
        }
        return output
    }
}

extension CapturedImageAnchor: PackDecodable {
    public static func unpack(data: Data) throws -> (Self, Int) {
        guard data.count >= 16 + 16 + 4
        else {
            throw UnpackError.needsMoreData(16 + 16 + 4)
        }
        let (id, consumed) = try UUID.unpack(data: data)
        var offset = consumed
        let originFromAnchorTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            originFromAnchorTransform = transform
            offset += consumed
        }
        let estimatedPhysicalWidth: Float
        let estimatedPhysicalHeight: Float
        let estimatedScaleFactor: Float
        do {
            let (floats, consumed) = try Float.unpack(data: data[(data.startIndex + offset)...], count: 3)
            estimatedPhysicalWidth = floats[0]
            estimatedPhysicalHeight = floats[1]
            estimatedScaleFactor = floats[2]
            offset += consumed
        }
        let referenceImageName: String?
        do {
            let (length, consumed) = try Int.unpack(data: data[(data.startIndex + offset)...])
            offset += consumed
            if length > 0 {
                referenceImageName = String(data: data[(data.startIndex + offset)..<(data.startIndex + offset + length)], encoding: .utf8)
                offset += length
            } else {
                referenceImageName = nil
            }
        }

        return (
            CapturedImageAnchor(
                id: id,
                originFromAnchorTransform: originFromAnchorTransform,
                isTracked: true,
                referenceImageName: referenceImageName,
                estimatedScaleFactor: estimatedScaleFactor,
                estimatedPhysicalWidth: estimatedPhysicalWidth,
                estimatedPhysicalHeight: estimatedPhysicalHeight
            ),
            offset
        )
    }
}
