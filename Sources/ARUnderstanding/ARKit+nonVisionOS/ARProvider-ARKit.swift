//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if !os(visionOS) && !os(iOS) && !os(macOS)
import Foundation

public enum ARProvider {
    case device
}

public enum ARProviderDefinition: Equatable {}

extension ARProviderDefinition {
    var provider: ARProvider {
        ARProvider.device
    }
}

extension ARProvider {
    func matches(rhs: ARProvider) -> Bool { true }
}

#endif
