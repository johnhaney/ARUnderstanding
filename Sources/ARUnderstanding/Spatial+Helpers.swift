//
//  Spatial+Helpers.swift
//
//
//  Created by John Haney on 4/20/24.
//

#if os(visionOS)
import Spatial
import RealityKit

extension Pose3D {
    /// Normalized vector in the direction of the pose's rotation
    var forward: Vector3D {
        rotation.forward
    }
    var up: Vector3D {
        rotation.up
    }
    var right: Vector3D {
        rotation.right
    }
}

extension Rotation3D {
    /// Normalized vector in the direction of the pose's rotation
    var forward: Vector3D {
        self.act(Vector3D.forward)
    }
    
    var up: Vector3D {
        self.act(Vector3D.up)
    }
    
    var right: Vector3D {
        self.act(Vector3D.right)
    }
    
    func act(_ vector: Vector3D) -> Vector3D {
        Vector3D(quaternion.act(vector.vector))
    }
}

extension Pose3D {
    @MainActor init?(_ entity: Entity) {
        self.init(entity.transform)
    }
    
    init?(_ transform: Transform) {
        self.init(transform.matrix)
    }
    
    var transform: Transform {
        Transform(rotation: rotation.floatQuaternion, translation: position.floatVector)
    }
}

extension Point3D {
    @MainActor init(_ entity: Entity) {
        self.init(entity.transform)
    }
    
    init(_ transform: Transform) {
        self.init(transform.translation)
    }
    
    var floatVector: SIMD3<Float> {
        SIMD3<Float>(self)
    }
}

extension Rotation3D {
    @MainActor init(_ entity: Entity) {
        self.init(entity.transform)
    }
    
    init(_ transform: Transform) {
        self.init(transform.rotation)
    }
    
    var floatQuaternion: simd_quatf {
        simd_quatf(self)
    }
}

extension Vector3D {
    var floatVector: SIMD3<Float> {
        SIMD3<Float>(self)
    }
}
#endif
