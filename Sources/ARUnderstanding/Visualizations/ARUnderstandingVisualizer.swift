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
    private var rootEntity: Entity
    private var baseEntity: Entity
    private var entities: [UUID: Entity] = [:]
    @MainActor public init(entity: Entity) {
        self.rootEntity = entity
        self.baseEntity = Entity()
        entity.addChild(baseEntity)
    }
    
    @MainActor public func setEntity(_ entity: Entity) {
        self.rootEntity = entity
        entity.addChild(baseEntity)
    }
    
    public func findEntity(for anchor: CapturedAnchor) -> Entity? {
        entities[anchor.id]
    }
    
    public func handleNewSession() async {
        entities.removeAll()
        await baseEntity.removeAllChildren()
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
