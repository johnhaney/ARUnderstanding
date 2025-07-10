//
//  CapturedImageAnchor.swift
//
//
//  Created by John Haney on 4/13/24.
//

import Foundation
#if canImport(ARKit)
import ARKit
#endif
#if canImport(RealityKit)
import RealityKit
#endif
import simd

public protocol ImageAnchorRepresentable: CapturableAnchor {
    var originFromAnchorTransform: simd_float4x4 { get }
    var isTracked: Bool { get }
    var id: UUID { get }
    var referenceImageName: String? { get }
    var estimatedScaleFactor: Float { get }
    var estimatedPhysicalWidth: Float { get }
    var estimatedPhysicalHeight: Float { get }
}

extension ImageAnchorRepresentable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

public struct CapturedImageAnchor: TrackableAnchor, ImageAnchorRepresentable, Sendable {
    public var id: UUID
    public var originFromAnchorTransform: simd_float4x4
    public var isTracked: Bool
    public var referenceImageName: String?
    public var estimatedScaleFactor: Float
    public var estimatedPhysicalWidth: Float
    public var estimatedPhysicalHeight: Float
    public var description: String { "Image \(originFromAnchorTransform) \(referenceImageName ?? "n/a") \(estimatedPhysicalWidth)x\(estimatedPhysicalHeight)" }
    
    public init(id: UUID, originFromAnchorTransform: simd_float4x4, isTracked: Bool, referenceImageName: String?, estimatedScaleFactor: Float, estimatedPhysicalWidth: Float, estimatedPhysicalHeight: Float) {
        self.id = id
        self.originFromAnchorTransform = originFromAnchorTransform
        self.isTracked = isTracked
        self.referenceImageName = referenceImageName
        self.estimatedScaleFactor = estimatedScaleFactor
        self.estimatedPhysicalWidth = estimatedPhysicalWidth
        self.estimatedPhysicalHeight = estimatedPhysicalHeight
    }
}

extension ImageAnchorRepresentable {
    public var captured: CapturedImageAnchor {
        CapturedImageAnchor(id: id, originFromAnchorTransform: originFromAnchorTransform, isTracked: isTracked, referenceImageName: referenceImageName, estimatedScaleFactor: estimatedScaleFactor, estimatedPhysicalWidth: estimatedPhysicalWidth, estimatedPhysicalHeight: estimatedPhysicalHeight)
    }
}

//public struct AnyImageAnchorRepresentable: ImageAnchorRepresentable {
//    private let _originFromAnchorTransform: @Sendable () -> simd_float4x4
//    private let _isTracked: @Sendable () -> Bool
//    private let _id: @Sendable () -> UUID
//    private let _referenceImageName: @Sendable () -> String?
//    private let _estimatedScaleFactor: @Sendable () -> Float
//    private let _estimatedPhysicalWidth: @Sendable () -> Float
//    private let _estimatedPhysicalHeight: @Sendable () -> Float
//    private let _description: @Sendable () -> String
//
//    public init<T: ImageAnchorRepresentable>(_ base: T) {
//        _originFromAnchorTransform = { base.originFromAnchorTransform }
//        _isTracked = { base.isTracked }
//        _id = { base.id }
//        _referenceImageName = { base.referenceImageName }
//        _estimatedScaleFactor = { base.estimatedScaleFactor }
//        _estimatedPhysicalWidth = { base.estimatedPhysicalWidth }
//        _estimatedPhysicalHeight = { base.estimatedPhysicalHeight }
//        _description = { base.description }
//    }
//
//    public var originFromAnchorTransform: simd_float4x4 { _originFromAnchorTransform() }
//    public var isTracked: Bool { _isTracked() }
//    public var id: UUID { _id() }
//    public var referenceImageName: String? { _referenceImageName() }
//    public var estimatedScaleFactor: Float { _estimatedScaleFactor() }
//    public var estimatedPhysicalWidth: Float { _estimatedPhysicalWidth() }
//    public var estimatedPhysicalHeight: Float { _estimatedPhysicalHeight() }
//    public var description: String { _description() }
//}
//
//extension ImageAnchorRepresentable {
//    var eraseToAny: AnyImageAnchorRepresentable {
//        AnyImageAnchorRepresentable(self)
//    }
//}
//
////public struct CapturedImageAnchor: ImageAnchorRepresentable, Sendable, Equatable, Hashable, Identifiable {
////    let base: AnyImageAnchorRepresentable
////    
////    public init<T: ImageAnchorRepresentable>(_ anchor: T) {
////        self.base = anchor.eraseToAny
////    }
////    
////    public var originFromAnchorTransform: simd_float4x4 { base.originFromAnchorTransform }
////    public var isTracked: Bool { base.isTracked }
////    public var id: UUID { base.id }
////    public var referenceImageName: String? { base.referenceImageName }
////    public var estimatedScaleFactor: Float { base.estimatedScaleFactor }
////    public var estimatedPhysicalWidth: Float { base.estimatedPhysicalWidth }
////    public var estimatedPhysicalHeight: Float { base.estimatedPhysicalHeight }
////    public var description: String { base.description }
////}
////
//public struct SavedImageAnchor: ImageAnchorRepresentable, Sendable {
//    public var originFromAnchorTransform: simd_float4x4
//    public var isTracked: Bool
//    public var id: UUID
//    public var referenceImageName: String?
//    public var estimatedScaleFactor: Float
//    public var estimatedPhysicalWidth: Float
//    public var estimatedPhysicalHeight: Float
//    public var description: String { "Image \(originFromAnchorTransform) \(referenceImageName ?? "n/a") \(estimatedPhysicalWidth)x\(estimatedPhysicalHeight)" }
//}
//
//extension ImageAnchorRepresentable {
//    public var captured: AnyImageAnchorRepresentable { eraseToAny }
//    public var saved: AnyImageAnchorRepresentable { eraseToAny }
//}
