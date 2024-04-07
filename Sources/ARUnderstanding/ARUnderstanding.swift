//
//  ARUnderstanding.swift
//  SimpleARKitVision
//
//  Created by John Haney on 3/31/24.
//

import ARKit
import RealityKit
import OSLog

@Observable
@MainActor
public class ARUnderstanding {
    public var logger = Logger(subsystem: "com.appsyoucanmake.ARUnderstanding", category: "general")
    private let session = ARKitSession()
    private(set) var providers: [ARProvider]
    public var errorState = false
    
    public init(providers: [ARProvider], logger: Logger? = nil) {
        self.providers = providers
        if let logger {
            self.logger = logger
        }
    }
    
    public convenience init(providers: [ARPoviderDefinition], logger: Logger? = nil) {
        self.init(providers: providers.map(\.provider), logger: logger)
    }
    
    private func runSession() async throws {
        try await session.run(providers.map(\.dataProvider))
    }
    
    private var dataProvidersAreSupported: Bool {
        return providers.map(\.isSupported).reduce(true, { $0 && $1 })
    }
    
    private var isReadyToRun: Bool {
        return providers.map(\.isReadyToRun).reduce(true, { $0 && $1 })
    }
    
    public var anchorUpdates: AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            Task {
                await self.build(continuation)
            }
        }
    }
    
    public static var handUpdates: AsyncStream<HandAnchor> {
        AsyncStream { continuation in
            Task {
                for await anchor in ARUnderstanding(providers: [.hands]).anchorUpdates {
                    switch anchor {
                    case .hand(let handAnchor):
                        continuation.yield(handAnchor)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
        }
    }

    public static var planeUpdates: AsyncStream<PlaneAnchor> {
        AsyncStream { continuation in
            Task {
                for await anchor in ARUnderstanding(providers: [.planes]).anchorUpdates {
                    switch anchor {
                    case .plane(let planeAnchor):
                        continuation.yield(planeAnchor)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
        }
    }

    public static var meshUpdates: AsyncStream<MeshAnchor> {
        AsyncStream { continuation in
            Task {
                for await anchor in ARUnderstanding(providers: [.meshes]).anchorUpdates {
                    switch anchor {
                    case .mesh(let meshAnchor):
                        continuation.yield(meshAnchor)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
        }
    }

    public static var worldUpdates: AsyncStream<WorldAnchor> {
        AsyncStream { continuation in
            Task {
                for await anchor in ARUnderstanding(providers: [.world]).anchorUpdates {
                    switch anchor {
                    case .world(let worldAnchor):
                        continuation.yield(worldAnchor)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
        }
    }

    public static func imageUpdates(resourceGroupName groupName: String) -> AsyncStream<ImageAnchor> {
        AsyncStream { continuation in
            Task {
                for await anchor in ARUnderstanding(providers: [.image(resourceGroupName: groupName)]).anchorUpdates {
                    switch anchor {
                    case .image(let imageAnchor):
                        continuation.yield(imageAnchor)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
        }
    }

    fileprivate func build(_ continuation: AsyncStream<CapturedAnchor>.Continuation) async {
        guard !providers.isEmpty,
              dataProvidersAreSupported,
              isReadyToRun 
        else {
            return continuation.finish()
        }
        
        try? await runSession()
        
        for updates in providers.map(\.anchorUpdates) {
            Task.detached {
                for await update in updates {
                    continuation.yield(update)
                }
            }
        }
        
        await monitorSessionEvents()
    }
    
    private func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(type: _, status: let status):
                logger.info("Authorization changed to: \(status)")
                
                if status == .denied {
                    errorState = true
                }
            case .dataProviderStateChanged(dataProviders: let providers, newState: let state, error: let error):
                logger.info("Data provider changed: \(providers), \(state)")
                if let error {
                    logger.error("Data provider reached an error state: \(error)")
                    errorState = true
                }
            @unknown default:
                fatalError("Unhandled new event type \(event)")
            }
        }
    }
}


extension ARProvider {
    var anchorUpdates: AsyncStream<CapturedAnchor> {
        switch self {
        case .hands(let provider):
            return AsyncStream { continuation in
                Task {
                    for await update in provider.anchorUpdates {
                        continuation.yield(CapturedAnchor.hand(update.anchor))
                    }
                }
            }
        default:
            return AsyncStream(unfolding: { nil })
        }
    }

    var isReadyToRun: Bool {
        switch self {
        case .hands(let handTrackingProvider):
            return handTrackingProvider.state == .initialized
        case .meshes(let sceneReconstructionProvider):
            return sceneReconstructionProvider.state == .initialized
        case .planes(let planeDetectionProvider):
            return planeDetectionProvider.state == .initialized
        case .image(let imageTrackingProvider):
            return imageTrackingProvider.state == .initialized
        case .world(let worldTrackingProvider):
            return worldTrackingProvider.state == .initialized
        }
    }
    
    var isSupported: Bool {
        switch self {
        case .hands(_):
            return HandTrackingProvider.isSupported
        case .meshes(_):
            return SceneReconstructionProvider.isSupported
        case .planes(_):
            return PlaneDetectionProvider.isSupported
        case .image(_):
            return ImageTrackingProvider.isSupported
        case .world(_):
            return WorldTrackingProvider.isSupported
        }
    }
    
    var dataProvider: DataProvider {
        switch self {
        case .hands(let handTrackingProvider):
            return handTrackingProvider
        case .meshes(let sceneReconstructionProvider):
            return sceneReconstructionProvider
        case .planes(let planeDetectionProvider):
            return planeDetectionProvider
        case .image(let imageTrackingProvider):
            return imageTrackingProvider
        case .world(let worldTrackingProvider):
            return worldTrackingProvider
        }
    }
}