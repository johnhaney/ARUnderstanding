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
    public var geometry: Geometry { _geometry() }
    private var _geometry: @Sendable () -> Geometry
    public var classifiedGeometries: ClassifiedGeometry { _classifiedGeometries() }
    public var _classifiedGeometries: @Sendable () -> ClassifiedGeometry
    public var planeAnchorIDs: [UUID]
    public var meshAnchorIDs: [UUID]
    public var isCurrentRoom: Bool
    public var description: String { "Room \(originFromAnchorTransform)" }
    
    init<T: RoomAnchorRepresentable>(captured: T) {
        self.id = captured.id
        self.originFromAnchorTransform = captured.originFromAnchorTransform
        self._geometry = { captured.geometry.captured }
        self._classifiedGeometries = { captured.classifiedGeometries.captured }
        self.planeAnchorIDs = captured.planeAnchorIDs
        self.meshAnchorIDs = captured.meshAnchorIDs
        self.isCurrentRoom = captured.isCurrentRoom
    }
    
    init(id: UUID, originFromAnchorTransform: simd_float4x4, geometry: Geometry, classifiedGeometries: ClassifiedGeometry, planeAnchorIDs: [UUID], meshAnchorIDs: [UUID], isCurrentRoom: Bool) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self._geometry = { geometry }
        self._classifiedGeometries = { classifiedGeometries }
        self.planeAnchorIDs = planeAnchorIDs
        self.meshAnchorIDs = meshAnchorIDs
        self.isCurrentRoom = isCurrentRoom
    }

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

