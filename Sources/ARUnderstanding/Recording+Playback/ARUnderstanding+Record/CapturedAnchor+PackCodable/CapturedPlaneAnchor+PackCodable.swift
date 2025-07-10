//
//  CapturedPlaneAnchor+PackCodable.swift
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

extension CapturedPlaneAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(contentsOf: [classification.code, alignment.code])
        output.append(try originFromAnchorTransform.pack())
        output.append(try geometry.pack())
        return output
    }
}

extension CapturedPlaneAnchor: PackDecodable {
    public static func unpack(data: Data) throws -> (Self, Int) {
        guard data.count >= 16 + 2 + 64
        else { throw UnpackError.needsMoreData(16 + 2 + 64) }
        let (id, consumed) = try UUID.unpack(data: data)
        var offset = consumed
        
        let classification = PlaneAnchor.Classification(code: data[(data.startIndex + offset)])
        offset += 1
        let alignment = PlaneAnchor.Alignment(code: data[(data.startIndex + offset)])
        offset += 1
        
        let originFromAnchorTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            originFromAnchorTransform = transform
            offset += consumed
        }
        let geometry: CapturedPlaneAnchor.Geometry

        do {
            let (g, consumed) = try CapturedPlaneAnchor.Geometry.unpack(data: data[(data.startIndex + offset)...])
            geometry = g
            offset += consumed
        }
        
        return (
            CapturedPlaneAnchor(
                id: id,
                originFromAnchorTransform: originFromAnchorTransform,
                geometry: geometry,
                classification: classification,
                alignment: alignment
            ),
            offset
        )
    }
}

extension PlaneAnchor.Alignment {
    var code: UInt8 {
        switch self {
        case .horizontal: UInt8(1)
        case .vertical: UInt8(2)
        case .slanted: UInt8(3)
        @unknown default: UInt8(0)
        }
    }
    
    init(code: UInt8) {
        switch code {
        case 1: self = .horizontal
        case 2: self = .vertical
        case 3: self = .slanted
        default: self = .horizontal
        }
    }
}

extension PlaneAnchor.Classification {
    var code: UInt8 {
        switch self {
        case .notAvailable: UInt8(0)
        case .undetermined: UInt8(1)
        case .unknown: UInt8(2)
        case .wall: UInt8(3)
        case .floor: UInt8(4)
        case .ceiling: UInt8(5)
        case .table: UInt8(6)
        case .seat: UInt8(7)
        case .window: UInt8(8)
        case .door: UInt8(9)
        @unknown default: UInt8.max
        }
    }
    
    init(code: UInt8) {
        switch code {
        case 0: self = .notAvailable
        case 1: self = .undetermined
        case 2: self = .unknown
        case 3: self = .wall
        case 4: self = .floor
        case 5: self = .ceiling
        case 6: self = .table
        case 7: self = .seat
        case 8: self = .window
        case 9: self = .door
        default: self = .unknown
        }
    }
}

extension CapturedPlaneAnchor.Geometry: PackCodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try extent.width.pack())
        output.append(try extent.height.pack())
        output.append(try extent.anchorFromExtentTransform.pack())
        output.append(try mesh.vertices.count.pack())
        output.append(try mesh.triangles.count.pack())
        for v in mesh.vertices {
            output.append(try v.pack())
        }
        for t in mesh.triangles {
            output.append(try t[0].pack())
            output.append(try t[1].pack())
            output.append(try t[2].pack())
        }
        return output
    }
}

extension CapturedPlaneAnchor.Geometry: PackDecodable {
    public static func unpack(data: Data) throws -> (CapturedPlaneAnchor.Geometry, Int) {
        let (extentDimensions, consumed) = try Float.unpack(data: data, count: 2)
        var offset = consumed
        let width = extentDimensions[0]
        let height = extentDimensions[1]
        let anchorFromExtentTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            offset += consumed
            anchorFromExtentTransform = transform
        }
        
        let numVertices: Int
        let numTriangles: Int
        do {
            let (counts, consumed) = try Int.unpack(data: data[(data.startIndex + offset)...], count: 2)
            offset += consumed
            numVertices = counts[0]
            numTriangles = counts[1]
        }
        
        let vertices: [SIMD3<Float>]
        let triangles: [[UInt32]]
        do {
            let (v, consumed) = try SIMD3<Float>.unpack(data: data[(data.startIndex + offset)...], count: numVertices)
            offset += consumed
            vertices = v
        }
        do {
            let result: ([UInt32], Int) = try UInt32.unpack(data: data[(data.startIndex + offset)...], count: numTriangles * 3)
            let t = result.0
            let consumed = result.1
            offset += consumed
            triangles = (0..<numTriangles).map { i -> [UInt32] in
                [
                    t[i * 3],
                    t[i * 3 + 1],
                    t[i * 3 + 2]
                ]
            }
        }

        let extent = CapturedPlaneAnchor.Geometry.Extent(anchorFromExtentTransform: anchorFromExtentTransform, width: width, height: height)
        let mesh = CapturedPlaneMeshGeometry(vertices: vertices, triangles: triangles)
        
        return (
            CapturedPlaneAnchor.Geometry(
                extent: extent,
                mesh: mesh
            ),
            offset
        )
    }
}
