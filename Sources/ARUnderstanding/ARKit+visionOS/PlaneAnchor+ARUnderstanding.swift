//
//  PlaneAnchor+ARUnderstanding.swift
//  ARUnderstanding
//
//  Created by John Haney on 5/27/25.
//

#if os(visionOS)
import Foundation
import ARKit
import RealityKit

extension PlaneAnchor: @retroactive Hashable {}
extension PlaneAnchor: PlaneAnchorRepresentable {
    public typealias Geometry = PlaneAnchor.Geometry
}
extension PlaneAnchor.Geometry: PlaneAnchorGeometryRepresentable {
    public typealias Extent = PlaneAnchor.Geometry.Extent
    
    public var mesh: CapturedPlaneMeshGeometry {
        CapturedPlaneMeshGeometry(self)
    }
}
extension PlaneAnchor.Geometry.Extent: PlaneAnchorGeometryExtentRepresentable {}
#else
public typealias PlaneAnchor = CapturedPlaneAnchor
#endif