public struct CapturedRoomGeometry: Sendable {
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

#if !os(visionOS)
extension MeshAnchor.MeshClassification: @unchecked Sendable {
    
}
#endif

extension RoomAnchorRepresentable {
    public var captured: CapturedRoomAnchor {
        if let captured = self as? CapturedRoomAnchor {
            captured
        } else {
            CapturedRoomAnchor(captured: self)
        }
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
        Dictionary(uniqueKeysWithValues: [MeshAnchor.MeshClassification.wall, MeshAnchor.MeshClassification.floor].map {
            ($0, room.geometries(of: $0))
        })
    }
}
#endif

//public struct AnyRoomAnchorRepresentable: RoomAnchorRepresentable, Sendable, Equatable {
//    private let _id: @Sendable () -> UUID
//    private let _originFromAnchorTransform: @Sendable () -> simd_float4x4
//    private let _geometry: @Sendable () -> AnyMeshAnchorGeometryRepresentable
//    private let _planeAnchorIDs: @Sendable () -> [UUID]
//    private let _meshAnchorIDs: @Sendable () -> [UUID]
//    private let _isCurrentRoom: @Sendable () -> Bool
//    private let _geometries: @Sendable (MeshAnchor.MeshClassification) -> [any MeshAnchorGeometryRepresentable]
//    private let _contains: @Sendable (SIMD3<Float>) -> Bool
//    private let _description: @Sendable () -> String
//    
//    public init<T: RoomAnchorRepresentable>(_ base: T) {
//        _id = { base.id }
//        _originFromAnchorTransform = { base.originFromAnchorTransform }
//        _geometry = { base.geometry }
//        _planeAnchorIDs = { base.planeAnchorIDs }
//        _meshAnchorIDs = { base.meshAnchorIDs }
//        _isCurrentRoom = { base.isCurrentRoom }
//        _geometries = { base.geometries(of: $0) }
//        _contains = { base.contains($0) }
//        _description = { base.description }
//    }
//    
//    public var id: UUID { _id() }
//    public var originFromAnchorTransform: simd_float4x4 { _originFromAnchorTransform() }
//    public var geometry: AnyMeshAnchorGeometryRepresentable { _geometry() }
//    public var planeAnchorIDs: [UUID] { _planeAnchorIDs() }
//    public var meshAnchorIDs: [UUID] { _meshAnchorIDs() }
//    public var isCurrentRoom: Bool { _isCurrentRoom() }
//    public func geometries(of classification: MeshAnchor.MeshClassification) -> [any MeshAnchorGeometryRepresentable] { _geometries(classification) }
//    public func contains(_ point: SIMD3<Float>) -> Bool { _contains(point) }
//    public var description: String { _description() }
//}
//
//extension AnyRoomAnchorRepresentable {
//    var classifiedGeometries: [MeshAnchor.MeshClassification: [AnyMeshAnchorGeometryRepresentable]] {
//        [
//            .floor: geometries(of: .floor).map(\.eraseToAny),
//            .wall: geometries(of: .wall).map(\.eraseToAny)
//        ]
//    }
//}
//
//extension RoomAnchorRepresentable {
//    var eraseToAny: AnyRoomAnchorRepresentable {
//        AnyRoomAnchorRepresentable(self)
//    }
//}
//
//public struct SavedRoomAnchor: RoomAnchorRepresentable, Sendable, Equatable {
//    public var id: UUID
//    public var originFromAnchorTransform: simd_float4x4
//    public var geometry: AnyMeshAnchorGeometryRepresentable
//    public var planeAnchorIDs: [UUID]
//    public var meshAnchorIDs: [UUID]
//    public var isCurrentRoom: Bool
//    
//    public func geometries(of classification: MeshAnchor.MeshClassification) -> [any MeshAnchorGeometryRepresentable] {
//        []
//    }
//    
//    public func contains(_ point: SIMD3<Float>) -> Bool {
//        false
//    }
//    
//    public var description: String { "Room \(originFromAnchorTransform)" }
//}
////    public var id: UUID
////    public var originFromAnchorTransform: simd_float4x4
////    public var geometry: AnyMeshAnchorGeometryRepresentable
////    public var planeAnchorIDs: [UUID]
////    public var meshAnchorIDs: [UUID]
////    public var isCurrentRoom: Bool
////    public func geometries(of classification: MeshAnchor.MeshClassification) -> [any MeshAnchorGeometryRepresentable] {
////        
////    }
////
////    public func contains(_ point: SIMD3<Float>) -> Bool {
////        false
////    }
////    
////    public struct SavedGeometries: RoomAnchorGeometryRepresentable, Sendable, Equatable {
////        public typealias MeshGeometry = SavedMeshAnchor.Geometry
////        public var classifiedGeometries: [MeshAnchor.MeshClassification : [SavedMeshAnchor.Geometry]] {
////            meshSource.classifiedGeometries
////        }
////        internal var meshSource: SavedRoomGeometrySource
////        
////        public var saved: SavedRoomAnchor.SavedGeometries { self }
////        
////        enum SavedRoomGeometrySource: Sendable, Equatable {
////            case saved(SavedRoomGeometry)
////#if os(visionOS)
////            case room(any RoomAnchorRepresentable)
////#endif
////            
////            var classifiedGeometries: [MeshAnchor.MeshClassification: [SavedMeshAnchor.Geometry]] {
////                switch self {
////                case .saved(let savedRoomGeometry):
////                    savedRoomGeometry.classifiedGeometries
////#if os(visionOS)
////                case .room(let room):
////                    room.classifiedGeometries.classifiedGeometries.mapValues({ $0.map({ $0.saved }) })
////#endif
////                }
////            }
////            
////            static func ==(lhs: SavedRoomGeometrySource, rhs: SavedRoomGeometrySource) -> Bool {
////                switch (lhs, rhs) {
////                case (.saved(let lhs), .saved(let rhs)):
////                    lhs == rhs
////                    #if os(visionOS)
////                case (.room(let lhs), .room(let rhs)):
////                    lhs == rhs
////                case (.saved, .room):
////                    false
////                case (.room, .saved):
////                    false
////                    #endif
////                }
////            }
////        }
////        
////        public init(room: SavedRoomGeometry) {
////            self.meshSource = .saved(room)
////        }
////        
////#if os(visionOS)
////        public init(room: any RoomAnchorRepresentable) {
////            self.meshSource = .room(room)
////        }
////        
////        public init(room: RoomAnchor) {
////            self.meshSource = .room(room)
////        }
////#endif
////    }
////    
////    public func shape() async throws -> ShapeResource {
////        try await geometry.mesh.shape()
////    }
////}
//
//public func ==<R1: RoomAnchorRepresentable, R2: RoomAnchorRepresentable>(lhs: R1, rhs: R2) -> Bool {
//    lhs.isCurrentRoom == rhs.isCurrentRoom &&
//    lhs.geometry == rhs.geometry
//}
//
//public func ==<R1: MeshAnchorGeometryRepresentable, R2: MeshAnchorGeometryRepresentable>(lhs: R1, rhs: R2) -> Bool {
//    lhs.facesArray == rhs.facesArray &&
//    lhs.normalsArray == rhs.normalsArray &&
//    lhs.verticesArray == rhs.verticesArray
//}
//
//public func ==<R1: MeshAnchorGeometryRepresentable, R2: MeshAnchorGeometryRepresentable>(lhs: [R1], rhs: [R2]) -> Bool {
//    lhs == rhs
//}
//
//public func ==<R1: RoomAnchorGeometryRepresentable, R2: RoomAnchorGeometryRepresentable>(lhs: R1, rhs: R2) -> Bool {
//    (lhs.classifiedGeometries[.wall] ?? []) == (rhs.classifiedGeometries[.wall] ?? []) &&
//    (lhs.classifiedGeometries[.floor] ?? []) == (rhs.classifiedGeometries[.floor] ?? [])
//}
//
////extension SavedMeshGeometry: MeshAnchorGeometryRepresentable {
////    public var mesh: SavedMeshGeometry {
////        self
////    }
////}
//
////public struct SavedRoomGeometry: Sendable, Equatable {
////    let classifiedGeometries: [MeshAnchor.MeshClassification: [SavedMeshAnchor.Geometry]]
////    
////    init<T: MeshAnchorGeometryRepresentable>(classifiedGeometries: [MeshAnchor.MeshClassification: [T]]) {
////        self.classifiedGeometries = classifiedGeometries.mapValues({ $0.map(\.saved) })
////    }
////
////    #if os(visionOS)
////    init(_ room: any RoomAnchorRepresentable) {
////        self.classifiedGeometries = room.classifiedGeometries.classifiedGeometries.mapValues({ $0.map(\.saved) })
////    }
////    #endif
////}
//
//#if os(visionOS)
//extension MeshAnchor.MeshClassification: @unchecked Sendable, Equatable {}
//#else
//extension MeshAnchor.MeshClassification: @unchecked Sendable {}
//#endif
//
//extension RoomAnchorRepresentable {
//    public var captured: AnyRoomAnchorRepresentable { eraseToAny }
//    public var saved: AnyRoomAnchorRepresentable { eraseToAny }
//}
//
//#if os(visionOS)
//extension MeshAnchor.MeshClassification: @retroactive CaseIterable {}
//#endif
//extension MeshAnchor.MeshClassification {
//    public static var allCases: [MeshAnchor.MeshClassification] {
//        [
//            .none,
//            .wall,
//            .floor,
//            .ceiling,
//            .table,
//            .seat,
//            .window,
//            .door,
//            .stairs,
//            .bed,
//            .cabinet,
//            .homeAppliance,
//            .tv,
//            .plant,
//        ]
//    }
//}
//
//public protocol RoomAnchorGeometryRepresentable {
//    associatedtype MeshGeometry: MeshAnchorGeometryRepresentable
//    var classifiedGeometries: [MeshAnchor.MeshClassification: [MeshGeometry]] { get }
//}
//
//#if os(visionOS)
//extension RoomAnchor {
//    public typealias ClassifiedGeometry = RoomAnchorGeometryContainer
//    public var classifiedGeometries: RoomAnchorGeometryContainer {
//        RoomAnchorGeometryContainer(room: self)
//    }
//}
//
//public struct RoomAnchorGeometryContainer: RoomAnchorGeometryRepresentable {
//    let room: RoomAnchor
//    public var classifiedGeometries: [MeshAnchor.MeshClassification: [MeshAnchor.Geometry]] {
//        Dictionary(uniqueKeysWithValues: [MeshAnchor.MeshClassification.wall, MeshAnchor.MeshClassification.floor].map {
//            ($0, room.geometries(of: $0))
//        })
//    }
//}
//#endif
