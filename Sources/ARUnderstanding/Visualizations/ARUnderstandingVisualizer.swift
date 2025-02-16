//
//  ARUnderstandingVisualizer.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/16/25.
//

import Foundation
import RealityKit

public class ARUnderstandingVisualizer: ARUnderstandingOutput {
    private var baseEntity: Entity
    public init(entity: Entity) {
        self.baseEntity = entity
    }
    
    public func handleNewSession() async {
        await baseEntity.removeAllChildren()
    }
    
    public func handleAnchor(_ anchor: CapturedAnchor) async {
        await anchor.visualize(in: baseEntity)
    }
}
