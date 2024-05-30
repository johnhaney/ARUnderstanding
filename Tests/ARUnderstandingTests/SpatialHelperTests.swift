//
//  SpatialHelperTests.swift
//
//
//  Created by John Haney on 4/20/24.
//

#if os(visionOS)
import XCTest
@testable import ARUnderstanding
import Spatial

final class SpatialHelperTests: XCTestCase {
    func testPoseHelpers() {
        let pose = Pose3D(position: Point3D(x: 1, y: 1, z: 1), rotation: Rotation3D(position: Point3D(x: 1, y: 0, z: 0), target: Point3D(x: 2, y: 0, z: 0), up: .up))
        
        XCTAssertEqual(pose.forward.x, 1, accuracy: 0.0001)
        XCTAssertEqual(pose.forward.y, 0, accuracy: 0.0001)
        XCTAssertEqual(pose.forward.z, 0, accuracy: 0.0001)
        
        XCTAssertEqual(pose.up.x, 0, accuracy: 0.0001)
        XCTAssertEqual(pose.up.y, 1, accuracy: 0.0001)
        XCTAssertEqual(pose.up.z, 0, accuracy: 0.0001)
        
        XCTAssertEqual(pose.right.x, 0, accuracy: 0.0001)
        XCTAssertEqual(pose.right.y, 0, accuracy: 0.0001)
        XCTAssertEqual(pose.right.z, -1, accuracy: 0.0001)
    }
    
    func testRotationHelpers() {
        let rotation = Rotation3D(angle: .degrees(45), axis: .xyz)
        
        XCTAssertEqual(rotation.forward.x, 0.505, accuracy: 0.001)
        XCTAssertEqual(rotation.forward.y, -0.3106, accuracy: 0.001)
        XCTAssertEqual(rotation.forward.z, 0.8047, accuracy: 0.001)
        
        XCTAssertEqual(rotation.up.x, -0.3106, accuracy: 0.001)
        XCTAssertEqual(rotation.up.y, 0.8047, accuracy: 0.001)
        XCTAssertEqual(rotation.up.z, 0.505, accuracy: 0.001)
        
        XCTAssertEqual(rotation.right.x, 0.8047, accuracy: 0.001)
        XCTAssertEqual(rotation.right.y, 0.505, accuracy: 0.001)
        XCTAssertEqual(rotation.right.z, -0.3106, accuracy: 0.001)
    }
}
#endif
