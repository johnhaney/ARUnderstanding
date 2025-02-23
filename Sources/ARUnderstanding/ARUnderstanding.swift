//
//  ARUnderstanding.swift
//  SimpleARKitVision
//
//  Created by John Haney on 3/31/24.
//

#if canImport(ARKit)
import ARKit
#endif
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
    
    public convenience init(providers: [ARProviderDefinition], logger: Logger? = nil) {
        let providers = Self.accumulate(providers, logger: logger ?? Logger(subsystem: "com.appsyoucanmake.ARUnderstanding", category: "general"))
        self.init(providers: providers, logger: logger)
    }
    
    private static func accumulate(_ definitions: [ARProviderDefinition], logger: Logger) -> [ARProvider] {
        let oneToOneMapping: [ARProvider] = definitions.map(\.provider)
        var queue = oneToOneMapping
        var result: [ARProvider] = []
        while !queue.isEmpty {
            let item = queue.removeFirst()
            let overlaps = queue.filter(item.matches)
            if !overlaps.isEmpty {
                // Resolve the conflict
                logger.warning("More than one of the same kind of ARProvider was requested, using only the first one in the list. Ignored: \(overlaps)")
                queue.removeAll(where: item.matches)
            }
            result.append(item)
        }
        return result
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
            let task = Task {
                await self.build(continuation)
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
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
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
            continuation.onTermination = { @Sendable _ in
                task.cancel()
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
        
        do {
            try await runSession()
            
            for updates in providers.map(\.anchorUpdates) {
                let task = Task {
                    for await update in updates {
                        continuation.yield(update)
                    }
                }
                continuation.onTermination = { @Sendable _ in
                    task.cancel()
                }
            }
            
            await monitorSessionEvents()
        } catch {
            logger.error("Error running session: \(error.localizedDescription)")
            continuation.finish()
        }
    }
    
    private func monitorSessionEvents() async {
#if os(visionOS)
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
                logger.error("Unhandled new event type \(event)")
                fatalError("Unhandled new event type \(event)")
            }
        }
#endif
    }
}

import QuartzCore

extension ARProvider {
    nonisolated func matches(rhs: ARProvider) -> Bool {
        switch (self, rhs) {
        case (.hands, .hands):
            return true
        case (.meshes, .meshes):
            return true
        case (.planes, .planes):
            return true
        case (.image, .image):
            return true
        case (.world, .world):
            return true
        case (.room, .room):
            return true
        case (.object, .object):
            return true
        case (.hands, _):
            return false
        case (.meshes, _):
            return false
        case (.planes, _):
            return false
        case (.image, _):
            return false
        case (.world, _):
            return false
        case (.room, _):
            return false
        case (.object, _):
            return false
        }
    }
    
    var anchorUpdates: AsyncStream<CapturedAnchor> {
        switch self {
        case .hands(let provider):
            return handAnchorStream(provider)
        case .image(let provider):
            return imageAnchorStream(provider)
        case .object(let provider):
            return objectAnchorStream(provider)
        case .meshes(let provider):
            return meshAnchorStream(provider)
        case .planes(let provider):
            return planeAnchorStream(provider)
        case .world(let provider, let queryDevice):
            return worldAnchorStream(provider, queryDevice: queryDevice)
        case .room(let provider):
            return roomAnchorStream(provider)
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
        case .object(let objectTrackingProvider):
            return objectTrackingProvider.state == .initialized
        case .world(let worldTrackingProvider, _):
            return worldTrackingProvider.state == .initialized
        case .room(let roomTrackingProvider):
            return roomTrackingProvider.state == .initialized
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
        case .object(_):
            return ObjectTrackingProvider.isSupported
        case .world(_, _):
            return WorldTrackingProvider.isSupported
        case .room(_):
            return RoomTrackingProvider.isSupported
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
        case .object(let objectTrackingProvider):
            return objectTrackingProvider
        case .world(let worldTrackingProvider, _):
            return worldTrackingProvider
        case .room(let roomTrackingProvider):
            return roomTrackingProvider
        }
    }
}

extension ARProvider {
    func handAnchorStream(_ provider: HandTrackingProvider) -> AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let task = Task {
                for await update in provider.anchorUpdates {
                    continuation.yield(.hand(update.captured))
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    func imageAnchorStream(_ provider: ImageTrackingProvider) -> AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let task = Task {
                for await update in provider.anchorUpdates {
                    continuation.yield(.image(update.captured))
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    func objectAnchorStream(_ provider: ObjectTrackingProvider) -> AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let task = Task {
                for await update in provider.anchorUpdates {
                    continuation.yield(.object(update.captured))
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    func meshAnchorStream(_ provider: SceneReconstructionProvider) -> AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let task = Task {
                for await update in provider.anchorUpdates {
                    continuation.yield(.mesh(update.captured))
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    func planeAnchorStream(_ provider: PlaneDetectionProvider) -> AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let task = Task {
                for await update in provider.anchorUpdates {
                    continuation.yield(.plane(update.captured))
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    func worldAnchorStream(_ provider: WorldTrackingProvider, queryDevice: QueryDeviceAnchor) -> AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let task = Task {
                for await update in provider.anchorUpdates {
                    continuation.yield(.world(update.captured))
                }
            }
            let queryTask: Task<(), Never>?
            switch queryDevice {
            case .enabled:
                queryTask = Task {
                    var event = CapturedAnchorEvent.added
                    while provider.state != .stopped {
                        if provider.state == .running {
                            let timestamp: TimeInterval = CACurrentMediaTime()
                            if let deviceAnchor = provider.queryDeviceAnchor(atTimestamp: timestamp) {
                                continuation.yield(.device(CapturedAnchorUpdate(anchor: deviceAnchor.captured, timestamp: timestamp, event: event)))
                                event = .updated
                            }
                            try? await Task.sleep(for: .milliseconds(12))
                        } else {
                            try? await Task.sleep(for: .milliseconds(100))
                        }
                    }
                }
            case .none:
                queryTask = nil
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
                queryTask?.cancel()
            }
        }
    }
    
    func roomAnchorStream(_ provider: RoomTrackingProvider) -> AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let task = Task {
                for await update in provider.anchorUpdates {
                    continuation.yield(.room(update.captured))
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

extension ARUnderstanding: ARUnderstandingInput {
    @MainActor public var sessionUpdates: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                defer { continuation.finish() }
                continuation.yield(ARUnderstandingSession.Message.newSession)
                for await update in self.anchorUpdates {
                    do {
                        let anchor = try CapturedAnchorProxy(anchor: update)
                        continuation.yield(ARUnderstandingSession.Message.anchor(anchor))
                    } catch {
                        
                    }
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
