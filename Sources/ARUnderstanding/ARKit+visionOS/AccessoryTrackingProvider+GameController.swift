//
//  AccessoryTrackingProvider+DataInputProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/11/25.
//

#if os(visionOS)
import ARKit
import GameController

extension AccessoryTrackingProvider {
    static var connectedDevices: [GCDevice] {
        GCController.controllers()
            .filter({
                $0.productCategory == GCProductCategorySpatialController ||
                $0.productCategory == GCProductCategorySpatialStylus })
        +
        GCStylus.styli
            .filter({
                $0.productCategory == GCProductCategorySpatialController ||
                $0.productCategory == GCProductCategorySpatialStylus })

    }
    
    static func accessories(for devices: [GCDevice]) async -> [Accessory] {
        var accessories: [Accessory] = []
        for device in devices {
            do {
                let accessory = try await Accessory(device: device)
                accessories.append(accessory)
            } catch {
                logger.error("Could not convert device [category: \(device.productCategory)] to accessory: \(error)")
            }
        }
        return accessories
    }
}
#endif
