//
//  CapturedAccessoryAnchor+PackCodable.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/6/25.
//

import Foundation

#if canImport(RealityKit)
import RealityKit
#endif
import simd
#if canImport(ARKit)
import ARKit
#endif

extension CapturedAccessoryAnchor: PackEncodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try originFromAnchorTransform.pack())
        
        output.append(try isTracked.pack())
        output.append(try trackingState.pack())
        output.append(try accessory.pack())
        if let heldChirality {
            output.append(try heldChirality.pack())
        } else {
            output.append(UInt8(0))
        }
        
        output.append(try velocity.pack())
        output.append(try angularVelocity.pack())
        return output
    }
}

extension Accessory.LocationName: PackCodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        guard let data = rawValue.data(using: .utf8)
        else { throw PackError.failed }
        output.append(try data.count.pack())
        output.append(data)
        return output
    }
    
    public static func unpack(data: Data) throws -> (Accessory.LocationName, Int) {
        let (count, bytes) = try Int.unpack(data: data)
        var offset = bytes
        guard data.count >= offset + count else {
            throw UnpackError.needsMoreData(offset + count - data.count)
        }
        let data = data[data.startIndex.advanced(by: offset)..<data.index(data.startIndex, offsetBy: offset + count)]
        offset += count
        guard let rawValue = String(data: data, encoding: .utf8)
        else {
            throw UnpackError.failed
        }
        let locationName = Accessory.LocationName(rawValue)
        return (locationName, offset)
    }
}

extension CapturedAccessory: PackCodable {
    public func pack() throws -> Data {
        var output: Data = Data()
        output.append(try id.pack())
        output.append(try inherentChirality.pack())
        output.append(try locations.pack())
        output.append(try name.pack())
        return output
    }
    
    public static func unpack(data: Data) throws -> (CapturedAccessory, Int) {
        throw UnpackError.failed
    }
}

protocol OneBytePackCodable: PackCodable {
    var packedValue: UInt8 { get }
    init?(packedValue: UInt8)
}

extension OneBytePackCodable {
    public func pack() throws -> Data {
        Data([packedValue])
    }
    
    public static func unpack(data: Data) throws -> (Self, Int) {
        guard !data.isEmpty
        else {
            throw UnpackError.needsMoreData(1)
        }
        let byte: UInt8 = data[data.startIndex]
        if let state = Self(packedValue: byte) {
            return (state, 1)
        } else {
            throw UnpackError.failed
        }
    }
}

extension ARKit.Accessory.Chirality: OneBytePackCodable {
    var packedValue: UInt8 {
        switch self {
        case .unspecified: 1
        case .left: 2
        case .right: 3
        @unknown default: 0
        }
    }
    
    init?(packedValue: UInt8) {
        switch packedValue {
        case 1: self = .unspecified
        case 2: self = .left
        case 3: self = .right
        default: return nil
        }
    }
}

extension AccessoryAnchor.TrackingState: OneBytePackCodable {
    var packedValue: UInt8 {
        switch self {
        case .untracked: 1
        case .orientationTracked: 2
        case .positionOrientationTracked: 3
        case .positionOrientationTrackedLowAccuracy: 4
        @unknown default: 0
        }
    }
    
    init?(packedValue: UInt8) {
        switch packedValue {
        case 1: self = .untracked
        case 2: self = .orientationTracked
        case 3: self = .positionOrientationTracked
        case 4: self = .positionOrientationTrackedLowAccuracy
        default: return nil
        }
    }
}

extension CapturedAccessoryAnchor: PackDecodable {
    public static func unpack(data: Data) throws -> (Self, Int) {
        guard data.count >= 16 + 64
        else {
            throw UnpackError.needsMoreData(16 + 64)
        }
        let (id, consumed) = try UUID.unpack(data: data)
        var offset = consumed
        let originFromAnchorTransform: simd_float4x4
        do {
            let (transform, consumed) = try simd_float4x4.unpack(data: data[(data.startIndex + offset)...])
            originFromAnchorTransform = transform
            offset += consumed
        }

        let isTracked: Bool
        do {
            let (tracked, consumed) = try Bool.unpack(data: data[(data.startIndex + offset)...])
            isTracked = tracked
            offset += consumed
        }
        
        let trackingState: AccessoryAnchor.TrackingState
        do {
            let (tracking, consumed) = try AccessoryAnchor.TrackingState.unpack(data: data[(data.startIndex + offset)...])
            trackingState = tracking
            offset += consumed
        }

        let accessory: CapturedAccessory
        do {
            let (value, consumed) = try CapturedAccessory.unpack(data: data[(data.startIndex + offset)...])
            accessory = value
            offset += consumed
        }
        
        let heldChirality: ARKit.Accessory.Chirality?
        do {
            let (chirality, consumed) = try ARKit.Accessory.Chirality.unpack(data: data[(data.startIndex + offset)...])
            heldChirality = chirality
            offset += consumed
        }
        
        let velocity: SIMD3<Float>
        do {
            let (velocityUnpacked, consumed) = try SIMD3<Float>.unpack(data: data[(data.startIndex + offset)...])
            velocity = velocityUnpacked
            offset += consumed
        }
        let angularVelocity: SIMD3<Float>
        do {
            let (angularVelocityUnpacked, consumed) = try SIMD3<Float>.unpack(data: data[(data.startIndex + offset)...])
            angularVelocity = angularVelocityUnpacked
            offset += consumed
        }
        
        return (
            CapturedAccessoryAnchor(
                id: id,
                originFromAnchorTransform: originFromAnchorTransform,
                isTracked: isTracked,
                trackingState: trackingState,
                accessory: accessory,
                heldChirality: heldChirality,
                velocity: velocity,
                angularVelocity: angularVelocity
            ),
            offset
        )
    }
}
