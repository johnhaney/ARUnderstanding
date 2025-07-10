//
//  CapturedAnchor+PackCodable.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

extension CapturedAnchor: PackDecodable {
    public static func unpack(data: Data) throws -> (CapturedAnchor, Int) {
        guard data.count >= 10 else { throw UnpackError.needsMoreData(4) }
        var offset = 0
        let (timestamp, consumed) = try TimeInterval.unpack(data: data)
        offset += consumed
        let eventCode: UInt8 = data[data.startIndex + offset]
        guard let event = CapturedAnchorEvent(code: eventCode)
        else {
            throw UnpackError.failed
        }
        offset += 1
        let anchorTypeCode: UInt8 = data[data.startIndex + offset]
        offset += 1
        switch anchorTypeCode {
        case 1:
            let (handAnchor, consumed) = try CapturedHandAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.hand(CapturedAnchorUpdate<CapturedHandAnchor>(anchor: handAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 2:
            let (meshAnchor, consumed) = try CapturedMeshAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.mesh(CapturedAnchorUpdate<CapturedMeshAnchor>(anchor: meshAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 3:
            let (planeAnchor, consumed) = try CapturedPlaneAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.plane(CapturedAnchorUpdate<CapturedPlaneAnchor>(anchor: planeAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 4:
            let (imageAnchor, consumed) = try CapturedImageAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.image(CapturedAnchorUpdate<CapturedImageAnchor>(anchor: imageAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 5:
            let (worldAnchor, consumed) = try CapturedWorldAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.world(CapturedAnchorUpdate<CapturedWorldAnchor>(anchor: worldAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 6:
            let (deviceAnchor, consumed) = try CapturedDeviceAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.device(CapturedAnchorUpdate<CapturedDeviceAnchor>(anchor: deviceAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 7:
            let (roomAnchor, consumed) = try CapturedRoomAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.room(.init(anchor: roomAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 8:
            let (objectAnchor, consumed) = try CapturedObjectAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.object(CapturedAnchorUpdate<CapturedObjectAnchor>(anchor: objectAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 9:
            let (faceAnchor, consumed) = try CapturedFaceAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.face(CapturedAnchorUpdate<CapturedFaceAnchor>(anchor: faceAnchor.captured, timestamp: timestamp, event: event)), offset + consumed)
        case 10:
            let (bodyAnchor, consumed) = try CapturedBodyAnchor.unpack(data: data[(data.startIndex + offset)...])
            return (CapturedAnchor.body(CapturedAnchorUpdate<CapturedBodyAnchor>(anchor: bodyAnchor, timestamp: timestamp, event: event)), offset + consumed)
        default:
            logger.error("Unrecognized anchor type: \(anchorTypeCode)")
            throw UnpackError.failed
        }
    }
}

extension CapturedAnchor: PackEncodable {
    public func pack() throws -> Data {
        switch self {
        case .body(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(10)])
            output.append(try update.pack())
            return output
        case .device(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(6)])
            output.append(try update.pack())
            return output
        case .face(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(9)])
            output.append(try update.pack())
            return output
        case .hand(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(1)])
            output.append(try update.pack())
            return output
        case .image(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(4)])
            output.append(try update.pack())
            return output
        case .mesh(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(2)])
            output.append(try update.pack())
            return output
        case .object(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(8)])
            output.append(try update.pack())
            return output
        case .plane(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(3)])
            output.append(try update.pack())
            return output
        case .room(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(7)])
            output.append(try update.pack())
            return output
        case .world(let update):
            var output = try update.timestamp.pack()
            output.append(contentsOf: [event.code, UInt8(5)])
            output.append(try update.pack())
            return output
        }
    }
}

extension CapturedAnchorUpdate: PackEncodable where AnchorType: PackEncodable {
    public func pack() throws -> Data {
        try anchor.pack()
    }
}
//
//struct SavingAnchorUpdate<AnchorType: Anchor> {
//    let timestamp: TimeInterval
//    let event: UInt8
//    let update: CapturedAnchorUpdate<AnchorType>
//    var anchorType: UInt8 { update.anchor.code }
//}
//
//extension Anchor {
//    var code: UInt8 {
//        if let _ = self as? any HandAnchorRepresentable {
//            UInt8(1)
//        } else {
//            #warning("TODO: fill in the other types here")
//            UInt8(0)
//        }
//    }
//}
//
//extension SavingAnchorUpdate {
//    static func pack(item: SavingAnchorUpdate) throws -> Data {
//        var output = try item.timestamp.pack()
//        output.append(contentsOf: [item.event, item.anchorType])
//        output.append(try item.update.pack())
//    }
//    
//    init(_ item: CapturedAnchor) {
//        switch item {
//        case .hand(let update):
//            SavingAnchorUpdate(timestamp: update.timestamp, event: update.event.code, update: update)
//        case .mesh(let update):
//            SavingAnchorUpdate(timestamp: update.timestamp, event: update.event.code, update: update)
//        case .plane(let update):
//            SavingAnchorUpdate(timestamp: update.timestamp, event: update.event.code, update: update)
//        case .image(let update):
//            SavingAnchorUpdate(timestamp: update.timestamp, event: update.event.code, update: update)
//        case .world(let update):
//            SavingAnchorUpdate(timestamp: update.timestamp, event: update.event.code, update: update)
//        case .device(let update):
//            SavingAnchorUpdate(timestamp: update.timestamp, event: update.event.code, update: update)
//        case .room(let update):
//            SavingAnchorUpdate(timestamp: update.timestamp, event: update.event.code, update: update)
//        case .object(let update):
//            SavingAnchorUpdate(timestamp: update.timestamp, event: update.event.code, update: update)
//        }
//    }
//}
//
////struct SavedAnchorUpdate<AnchorType: Anchor> {
////    let timestamp: TimeInterval
////    let event: TimeInterval
////    let data: Data
////    func anchor() throws -> AnchorType {
////        try AnchorType.unpack(data: data)
////    }
////}
////
////extension SavedAnchorUpdate: PackDecodable {
////    static func unpack(data: Data) throws -> (SavedAnchorUpdate, Int) {
////        let length = data.count
////        // confirm we have enough data to unpack without the header
////        guard length < 16 else { throw UnpackError.needsMoreData(16) }
////
////        let (timestamp, consumed) = try TimeInterval.unpack(data: data)
////        var offset = consumed
////        let (event, consumed) = try TimeInterval.unpack(data: data[offset...])
////        offset += consumed
////        let expectedDataLength: Int
////        let anchorCode = data[offset]
////        offset += 1
////        switch anchorCode {
////        case CapturedHandAnchor.code:
////            expectedDataLength = CapturedHandAnchor.expectedPackedLength(data: data[offset...])
//////        case .mesh(let update):
//////            expectedDataLength = CapturedMeshAnchor.expectedPackedLength(data: data[offset...])
//////        case .plane(let update):
//////            expectedDataLength = CapturedPlaneAnchor.expectedPackedLength(data: data[offset...])
//////        case .image(let update):
//////            expectedDataLength = CapturedImageAnchor.expectedPackedLength(data: data[offset...])
//////        case .world(let update):
//////            expectedDataLength = CapturedWorldAnchor.expectedPackedLength(data: data[offset...])
//////        case .device(let update):
//////            expectedDataLength = CapturedDeviceAnchor.expectedPackedLength(data: data[offset...])
//////        case .room(let update):
//////            expectedDataLength = CapturedRoomAnchor.expectedPackedLength(data: data[offset...])
//////        case .object(let update):
//////            expectedDataLength = CapturedObjectAnchor.expectedPackedLength(data: data[offset...])
////        default:
////            throw UnpackError.failed
////        }
////        guard offset + expectedDataLength <= length else { throw UnpackError.needsMoreData(offset + expectedDataLength) }
////        let dataBlob = data[offset..<(offset+expectedDataLength)]
////        return (.init(timestamp: timestamp, event: event, data: dataBlob), offset + expectedDataLength)
////    }
////}
