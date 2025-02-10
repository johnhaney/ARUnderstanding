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
    associatedtype ClassifiedGeometry: RoomAnchorGeometryRepresentable
    var id: UUID { get }
    var originFromAnchorTransform: simd_float4x4 { get }
    var geometry: Geometry { get }
    var planeAnchorIDs: [UUID] { get }
    var meshAnchorIDs: [UUID] { get }
    var isCurrentRoom: Bool { get }
    func geometries(of classification: MeshAnchor.MeshClassification) -> [Geometry]
    func contains(_ point: SIMD3<Float>) -> Bool
    var classifiedGeometries: ClassifiedGeometry { get }
//    var capturedClassifiedGeometries: [MeshAnchor.MeshClassification: [CapturedMeshAnchor.Geometry]] { get }
//    var capturedGeometry: CapturedRoomAnchor.CapturedGeometry { get }
}

extension RoomAnchorGeometryRepresentable {
    var captured: CapturedRoomAnchor.ClassifiedGeometry {
        let capturedGeometry = CapturedRoomGeometry(classifiedGeometries: classifiedGeometries)
        return CapturedRoomAnchor.ClassifiedGeometry.init(room: capturedGeometry)
    }
}

extension RoomAnchorRepresentable where ClassifiedGeometry.MeshGeometry == Geometry {
    public func geometries(of classification: MeshAnchor.MeshClassification) -> [Geometry] {
        classifiedGeometries.classifiedGeometries[classification] ?? []
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

public struct CapturedRoomAnchor: Anchor, RoomAnchorRepresentable, Sendable {
    public typealias Geometry = CapturedMeshAnchor.Geometry
    public typealias ClassifiedGeometry = CapturedGeometries
    public typealias ID = UUID
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var geometry: Geometry
    public var classifiedGeometries: ClassifiedGeometry
    public var planeAnchorIDs: [UUID]
    public var meshAnchorIDs: [UUID]
    public var isCurrentRoom: Bool
    public var description: String { "Room \(originFromAnchorTransform)" }
    public var timestamp: TimeInterval

    public func geometries(of classification: MeshAnchor.MeshClassification) -> [Geometry] {
        classifiedGeometries.classifiedGeometries[classification] ?? []
    }
    
    public func contains(_ point: SIMD3<Float>) -> Bool {
        false
    }
    
    public struct CapturedGeometries: RoomAnchorGeometryRepresentable, Sendable {
        public typealias MeshGeometry = CapturedMeshAnchor.Geometry
        public var classifiedGeometries: [MeshAnchor.MeshClassification : [CapturedMeshAnchor.Geometry]] {
            meshSource.classifiedGeometries
        }
        internal var meshSource: CapturedRoomGeometrySource
        
        public var captured: CapturedRoomAnchor.CapturedGeometries { self }
        
        enum CapturedRoomGeometrySource : Sendable {
            case captured(CapturedRoomGeometry)
#if os(visionOS)
            case room(any RoomAnchorRepresentable)
#endif
            
            var classifiedGeometries: [MeshAnchor.MeshClassification: [CapturedMeshAnchor.Geometry]] {
                switch self {
                case .captured(let capturedRoomGeometry):
                    capturedRoomGeometry.classifiedGeometries
#if os(visionOS)
                case .room(let room):
                    room.classifiedGeometries.classifiedGeometries.mapValues({ $0.map({ $0.captured }) })
#endif
                }
            }
        }
        
        public init(room: CapturedRoomGeometry) {
            self.meshSource = .captured(room)
        }
        
#if os(visionOS)
        public init(room: any RoomAnchorRepresentable) {
            self.meshSource = .room(room)
        }
        
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
    let classifiedGeometries: [MeshAnchor.MeshClassification: [CapturedMeshAnchor.Geometry]]
    
    init<T: MeshAnchorGeometryRepresentable>(classifiedGeometries: [MeshAnchor.MeshClassification: [T]]) {
        self.classifiedGeometries = classifiedGeometries.mapValues({ $0.map(\.captured) })
    }

    #if os(visionOS)
    init(_ room: any RoomAnchorRepresentable) {
        self.classifiedGeometries = room.classifiedGeometries.classifiedGeometries.mapValues({ $0.map(\.captured) })
    }
    #endif
}

extension MeshAnchor.MeshClassification: Codable, @unchecked Sendable {
    
}

extension RoomAnchorRepresentable {
    public var captured: CapturedRoomAnchor {
        CapturedRoomAnchor(
            id: id,
            originFromAnchorTransform: originFromAnchorTransform,
            geometry: geometry.captured,
            classifiedGeometries: classifiedGeometries.captured,
            planeAnchorIDs: planeAnchorIDs,
            meshAnchorIDs: meshAnchorIDs,
            isCurrentRoom: isCurrentRoom,
            timestamp: timestamp)
    }
}

#if os(visionOS)
extension MeshAnchor.MeshClassification: @retroactive CaseIterable {}
#else
extension MeshAnchor.MeshClassification: CaseIterable {}
#endif
extension MeshAnchor.MeshClassification {
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
    associatedtype MeshGeometry: MeshAnchorGeometryRepresentable
    var classifiedGeometries: [MeshAnchor.MeshClassification: [MeshGeometry]] { get }
}

#if os(visionOS)
extension RoomAnchor {
    public typealias ClassifiedGeometry = RoomAnchorGeometryContainer
    public var classifiedGeometries: RoomAnchorGeometryContainer {
        RoomAnchorGeometryContainer(room: self)
    }
}

public struct RoomAnchorGeometryContainer: RoomAnchorGeometryRepresentable {
    let room: RoomAnchor
    public var classifiedGeometries: [MeshAnchor.MeshClassification: [MeshAnchor.Geometry]] {
        Dictionary(uniqueKeysWithValues: MeshAnchor.MeshClassification.allCases.map {
            ($0, room.geometries(of: $0))
        })
    }
}
#endif
