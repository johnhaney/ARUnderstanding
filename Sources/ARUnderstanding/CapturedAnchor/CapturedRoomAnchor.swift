//
//  CapturedRoomAnchor.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/5/25.
//

#if canImport(ARKit)
import ARKit
#endif
import Foundation
import RealityKit

public protocol RoomAnchorRepresentable: CapturableAnchor {
    associatedtype Geometry: MeshAnchorGeometryRepresentable
    var id: UUID { get }
    var originFromAnchorTransform: simd_float4x4 { get }
    var geometry: Geometry { get }
    var planeAnchorIDs: [UUID] { get }
    var meshAnchorIDs: [UUID] { get }
    var isCurrentRoom: Bool { get }
    func geometries(of classification: MeshAnchor.MeshClassification) -> [Geometry]
    func contains(_ point: SIMD3<Float>) -> Bool
    var classifiedGeometries: [MeshAnchor.MeshClassification: [Geometry]] { get }
//    var capturedClassifiedGeometries: [MeshAnchor.MeshClassification: [CapturedMeshAnchor.Geometry]] { get }
//    var capturedGeometry: CapturedRoomAnchor.CapturedGeometry { get }
}

extension Dictionary where Key == MeshAnchor.MeshClassification, Value == [any MeshAnchorGeometryRepresentable] {
    var captured: [MeshAnchor.MeshClassification: [CapturedMeshAnchor.Geometry]] {
        self.mapValues({ $0.map(\.captured) })
    }
}

extension RoomAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension RoomAnchor {
    var capturedGeometry: CapturedRoomAnchor.CapturedGeometry {
        CapturedRoomAnchor.CapturedGeometry(room: self)
    }
}

public struct CapturedRoomAnchor: Anchor, RoomAnchorRepresentable, Sendable {
    public typealias Geometry = CapturedGeometry.MeshGeometry
    public typealias ID = UUID
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var capturedGeometry: CapturedGeometry
    public var planeAnchorIDs: [UUID]
    public var meshAnchorIDs: [UUID]
    public var isCurrentRoom: Bool
    public var description: String { "Room \(originFromAnchorTransform)" }
    public var timestamp: TimeInterval

    public var geometry: Geometry {
        capturedGeometry.mesh
    }
    public var classifiedGeometries: [MeshAnchor.MeshClassification : [Geometry]] {
        capturedGeometry.classifiedGeometries
    }

    public func geometries(of classification: MeshAnchor.MeshClassification) -> [Geometry] {
        classifiedGeometries[classification] ?? []
    }
    
    public func contains(_ point: SIMD3<Float>) -> Bool {
        false
    }
    
    public struct CapturedGeometry: RoomAnchorGeometryRepresentable, Sendable, Codable {
        public typealias MeshGeometry = CapturedMeshGeometry
        public var mesh: MeshGeometry {
            meshSource.mesh
        }
        public var classifiedGeometries: [MeshAnchor.MeshClassification : [MeshGeometry]] {
            meshSource.classifiedGeometries
        }
        private var meshSource: CapturedRoomGeometrySource
        
        public var captured: CapturedRoomAnchor.CapturedGeometry { self }
        
        enum CapturedRoomGeometrySource : Sendable {
            case captured(CapturedRoomGeometry)
#if os(visionOS)
            case room(any RoomAnchorRepresentable)
#endif
            
            var mesh: CapturedMeshGeometry {
                switch self {
                case .captured(let capturedRoomGeometry):
                    capturedRoomGeometry.geometry
#if os(visionOS)
                case .room(let room):
                    CapturedMeshGeometry(room.geometry)
#endif
                }
            }
            
            var classifiedGeometries: [MeshAnchor.MeshClassification: [CapturedMeshGeometry]] {
                switch self {
                case .captured(let capturedRoomGeometry):
                    capturedRoomGeometry.classifiedGeometries
#if os(visionOS)
                case .room(let room):
                    room.classifiedGeometries.mapValues({ $0.map({ CapturedMeshGeometry($0) }) })
#endif
                }
            }
        }
        
        public init(room: CapturedRoomGeometry) {
            self.meshSource = .captured(room)
        }
        
