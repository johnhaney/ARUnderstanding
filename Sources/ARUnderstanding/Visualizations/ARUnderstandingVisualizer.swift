//
//  ARUnderstandingVisualizer.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/16/25.
//

import Foundation
import SwiftUI
import RealityKit

@Observable
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
    
    @MainActor public func handleNewSession() async {
        entities.removeAll()
        
        // Clear out the old base entity
        baseEntity.removeFromParent()
        
        // replace the base entity with a new one
        baseEntity = Entity()
        rootEntity.addChild(baseEntity)
    }
    
    @MainActor public func handleAnchor(_ anchor: CapturedAnchor) {
        if let existing = entities[anchor.id] {
            anchor.visualize(in: existing)
        } else {
            let entity = Entity()
            entities[anchor.id] = entity
            anchor.visualize(in: entity)
            baseEntity.addChild(entity)
        }
    }
}
