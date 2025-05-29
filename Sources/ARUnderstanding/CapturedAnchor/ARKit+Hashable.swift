//
//  ARKit+Hashable.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if canImport(ARKit)
import ARKit
#else
import RealityKit
#endif

extension simd_float4x4: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(columns.0)
        hasher.combine(columns.1)
        hasher.combine(columns.2)
        hasher.combine(columns.3)
    }
}