        public init(room: any RoomAnchorRepresentable) {
            self.meshSource = .room(room)
        }
        
#if os(visionOS)
        public init(room: RoomAnchor) {
            self.meshSource = .room(room)
        }
#endif
    }
    
    public func shape() async throws -> ShapeResource {
        try await geometry.mesh.shape()
    }
}

extension CapturedMeshGeometry: MeshAnchorGeometryRepresentable {
    public var mesh: CapturedMeshGeometry {
        self
    }
}

public struct CapturedRoomGeometry: Codable, Sendable {
    let geometry: CapturedMeshGeometry
    let classifiedGeometries: [MeshAnchor.MeshClassification: [CapturedMeshGeometry]]
    
    #if os(visionOS)
    init(_ geometry: RoomAnchor.Geometry, classifiedGeometries: [MeshAnchor.MeshClassification: [RoomAnchor.Geometry]]) {
        self.geometry = CapturedMeshGeometry(geometry)
        self.classifiedGeometries = classifiedGeometries.mapValues({ $0.map(CapturedMeshGeometry.init) })
    }

    init(_ room: RoomAnchor) {
        self.geometry = CapturedMeshGeometry(room.geometry)
        self.classifiedGeometries = room.classifiedGeometries.mapValues({ $0.map(CapturedMeshGeometry.init) })
    }

    init(_ room: any RoomAnchorRepresentable) {
        self.geometry = CapturedMeshGeometry(room.geometry)
        self.classifiedGeometries = room.classifiedGeometries.mapValues({ $0.map(CapturedMeshGeometry.init) })
    }
    #endif
}

extension RoomAnchorRepresentable {
    public var captured: CapturedRoomAnchor {
        CapturedRoomAnchor(
            id: id,
            originFromAnchorTransform: originFromAnchorTransform,
            capturedGeometry: capturedGeometry,
            planeAnchorIDs: planeAnchorIDs,
            meshAnchorIDs: meshAnchorIDs,
            isCurrentRoom: isCurrentRoom,
            timestamp: timestamp)
    }
    
    var capturedGeometry: CapturedRoomAnchor.CapturedGeometry {
        CapturedRoomAnchor.CapturedGeometry(room: self)
    }
}

//extension RoomAnchorGeometryRepresentable {
//    var captured: CapturedRoomAnchor.CapturedGeometry {
//        CapturedRoomAnchor.CapturedGeometry(mesh: mesh.captured, classifiedGeometries:         classifiedGeometries.mapValues({ $0.map(\.captured) }))
//    }
//}

extension MeshAnchor.MeshClassification: @retroactive CaseIterable {
    public static var allCases: [MeshAnchor.MeshClassification] {
        [
            .none,
            .wall,
            .floor,
            .ceiling,
            .table,
            .seat,
            .window,
            .door,
            .stairs,
            .bed,
            .cabinet,
            .homeAppliance,
            .tv,
            .plant,
        ]
    }
}

public protocol RoomAnchorGeometryRepresentable {
    associatedtype MeshGeometry = CapturedMeshGeometry
    var mesh: MeshGeometry { get }
    var classifiedGeometries: [MeshAnchor.MeshClassification: [MeshGeometry]] { get }
}

extension MeshAnchor.MeshClassification: Codable, Sendable {
    
}

public struct CapturedRoomMeshGeometry: Codable, Sendable {
    var geometry: CapturedMeshAnchor.Geometry
    var classifiedGeometries: [MeshAnchor.MeshClassification: [CapturedMeshAnchor.Geometry]]

#if !os(visionOS)
    init(_ roomAnchor: RoomAnchor) {
        geometry = roomAnchor.geometry.captured
        classifiedGeometries = roomAnchor.capturedClassifiedGeometries
    }
#endif
}

extension RoomAnchor {
    public var classifiedGeometries: [MeshAnchor.MeshClassification : [MeshAnchor.Geometry]] {
        Dictionary(uniqueKeysWithValues: MeshAnchor.MeshClassification.allCases.map { classification in
            (classification, self.geometries(of: classification))
        })
    }
}
