//
//  ARProvider.swift
//  
//
//  Created by John Haney on 3/1/25.
//

#if os(macOS)
import Foundation
import RealityKit

public enum ARProvider {
    case device
//    case device(HeadTrackingProvider)
}

public enum ARProviderDefinition: Equatable {
    case device
//    case body
//    case meshes
//    case unclassifiedMeshes
//    case planes
//    case verticalPlanes
//    case horizontalPlanes
//    case room
//    case image(resourceGroupName: String)
//    case object(referenceObjects: [ReferenceObject])
//    case appClipCode
//    case geographic
}

public enum QueryDeviceAnchor {
    case enabled
    case none
}

extension ARProviderDefinition {
    var provider: ARProvider {
        switch self {
        case .device:
            .device
        }
    }
}

extension ARProvider {
    nonisolated func matches(rhs: ARProvider) -> Bool {
        false
    }
    
    var provider: ARProvider {
        .device
    }
}
#endif
