//
//  ARUnderstandingVisualizer.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/16/25.
//

#if canImport(RealityKit)
import Foundation
import SwiftUI
import RealityKit

@available(visionOS, introduced: 2.0)
@available(iOS, introduced: 18.0)
@available(tvOS, introduced: 26.0)
@available(macOS, introduced: 15.0)
public class ARUnderstandingVisualizer: ARUnderstandingOutput {
    private var rootEntity: Entity // Entity provided to Visualizer, Visualizer adds baseEntity to rootEntity
    private var baseEntity: Entity // Entity managed by ARUnderstandingVisualizer, all visualizations are children of baseEntity
    private var entities: [UUID: Entity] = [:]
    @MainActor public init(entity: Entity) {
        self.rootEntity = entity
        self.baseEntity = Entity()
        entity.addChild(baseEntity)
    }
    
    @MainActor public func setEntity(_ entity: Entity) {
        self.rootEntity = entity
        // Migrate the visualizations to this new rootEntity by adding the baseEntity
        entity.addChild(baseEntity)
    }
    
    public func findEntity(for anchor: CapturedAnchor) -> Entity? {
        entities[anchor.id]
    }
    
    public func handle(_ message: ARUnderstandingSession.Message) async {
        switch message {
        case .newSession:
            await handleNewSession()
        case .anchor(let capturedAnchor):
            await handleAnchor(capturedAnchor)
        case .authorizationDenied:
            break
        case .trackingError:
            break
        case .unknown:
            break
        }
    }
    
    @MainActor public func handleNewSession() async {
        entities.removeAll()
        
        // Clear out the old base entity
        baseEntity.removeFromParent()
        
        // replace the base entity with a new one
        baseEntity = Entity()
        rootEntity.addChild(baseEntity)
    }
    
    @MainActor public func handleAnchor(_ anchor: CapturedAnchor) async {
        guard anchor.event != .removed else { return }
        if let existing = entities[anchor.uniqueId] {
            await anchor.visualize(in: existing, with: [anchor.defaultMaterial])
        } else {
            let entity = Entity()
            entities[anchor.uniqueId] = entity
            baseEntity.addChild(entity)
            await anchor.visualize(in: entity, with: [anchor.defaultMaterial])
        }
    }
}
#endif
