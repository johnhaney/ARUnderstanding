//
//  ARUnderstandingAccessoryTrackingProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/6/25.
//

#if os(visionOS)
import ARKit
import GameController

public final class ARUnderstandingAccessoryTrackingProvider: ARUnderstandingInputProvider {
    private static let arSession: ARKitSession = ARKitSession()
    
    let accessoryCategories: Set<AccessoryCategory>
    @MainActor static var anchorContinuations: [UUID: AsyncStream<CapturedAnchorUpdate<CapturedAccessoryAnchor>>.Continuation] = [:]
    
    @MainActor static func yield(_ update: CapturedAnchorUpdate<CapturedAccessoryAnchor>) {
        let continutations = Array(anchorContinuations.values)
        for continuation in continutations {
            continuation.yield(update)
        }
    }
    
    @MainActor static var anchorSession: UUID = UUID()
    
    private static func anchorUpdates(uuid: UUID) -> AsyncStream<CapturedAnchorUpdate<CapturedAccessoryAnchor>> {
        AsyncStream { continuation in
            let task = Task {
                let thisAnchorSession = UUID()
                await MainActor.run {
                    Self.anchorContinuations[uuid] = continuation
                    Self.anchorSession = thisAnchorSession
                }
                let devices = AccessoryTrackingProvider.connectedDevices
                let accessories: [Accessory] = await AccessoryTrackingProvider.accessories(for: devices)
                let provider = AccessoryTrackingProvider(accessories: accessories)
                try? await arSession.run([provider])
                for await update in provider.anchorUpdates {
                    guard !Task.isCancelled,
                          await Self.anchorSession == thisAnchorSession
                    else { break }
                    
                    await Self.yield(update.captured)
                }
            }
            continuation.onTermination = { termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }

    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        Self.messages
    }
    
    private static var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                let uuid = UUID()
                for await update in Self.anchorUpdates(uuid: uuid) {
                    guard !Task.isCancelled else { break }
                    continuation.yield(.anchor(.accessory(update)))
                }
                continuation.finish()
                Task { @MainActor in
                    Self.anchorContinuations.removeValue(forKey: uuid)
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
    
    init(accessoryCategories: Set<AccessoryCategory>) {
        self.accessoryCategories = accessoryCategories
        if !accessoryCategories.isEmpty {
            registerForControllerNotifications()
        }
    }
    
    func registerForControllerNotifications() {
        let connectedChange: @Sendable (Notification) -> Void = { notification in
            if let controller = notification.object as? GCController {
                switch controller.productCategory {
                case GCProductCategorySpatialController:
                    Task { @MainActor in
                        await Self.updateTask()
                    }
                case GCProductCategorySpatialStylus:
                    Task { @MainActor in
                        await Self.updateTask()
                    }
                default:
                    break
                }
            } else if let stylus = notification.object as? GCStylus {
                switch stylus.productCategory {
                case GCProductCategorySpatialStylus:
                    Task { @MainActor in
                        await Self.updateTask()
                    }
                default:
                    break
                }
            }
        }
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil, using: connectedChange)
        NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil, using: connectedChange)
        NotificationCenter.default.addObserver(forName: .GCStylusDidConnect, object: nil, queue: nil, using: connectedChange)
        NotificationCenter.default.addObserver(forName: .GCStylusDidDisconnect, object: nil, queue: nil, using: connectedChange)
    }
    
    @MainActor static func updateTask() async {
        if !Self.anchorContinuations.isEmpty {
            Task.detached {
                for await message in messages {
                    // waiting for message
//                    print("spatial controller updated")
                }
            }
        }
    }
}

extension ARUnderstandingAccessoryTrackingProvider {}
#endif
