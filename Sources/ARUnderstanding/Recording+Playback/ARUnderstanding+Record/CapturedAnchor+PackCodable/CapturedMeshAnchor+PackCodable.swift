//
//  CapturedMeshAnchor+PackCodable.swift
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

extension CapturedMeshAnchor: PackEncodable {
    func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try originFromAnchorTransform.pack())
        output.append(try geometry.pack())
        return output
    }
}

extension CapturedMeshAnchor: AnchorPackDecodable {
    static func unpack(data: Data, timestamp: TimeInterval) throws -> (Self, Int) {
        guard data.count >= 16 + 1 + 1
        else {
            throw UnpackError.needsMoreData(16 + 1 + 1)
        }
        
        let (id, consumed) = try UUID.unpack(data: data)
        var offset = consumed
        let originFromAnchorTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            originFromAnchorTransform = transform
            offset += consumed
        }
        let geometry: CapturedMeshAnchor.Geometry
        do {
            let (capturedGeometry, consumed) = try CapturedMeshAnchor.Geometry.unpack(data: data[(data.startIndex + offset)...])
            geometry = capturedGeometry
            offset += consumed
        }
        
        return (
            CapturedMeshAnchor(
                id: id,
                originFromAnchorTransform: originFromAnchorTransform,
                geometry: geometry,
                timestamp: timestamp
            ),
            offset
        )
    }
}

extension CapturedMeshAnchor.Geometry: PackCodable {
    func pack() throws -> Data {
        var output: Data = Data()
        let classifications: [UInt8] = mesh.classifications ?? []
        output.append(try mesh.vertices.count.pack())
        output.append(try mesh.normals.count.pack())
        output.append(try mesh.triangles.count.pack())
        output.append(try classifications.count.pack())

        for v in mesh.vertices {
            output.append(try v.pack())
        }
        for n in mesh.normals {
            output.append(try n.pack())
        }
        for t in mesh.triangles {
            output.append(try t[0].pack())
            output.append(try t[1].pack())
            output.append(try t[2].pack())
        }
        output.append(contentsOf: classifications)
        return output
    }
    
    static func unpack(data: Data) throws -> (CapturedMeshAnchor.Geometry, Int) {
        let (counts, consumed) = try Int.unpack(data: data, count: 4)
        let numVertices = counts[0]
        let numNormals = counts[1]
        let numTriangles = counts[2]
        let numClassifications = counts[3]
        var offset = consumed
        let vertices: [SIMD3<Float>]
        let normals: [SIMD3<Float>]
        let triangles: [[UInt32]]
        let classifications: [UInt8]
        do {
            let (v, consumed) = try SIMD3<Float>.unpack(data: data[(data.startIndex + offset)...], count: numVertices)
            offset += consumed
            vertices = v
        }
        do {
            let (n, consumed) = try SIMD3<Float>.unpack(data: data[(data.startIndex + offset)...], count: numNormals)
            offset += consumed
            normals = n
        }
        do {
            let (t, consumed) = try UInt32.unpack(data: data[(data.startIndex + offset)...], count: numTriangles * 3)
            offset += consumed
            triangles = (0 ..< numTriangles).map { i in
                [
                    t[i * 3],
                    t[i * 3 + 1],
                    t[i * 3 + 2]
                ]
            }
        }
        if numClassifications > 0 {
            var classification: [UInt8] = Array(repeating: UInt8.zero, count: numClassifications)
            data.copyBytes(to: &classification, from: (data.startIndex + offset)..<(data.startIndex + offset + numClassifications))
            offset += numClassifications
            classifications = classification
        } else {
            classifications = []
        }

        let mesh = CapturedMeshGeometry(vertices: vertices, normals: normals, triangles: triangles, classifications: classifications)
        return (CapturedMeshAnchor.Geometry(mesh: mesh), offset)
    }
}
