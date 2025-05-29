//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/3/25.
//

#if os(iOS)
import ARKit
import RealityKit

extension ARPlaneAnchor: CapturableARAnchor {
    func capturedAnchor(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor {
        CapturedAnchor.plane(CapturedAnchorUpdate<CapturedPlaneAnchor>(anchor: self.captured, timestamp: timestamp, event: event))
    }
}

extension ARPlaneAnchor {
    var captured: CapturedPlaneAnchor {
        SavedARPlaneAnchor(anchor: self).captured
    }
    
    var capturedGeometry: CapturedPlaneAnchor.Geometry {
        CapturedPlaneAnchor.Geometry(
            extent: self.planeExtent,
            mesh: self.geometry.mesh
        )
    }
}

struct SavedARPlaneAnchor: PlaneAnchorRepresentable {
    typealias Geometry = CapturedPlaneAnchor.Geometry
    var originFromAnchorTransform: simd_float4x4 { _originFromAnchorTransform() }
    var id: UUID { _id() }
    var classification: PlaneAnchor.Classification { _classification() }
    var alignment: PlaneAnchor.Alignment { _alignment() }
    var geometry: CapturedPlaneAnchor.Geometry { _geometry() }

    init(anchor: ARPlaneAnchor) {
        _originFromAnchorTransform = { anchor.transform }
        _id = { anchor.identifier }
        _classification = { anchor.classification.captured }
        _alignment = { anchor.alignment.captured }
        _geometry = { anchor.capturedGeometry }
    }
    
    private var _originFromAnchorTransform: @Sendable () -> simd_float4x4
    private var _id: @Sendable () -> UUID
    private var _classification: @Sendable () -> PlaneAnchor.Classification
    private var _alignment: @Sendable () -> PlaneAnchor.Alignment
    private var _geometry: @Sendable () -> CapturedPlaneAnchor.Geometry
}

extension ARPlaneExtent: PlaneAnchorGeometryExtentRepresentable {
    public var anchorFromExtentTransform: simd_float4x4 {
        Transform(rotation: .init(angle: self.rotationOnYAxis, axis: [0,1,0])).matrix
    }
}

extension ARPlaneGeometry {
    public var mesh: CapturedPlaneMeshGeometry {
        var vertices: [SIMD3<Float>] = []
        vertices.reserveCapacity(self.vertices.count)

        for v in self.vertices {
            vertices.append(SIMD3(v.x, v.y, v.z))
        }

        var triangles: [[UInt32]] = []
        for i in stride(from: 0, to: triangleIndices.count, by: 3) {
            let i0 = triangleIndices[i]
            let i1 = triangleIndices[i + 1]
            let i2 = triangleIndices[i + 2]
            triangles.append([UInt32(i0), UInt32(i1), UInt32(i2)])
        }

        return CapturedPlaneMeshGeometry(vertices: vertices, triangles: triangles)
    }
}

//extension ARPlaneGeometry: PlaneAnchorGeometryRepresentable {
//    public typealias Extent = ARPlaneExtent
//    public var extent: Extent {
//    }
//    
//    public var mesh: CapturedPlaneMeshGeometry {
//        
//    }
//}

//    func capturedAnchor(_ event: CapturedAnchorEvent, timestamp: TimeInterval) -> CapturedAnchor {
//        let anchor = CapturedPlaneAnchor(id: identifier, originFromAnchorTransform: transform, geometry: capturedGeometry, classification: classification.captured, alignment: alignment.captured)
//        let update = CapturedAnchorUpdate<CapturedPlaneAnchor>(anchor: anchor, timestamp: timestamp, event: event)
//        return CapturedAnchor.plane(update)
//    }
//    
//    var capturedGeometry: CapturedPlaneAnchor.Geometry {
//        let extent = capturedPlaneExtent
//        let mesh = capturedMeshGeometry
//        return CapturedPlaneAnchor.Geometry(extent: extent, mesh: mesh)
//    }
//    
//    var capturedPlaneExtent: CapturedPlaneAnchor.Geometry.Extent {
//        CapturedPlaneAnchor.Geometry.Extent(anchorFromExtentTransform: Transform(rotation: simd_quatf(angle: planeExtent.rotationOnYAxis, axis: [0,1,0])).matrix, width: planeExtent.width, height: planeExtent.height)
//    }
//    
//    var capturedMeshGeometry: CapturedPlaneMeshGeometry {
//        let triangles: [[UInt32]] = (0..<geometry.triangleCount).map { i in
//            [
//                UInt32(geometry.triangleIndices[3 * i + 0]),
//                UInt32(geometry.triangleIndices[3 * i + 1]),
//                UInt32(geometry.triangleIndices[3 * i + 2])
//            ]
//        }
//        return CapturedPlaneMeshGeometry(vertices: geometry.vertices, triangles: triangles)
//    }
//}

extension ARPlaneAnchor.Alignment {
    var captured: CapturedPlaneAnchor.Alignment {
        switch self {
        case .horizontal: .horizontal
        case .vertical: .vertical
        @unknown default: .horizontal
        }
    }
}

extension ARPlaneAnchor.Classification {
    var captured: CapturedPlaneAnchor.Classification {
        switch self {
        case .wall: .wall
        case .floor: .floor
        case .ceiling: .ceiling
        case .table: .table
        case .seat: .seat
        case .window: .window
        case .door: .door
        case .none(let state):
            switch state {
            case .notAvailable: .notAvailable
            case .undetermined: .undetermined
            case .unknown: .unknown
            @unknown default: .unknown
            }
        @unknown default: .unknown
        }
    }
}
#endif
