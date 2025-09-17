//
//  ARUnderstanding+iOS.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if os(iOS)
#if targetEnvironment(simulator)
#else
import Foundation
import ARKit
import RealityKit
import OSLog

@available(iOS 18.0, *)
@available(visionOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
extension ARUnderstanding {
    public static var bodyUpdates: AsyncStream<CapturedAnchorUpdate<CapturedBodyAnchor>> {
        AsyncStream { continuation in
            let task = Task {
                for await anchor in ARUnderstanding(providers: [.body]).anchorUpdates {
                    guard !Task.isCancelled else { break }
                    switch anchor {
                    case .body(let bodyAnchor):
                        continuation.yield(bodyAnchor)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }
    
    public static var planeUpdates: AsyncStream<CapturedAnchorUpdate<CapturedPlaneAnchor>> {
        AsyncStream { continuation in
            let task = Task {
                for await anchor in ARUnderstanding(providers: [.planes]).anchorUpdates {
                    guard !Task.isCancelled else { break }
                    switch anchor {
                    case .plane(let planeAnchor):
                        continuation.yield(planeAnchor)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }
}

struct ARUnderstandingLiveInput: ARUnderstandingInput {
    private let providers: [ARProviderDefinition]
    private let logger: Logger
    
    init(providers: [ARProviderDefinition], logger: Logger = Logger(subsystem: "com.appsyoucanmake.ARUnderstanding", category: "ARUnderstandingLiveInput")) {
        self.providers = providers
        self.logger = logger
    }

    var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream<ARUnderstandingSession.Message> { continuation in
            #if targetEnvironment(macCatalyst)
            continuation.finish()
            #else
            guard !providers.isEmpty
            else {
                continuation.finish()
                return
            }
                
            if #available(iOS 18.0, *) {
                let providers = self.providers
                Task {
                    do {
                        continuation.yield(ARUnderstandingSession.Message.newSession)
                        try await Self.runSession(providers: providers, logger: logger, continuation)
                    } catch {
                        logger.error("Error running session: \(error.localizedDescription)")
                        continuation.finish()
                    }
                }
            } else {
                continuation.finish()
            }
            #endif
        }
    }
    
    @available(iOS 18.0, *)
    @available(visionOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    @MainActor private static func runSession(providers providerDefinitions: [ARProviderDefinition], logger: Logger, _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation) async {
        logger.debug("ARU LiveInput: Run session...")
        let providers = providerDefinitions.map(\.provider)
        let session = SpatialTrackingSession()
        let arSession = ARSession()
        let arDelegate = LiveARDelegate(providers: providers.map(\.dataProvider))
        let tracking: Set<SpatialTrackingSession.Configuration.AnchorCapability> = providers.flatMap(\.anchorCapabilities).reduce(Set<SpatialTrackingSession.Configuration.AnchorCapability>(), { $0.union($1) })
        let sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> = providers.flatMap(\.sceneUnderstanding).reduce(Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability>(), { $0.union($1) })
        let configuration = SpatialTrackingSession.Configuration(
            tracking: tracking,
            sceneUnderstanding: sceneUnderstanding)
        
        let arConfiguration = Self.configuration(providers)
        arDelegate.continuation = continuation
        arSession.delegate = arDelegate
        arSession.run(arConfiguration)
        let unavailableAnchors = await session.run(configuration, session: arSession, arConfiguration: arConfiguration)
//        arSession.delegate = arDelegate
//        arSession.run(arConfiguration)
        if let unavailableAnchors {
            logger.error("started SpatialTrackingSession unavailable: \(unavailableAnchors.anchor)")
        } else {
            logger.trace("started SpatialTrackingSession uneventfully")
        }
        logger.debug("ARU LiveInput: Session running")

        while true {
            logger.trace("providers: \(arDelegate.providers.count) \(arDelegate.providers.map(\.description))")
            try? await Task.sleep(for: .seconds(30))
        }
    }
    
    @available(iOS 18.0, *)
    private static func configuration(_ providers: [ARProvider]) -> ARConfiguration {
        switch (providers.count, providers.first) {
        case (_, .body):
            bodyConfiguration(providers)
        case (_, _):
            worldConfiguration(providers)
        }
    }
    
    @available(iOS 18.0, *)
    private static func bodyConfiguration(_ providers: [ARProvider]) -> ARBodyTrackingConfiguration {
        var bodyConfig = ARBodyTrackingConfiguration()
        for provider in providers {
            provider.configure(&bodyConfig)
        }
        return bodyConfig
    }
    
    @available(iOS 18.0, *)
    private static func worldConfiguration(_ providers: [ARProvider]) -> ARWorldTrackingConfiguration {
        var worldConfig = ARWorldTrackingConfiguration()
        for provider in providers {
            provider.configure(&worldConfig)
        }
        return worldConfig
    }
    
    @available(iOS 18.0, *)
    private static func stopSession(session: SpatialTrackingSession, arSession: ARSession) async throws {
        try? await session.stop()
        arSession.delegate = nil
        arSession.pause()
    }
}

@available(macCatalyst, unavailable)
@available(iOS, introduced: 18.0)
class LiveARDelegate: NSObject, ARSessionDelegate {
    let providers: [any ARDataProvider]
    var continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?
    
    init(providers: [any ARDataProvider]) {
        logger.trace("LiveARDelegate: \(providers)")
        self.providers = providers
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        for provider in providers {
            provider.session(session, didUpdate: frame, continuation)
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for provider in providers {
            provider.session(session, didAdd: anchors, continuation)
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for provider in providers {
            provider.session(session, didUpdate: anchors, continuation)
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for provider in providers {
            provider.session(session, didRemove: anchors, continuation)
        }
    }
}
#endif
#endif
