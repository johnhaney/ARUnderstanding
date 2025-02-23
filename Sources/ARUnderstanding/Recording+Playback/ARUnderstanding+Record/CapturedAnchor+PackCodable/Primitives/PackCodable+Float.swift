//
//  PackCodable+Double.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation
import RealityKit

extension Float: PackEncodable {
    func pack() throws -> Data {
        .init(underlying: bitPattern.bigEndian)
    }
}

extension Float: PackDecodable {
    static func unpack(data: Data) throws -> (Float, Int) {
        let bytes = MemoryLayout<UInt32>.size
        guard data.count >= bytes else { throw UnpackError.needsMoreData(bytes) }
        let value = UInt32(bigEndian: data.interpreted())
        return (Float(bitPattern: value), bytes)
    }
}

import simd

extension simd_float4x4: PackCodable {
    func pack() throws -> Data {
        var output: Data = Data()
        for f in floats {
            let data: Data = try f.pack()
            output.append(data)
        }
        return output
    }

    static func unpack(data: Data) throws -> (Self, Int) {
        let (floats, size) = try Float.unpack(data: data, count: 16)
        let result = simd_float4x4(columns: (
            simd_float4(arrayLiteral: floats[0], floats[1], floats[2], floats[3]),
            simd_float4(arrayLiteral: floats[4], floats[5], floats[6], floats[7]),
            simd_float4(arrayLiteral: floats[8], floats[9], floats[10], floats[11]),
            simd_float4(arrayLiteral: floats[12], floats[13], floats[14], floats[15])))
        return (result, size)
    }
}

extension simd_float4x4 {
    var floats: [Float] {
        columns.0.floats +
        columns.1.floats +
        columns.2.floats +
        columns.3.floats
    }
}

extension simd_float4 {
    var floats: [Float] {
        [x, y, z, w]
    }
}

extension simd_float4: PackEncodable, PackDecodable {
    func pack() throws -> Data {
        var output: Data = Data()
        for f in [x,y,z,w] {
            let data: Data = try f.pack()
            output.append(data)
        }
        return output
    }
    
    static func unpack(data: Data) throws -> (simd_float4, Int) {
        let (floats, consumed) = try Float.unpack(data: data, count: 4)
        return (SIMD4<Float>(floats), consumed)
    }
}

extension simd_float3: PackEncodable, PackDecodable {
    func pack() throws -> Data {
        var output: Data = Data()
        for f in [x,y,z] {
            let data: Data = try f.pack()
            output.append(data)
        }
        return output
    }
    
    static func unpack(data: Data) throws -> (simd_float3, Int) {
        let (floats, consumed) = try Float.unpack(data: data, count: 3)
        return (SIMD3<Float>(floats), consumed)
    }
}
