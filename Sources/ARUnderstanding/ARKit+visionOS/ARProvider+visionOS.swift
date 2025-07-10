//
//  ARProvider.swift
//  
//
//  Created by John Haney on 4/7/24.
//

#if os(visionOS)
import ARKit
import Foundation
import RealityKit
import QuartzCore

public enum ARProvider: Sendable {
    case hands(HandTrackingProvider)
    case meshes(SceneReconstructionProvider)
    case planes(PlaneDetectionProvider)
    case image(ImageTrackingProvider)
    case object(ObjectTrackingProvider)
    case room(RoomTrackingProvider)
    case world(WorldTrackingProvider, QueryDeviceAnchor)
}

public enum ARProviderDefinition: Equatable {
    case hands
    case device
    case meshes
    case unclassifiedMeshes
    case planes
    case verticalPlanes
    case horizontalPlanes
    case slantedPlanes
    case room
    case image(resourceGroupName: String)
    case object(referenceObjects: [ReferenceObject])
    case world
}

public enum QueryDeviceAnchor: Sendable {
    case enabled
    case none
}

extension ARProviderDefinition {
    var provider: ARProvider {
        switch self {
        case .hands:
            .hands(HandTrackingProvider())
        case .device:
            .world(WorldTrackingProvider(), .enabled)
        case .meshes:
            .meshes(SceneReconstructionProvider(modes: [.classification]))
        case .unclassifiedMeshes:
            .meshes(SceneReconstructionProvider())
        case .planes:
                .planes(PlaneDetectionProvider(alignments: [.horizontal, .vertical, .slanted]))
        case .verticalPlanes:
            .planes(PlaneDetectionProvider(alignments: [.vertical]))
        case .horizontalPlanes:
            .planes(PlaneDetectionProvider(alignments: [.horizontal]))
        case .slantedPlanes:
            .planes(PlaneDetectionProvider(alignments: [.slanted]))
        case .image(let resourceGroupName):
            .image(ImageTrackingProvider(referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: resourceGroupName)))
        case .object(let referenceObjects):
                .object(ObjectTrackingProvider(referenceObjects: referenceObjects))
        case .world:
            .world(WorldTrackingProvider(), .none)
        case .room:
            .room(RoomTrackingProvider())
        }
    }
}

extension HandTrackingProvider: ARUnderstandingInput {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                for await update in anchorUpdates {
                    continuation.yield(.anchor(.hand(update.captured)))
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
}

extension ImageTrackingProvider: ARUnderstandingInput {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                for await update in anchorUpdates {
                    continuation.yield(.anchor(.image(update.captured)))
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
}

extension ObjectTrackingProvider: ARUnderstandingInput {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                for await update in anchorUpdates {
                    continuation.yield(.anchor(.object(update.captured)))
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
}

extension SceneReconstructionProvider: ARUnderstandingInput {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                for await update in anchorUpdates {
                    continuation.yield(.anchor(.mesh(update.captured)))
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
}

extension PlaneDetectionProvider: ARUnderstandingInput {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                for await update in anchorUpdates {
                    continuation.yield(.anchor(.plane(update.captured)))
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
}

protocol DataInputProvider: DataProvider, ARUnderstandingInput, Sendable {}

extension HandTrackingProvider: DataInputProvider {}
extension ImageTrackingProvider: DataInputProvider {}
extension ObjectTrackingProvider: DataInputProvider {}
extension PlaneDetectionProvider: DataInputProvider {}
extension RoomTrackingProvider: DataInputProvider {}
extension SceneReconstructionProvider: DataInputProvider {}
extension WorldTrackingProvider: DataInputProvider {}

extension WorldTrackingProvider {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        messages(withDevice: true)
    }
    
    private func messages(withDevice: Bool) -> AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let worldTrackingProvider = self
            let task = Task {
                for await update in worldTrackingProvider.anchorUpdates {
                    guard !Task.isCancelled else { return }
                    continuation.yield(.anchor(.world(update.captured)))
                }
            }
            let queryTask = Task {
                if withDevice {
                    var event = CapturedAnchorEvent.added
                    while worldTrackingProvider.state != .stopped {
                        guard !Task.isCancelled else { return }
                        if worldTrackingProvider.state == .running {
                            let timestamp: TimeInterval = CACurrentMediaTime()
                            if let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: timestamp) {
                                continuation.yield(.anchor(.device(CapturedAnchorUpdate(anchor: deviceAnchor.captured, timestamp: timestamp, event: event))))
                                event = .updated
                            }
                            try? await Task.sleep(for: .milliseconds(12))
                        } else {
                            try? await Task.sleep(for: .milliseconds(100))
                        }
                    }
                }
            }
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled:
                    task.cancel()
                    queryTask.cancel()
                default: break
                }
            }
        }
    }
}

extension RoomTrackingProvider {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                for await update in anchorUpdates {
                    continuation.yield(.anchor(.room(update.captured)))
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
}

extension ARProvider: ARUnderstandingInput {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        switch self {
        case .hands(let provider):
            provider.messages
        case .image(let provider):
            provider.messages
        case .object(let provider):
            provider.messages
        case .meshes(let provider):
            provider.messages
        case .planes(let provider):
            provider.messages
        case .world(let provider, _):
            provider.messages
        case .room(let provider):
            provider.messages
        }
    }
    
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
    
    var dataProvider: DataInputProvider {
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled:
                    task.cancel()
                    queryTask?.cancel()
                default: break
                }
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
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }
}
#endif
