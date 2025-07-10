//
//  ARUnderstanding+visionOS.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if os(visionOS)
extension ARUnderstanding {
    public static var handUpdates: AsyncStream<CapturedAnchorUpdate<CapturedHandAnchor>> {
        AsyncStream { continuation in
            let task = Task {
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

    public static var meshUpdates: AsyncStream<CapturedAnchorUpdate<CapturedMeshAnchor>> {
        AsyncStream { continuation in
            let task = Task {
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }

    public static var deviceUpdates: AsyncStream<CapturedAnchorUpdate<CapturedDeviceAnchor>> {
        AsyncStream { continuation in
            let task = Task {
                for await anchor in ARUnderstanding(providers: [.device]).anchorUpdates {
                    switch anchor {
                    case .device(let deviceAnchor):
                        continuation.yield(deviceAnchor)
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

    public static var worldUpdates: AsyncStream<CapturedAnchorUpdate<CapturedWorldAnchor>> {
        AsyncStream { continuation in
            let task = Task {
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }
    
    public static var roomUpdates: AsyncStream<CapturedAnchorUpdate<CapturedRoomAnchor>> {
        AsyncStream { continuation in
            let task = Task {
                for await anchor in ARUnderstanding(providers: [.room]).anchorUpdates {
                    switch anchor {
                    case .room(let roomAnchor):
                        continuation.yield(roomAnchor)
                    default:
                        break
                    }
                }
            }
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }

    public static func imageUpdates(resourceGroupName groupName: String) -> AsyncStream<CapturedAnchorUpdate<CapturedImageAnchor>> {
        AsyncStream { continuation in
            let task = Task {
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }

    public static func objectUpdates(referenceObjects: [ReferenceObject]) -> AsyncStream<CapturedAnchorUpdate<CapturedObjectAnchor>> {
        AsyncStream { continuation in
            let task = Task {
                for await anchor in ARUnderstanding(providers: [.object(referenceObjects: referenceObjects)]).anchorUpdates {
                    switch anchor {
                    case .object(let objectAnchor):
                        continuation.yield(objectAnchor)
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

import Foundation
import ARKit
import OSLog

struct ARUnderstandingLiveInput: ARUnderstandingInput {
    private let providers: [ARProviderDefinition]
    private let logger: Logger

    init(providers: [ARProviderDefinition], logger: Logger) {
        self.providers = providers
        self.logger = logger
    }

    func providersFromDefinitions() -> [ARProvider] {
        providers.map(\.provider)
    }
    
    var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream<ARUnderstandingSession.Message> { continuation in
            let providersRunning = providersFromDefinitions()
            guard !providersRunning.isEmpty,
                  dataProvidersAreSupported(providersRunning),
                  isReadyToRun(providersRunning)
            else {
                return continuation.finish()
            }
            
            let logger = self.logger
            Task {
                do {
                    continuation.yield(ARUnderstandingSession.Message.newSession)
                    try await Self.startSession(providers: providersRunning, logger: logger, continuation)
                } catch {
                    logger.error("Error running session: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }
    
    private func isReadyToRun(_ providers: [ARProvider]) -> Bool {
        return providers.map(\.isReadyToRun).reduce(true, { $0 && $1 })
    }
    
    private func dataProvidersAreSupported(_ providers: [ARProvider]) -> Bool {
        return providers.map(\.isSupported).reduce(true, { $0 && $1 })
    }
    
    private static func startSession(providers providerDefinitions: [ARProvider], logger: Logger, _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation) async throws {
        let providers = providerDefinitions.map(\.dataProvider)
        let arSession = ARKitSession()
        try await arSession.run(providers)
        
        for provider in providers {
            Task {
                for await update in provider.messages {
                    switch update {
                    case .newSession:
                        break
                    default:
                        continuation.yield(update)
                    }
                }
            }
        }

        Self.monitorSessionEvents(logger, arSession, continuation)
    }
    private func runSession(_ providers: [ARProvider]) async throws {
    }
    
    private static func monitorSessionEvents(_ logger: Logger, _ arSession: ARKitSession, _ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation) {
        Task {
            for await event in arSession.events {
                switch event {
                case .authorizationChanged(type: let authType, status: let status):
                    logger.trace("Authorization changed for \(authType) to: \(status)")
                    
                    if status == .denied {
                        logger.error("Authorization Denied for: \(authType)")
                        switch continuation.yield(.authorizationDenied("Authorization denied for \(authType). Please allow in Settings.")) {
                        case .terminated: return
                        default: break
                        }
                    }
                case .dataProviderStateChanged(dataProviders: let providers, newState: let state, error: let error):
                    logger.trace("Data provider changed: \(providers), \(state)")
                    if let error {
                        logger.error("Data provider(s) reached an error state: \(error)")
                        switch continuation.yield(.trackingError("Something went wrong with \(providers). \(error.localizedDescription)")) {
                        case .terminated: return
                        default: break
                        }
                    }
                @unknown default:
                    logger.error("Unhandled new event type \(event)")
                }
            }
        }
    }
}
#endif
