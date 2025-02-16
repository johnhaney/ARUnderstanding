//
//  CapturedRoomAnchor+Codable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/8/25.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

extension CapturedRoomAnchor: Codable {
    enum CodingKeys: String, CodingKey {
        case VERSION
        case id
        case originFromAnchorTransform
        case geometry
        case classifiedGeometries
        case planeAnchorIDs
        case meshAnchorIDs
        case isCurrentRoom
        case timestamp
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(originFromAnchorTransform, forKey: .originFromAnchorTransform)
        try container.encode(geometry, forKey: .geometry)
        try container.encode(classifiedGeometries, forKey: .classifiedGeometries)
        try container.encode(planeAnchorIDs, forKey: .planeAnchorIDs)
        try container.encode(meshAnchorIDs, forKey: .meshAnchorIDs)
        try container.encode(isCurrentRoom, forKey: .isCurrentRoom)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let originFromAnchorTransform = try container.decode(simd_float4x4.self, forKey: .originFromAnchorTransform)
        let geometry = try container.decode(CapturedRoomAnchor.Geometry.self, forKey: .geometry)
        let classifiedGeometries = try container.decode(CapturedRoomAnchor.CapturedGeometries.self, forKey: .classifiedGeometries)
        let planeAnchorIDs = try container.decode([UUID].self, forKey: .planeAnchorIDs)
        let meshAnchorIDs = try container.decode([UUID].self, forKey: .meshAnchorIDs)
        let isCurrentRoom = try container.decode(Bool.self, forKey: .isCurrentRoom)
        let timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        self.init(id: id, originFromAnchorTransform: originFromAnchorTransform, geometry: geometry, classifiedGeometries: classifiedGeometries, planeAnchorIDs: planeAnchorIDs, meshAnchorIDs: meshAnchorIDs, isCurrentRoom: isCurrentRoom, timestamp: timestamp)
    }
}

extension CapturedRoomAnchor.CapturedGeometries: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(meshSource)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let meshSource = try container.decode(CapturedRoomGeometrySource.self)
        self.meshSource = meshSource
    }
}

extension CapturedRoomAnchor.CapturedGeometries.CapturedRoomGeometrySource: Codable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
#if os(visionOS)
        case .room(let room):
            try container.encode(CapturedRoomGeometry(room))
#endif
        case .captured(let capturedRoomGeometry):
            try container.encode(capturedRoomGeometry)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let capturedRoomGeometry = try container.decode(CapturedRoomGeometry.self)
        self = .captured(capturedRoomGeometry)
    }
}

//extension CapturedRoomAnchor.CapturedGeometry.CapturedRoomGeometrySource: Codable {
//    init(from decoder: any Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        let capturedRoomGeometry = try container.decode(CapturedRoomGeometry.self)
//        self = .captured(capturedRoomGeometry)
//    }
//    
//    func encode(to encoder: any Encoder) throws {
//        var container = encoder.singleValueContainer()
//        switch self {
//#if os(visionOS)
//        case .room(let room):
//            try container.encode(CapturedRoomGeometry(room))
//#endif
//        case .captured(let capturedRoomGeometry):
//            try container.encode(capturedRoomGeometry)
//        }
//    }
//}
