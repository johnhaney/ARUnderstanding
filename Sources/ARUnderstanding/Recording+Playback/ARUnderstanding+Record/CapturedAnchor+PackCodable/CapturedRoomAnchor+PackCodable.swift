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

extension CapturedRoomAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try originFromAnchorTransform.pack())
        output.append(contentsOf: [isCurrentRoom ? UInt8(1) : UInt8(0)])
        output.append(try planeAnchorIDs.count.pack())
        output.append(try meshAnchorIDs.count.pack())
        for id in planeAnchorIDs {
            output.append(try id.pack())
        }
        for id in meshAnchorIDs {
            output.append(try id.pack())
        }
        output.append(try geometry.pack())
        output.append(try classifiedGeometries.pack())
        return output
    }
}

extension CapturedRoomAnchor: PackDecodable {
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
        
        let isCurrentRoom = data[data.startIndex + offset] == 1
        offset += 1
        
        let numPlanes: Int
        let numMeshes: Int
        do {
            let (counts, consumed) = try Int.unpack(data: data[(data.startIndex + offset)...], count: 2)
            offset += consumed
            numPlanes = counts[0]
            numMeshes = counts[1]
        }
        
        let planes: [UUID]
        if numPlanes > 0 {
            let (p, consumed) = try UUID.unpack(data: data[(data.startIndex + offset)...], count: numPlanes)
            offset += consumed
            planes = p
        } else {
            planes = []
        }
        let meshes: [UUID]
        if numMeshes > 0 {
            let (m, consumed) = try UUID.unpack(data: data[(data.startIndex + offset)...], count: numMeshes)
            offset += consumed
            meshes = m
        } else {
            meshes = []
        }
        
        let geometry: CapturedRoomAnchor.Geometry
        do {
            let (g, consumed) = try CapturedRoomAnchor.Geometry.unpack(data: data[(data.startIndex + offset)...])
            offset += consumed
            geometry = g
        }
        let classifiedGeometries: CapturedRoomAnchor.ClassifiedGeometry
        do {
            let (c, consumed) = try CapturedRoomAnchor.ClassifiedGeometry.unpack(data: data[(data.startIndex + offset)...])
            offset += consumed
            classifiedGeometries = c
        }
        
        return (
            CapturedRoomAnchor(
                id: id,
                originFromAnchorTransform: originFromAnchorTransform,
                geometry: geometry,
                classifiedGeometries: classifiedGeometries,
                planeAnchorIDs: planes,
                meshAnchorIDs: meshes,
                isCurrentRoom: isCurrentRoom
            ),
            offset
        )
    }
}

extension CapturedRoomAnchor.ClassifiedGeometry: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        let classifiedGeometries = self.classifiedGeometries
        output.append(contentsOf: [UInt8(2)])
        do {
            let classification = MeshAnchor.MeshClassification.floor
            let geometries = classifiedGeometries[classification] ?? []
            output.append(contentsOf: [classification.code])
            output.append(try geometries.count.pack())
            for g in geometries {
                output.append(try g.pack())
            }
        }
        do {
            let classification = MeshAnchor.MeshClassification.floor
            let geometries = classifiedGeometries[classification] ?? []
            output.append(contentsOf: [classification.code])
            output.append(try geometries.count.pack())
            for g in geometries {
                output.append(try g.pack())
            }
        }
        return output
    }
}

extension CapturedRoomAnchor.ClassifiedGeometry: PackDecodable {
    public static func unpack(data: Data) throws -> (CapturedRoomAnchor.CapturedGeometries, Int) {
        
        let numberOfClassified = data[data.startIndex]
        var offset = 1

        var geometries: [MeshAnchor.MeshClassification : [CapturedMeshAnchor.Geometry]] = [:]
        for _ in 0..<Int(numberOfClassified) {
            let code = data[data.startIndex + offset]
            offset += 1
            let classification = MeshAnchor.MeshClassification(code: code)
            let (count, consumed) = try Int.unpack(data: data[(data.startIndex + offset)...])
            offset += consumed
            
            do {
                let (g, consumed) = try CapturedMeshAnchor.Geometry.unpack(data: data[(data.startIndex + offset)...], count: count)
                offset += consumed
                geometries[classification] = g
            }
        }
        
        let geometry = CapturedRoomGeometry(classifiedGeometries: geometries)
        
        return (
            CapturedRoomAnchor.ClassifiedGeometry(room: geometry),
            offset
        )
    }
}

extension MeshAnchor.MeshClassification {
    var code: UInt8 {
        switch self {
        case .none: UInt8(0)
        case .wall: UInt8(1)
        case .floor: UInt8(2)
        case .ceiling: UInt8(3)
        case .table: UInt8(4)
        case .seat: UInt8(5)
        case .window: UInt8(6)
        case .door: UInt8(7)
        case .stairs: UInt8(8)
        case .bed: UInt8(9)
        case .cabinet: UInt8(10)
        case .homeAppliance: UInt8(11)
        case .tv: UInt8(12)
        case .plant: UInt8(13)
        @unknown default: UInt8.max
        }
    }
    
    init(code: UInt8) {
        switch code {
        case 0: self = .none
        case 1: self = .wall
        case 2: self = .floor
        case 3: self = .ceiling
        case 4: self = .table
        case 5: self = .seat
        case 6: self = .window
        case 7: self = .door
        case 8: self = .stairs
        case 9: self = .bed
        case 10: self = .cabinet
        case 11: self = .homeAppliance
        case 12: self = .tv
        case 13: self = .plant
        default: self = .none
        }
    }
}
