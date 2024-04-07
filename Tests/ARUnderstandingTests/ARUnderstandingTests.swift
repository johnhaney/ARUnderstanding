import XCTest
@testable import ARUnderstanding
import ARKit

final class ARUnderstandingTests: XCTestCase {
    func testNoProvidersGiven() async throws {
        try await didNotStart(providers: [])
    }
    
    func testHandNotReady() async throws {
        #if targetEnvironment(simulator)
        #else
        XCTSkip("This test is intended for simulator only")
        #endif
        try await didNotStart(providers: [
            .hands(HandTrackingProvider())
        ])
    }
    
    func testImageNotReady() async throws {
        #if targetEnvironment(simulator)
        #else
        XCTSkip("This test is intended for simulator only")
        #endif
        try await didNotStart(providers: [
            .image(ImageTrackingProvider(referenceImages: []))
        ])
    }
    
    func testMeshNotReady() async throws {
        #if targetEnvironment(simulator)
        #else
        XCTSkip("This test is intended for simulator only")
        #endif
        try await didNotStart(providers: [
            .meshes(SceneReconstructionProvider())
        ])
    }
    
    func testPlaneNotReady() async throws {
        #if targetEnvironment(simulator)
        #else
        XCTSkip("This test is intended for simulator only")
        #endif
        try await didNotStart(providers: [
            .planes(PlaneDetectionProvider())
        ])
    }
    
    // Note: No test for world not ready because WorldTrackingProvider still runs on Simulator

    func didNotStart(providers: [ARProvider]) async throws {
        let gotAnchor = XCTestExpectation(description: "returned anchors")
        gotAnchor.isInverted = true
        
        let exitedAnchorLoop = XCTestExpectation(description: "exited anchor loop")
        Task {
            for await _ in await ARUnderstanding(providers: providers).anchorUpdates {
                gotAnchor.fulfill()
            }
            exitedAnchorLoop.fulfill()
        }
        await fulfillment(of: [exitedAnchorLoop, gotAnchor], timeout: 1)
    }
}
