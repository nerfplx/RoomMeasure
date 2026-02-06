import Foundation
import SwiftData
import RoomPlan
import SwiftUI

@Model
final class MeasurementProject {
    var id: UUID
    var name: String
    var createdDate: Date
    var rooms: [Room]
    var pdfData: Data?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.rooms = []
    }
    
    var totalRooms: Int { rooms.count }
    var totalMeasurements: Int { rooms.reduce(0) { $0 + $1.measurements.count } }
    var totalArea: Float { rooms.reduce(0) { $0 + ($1.roomDimensions?.area ?? 0) } }
    var totalVolume: Float { rooms.reduce(0) { $0 + ($1.roomDimensions?.volume ?? 0) } }
}

@Model
final class Room {
    var id: UUID
    var name: String
    var createdDate: Date
    var roomDimensions: RoomDimensions?
    var measurements: [SingleMeasurement]
    var usdzData: Data?
    var notes: String?
    var wallInfos: [WallInfo]
    var doorInfos: [DoorWindowInfo]
    var windowInfos: [DoorWindowInfo]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.measurements = []
        self.wallInfos = []
        self.doorInfos = []
        self.windowInfos = []
    }
    
    var measurementCount: Int { measurements.count }
    var hasRoomScan: Bool { roomDimensions != nil || usdzData != nil }
}

@Model
final class RoomDimensions {
    var height: Float
    var area: Float
    var volume: Float
    var totalWallLength: Float
    var wallCount: Int
    
    init(height: Float, area: Float, volume: Float, totalWallLength: Float = 0, wallCount: Int = 0) {
        self.height           = height
        self.area             = area
        self.volume           = volume
        self.totalWallLength  = totalWallLength
        self.wallCount        = wallCount
    }
}

@Model
final class WallInfo {
    var centerX: Float
    var centerY: Float
    var centerZ: Float
    var directionX: Float
    var directionZ: Float
    var width: Float
    var height: Float
    
    init(centerX: Float, centerY: Float, centerZ: Float,
         directionX: Float, directionZ: Float,
         width: Float, height: Float) {
        self.centerX    = centerX
        self.centerY    = centerY
        self.centerZ    = centerZ
        self.directionX = directionX
        self.directionZ = directionZ
        self.width      = width
        self.height     = height
    }
    
    convenience init(from wall: CapturedRoom.Surface) {
        let t  = wall.transform
        let dx = Float(t.columns.0.x)
        let dz = Float(t.columns.0.z)
        let len = sqrt(dx*dx + dz*dz)
        self.init(
            centerX:    Float(t.columns.3.x),
            centerY:    Float(t.columns.3.y),
            centerZ:    Float(t.columns.3.z),
            directionX: len > 0.001 ? dx / len : 1.0,
            directionZ: len > 0.001 ? dz / len : 0.0,
            width:      wall.dimensions.x,
            height:     wall.dimensions.y
        )
    }
}

@Model
final class DoorWindowInfo {
    var centerX: Float
    var centerZ: Float
    var directionX: Float
    var directionZ: Float
    var width: Float
    var isDoor: Bool
    
    init(centerX: Float, centerZ: Float,
         directionX: Float, directionZ: Float,
         width: Float, isDoor: Bool) {
        self.centerX    = centerX
        self.centerZ    = centerZ
        self.directionX = directionX
        self.directionZ = directionZ
        self.width      = width
        self.isDoor     = isDoor
    }
    
    convenience init(from surface: CapturedRoom.Surface, isDoor: Bool) {
        let t  = surface.transform
        let dx = Float(t.columns.0.x)
        let dz = Float(t.columns.0.z)
        let len = sqrt(dx*dx + dz*dz)
        self.init(
            centerX:    Float(t.columns.3.x),
            centerZ:    Float(t.columns.3.z),
            directionX: len > 0.001 ? dx / len : 1.0,
            directionZ: len > 0.001 ? dz / len : 0.0,
            width:      surface.dimensions.x,
            isDoor:     isDoor
        )
    }
}

@Model
final class SingleMeasurement {
    var id: UUID
    var name: String
    var distance: Float
    var objectHeight: Float?
    var timestamp: Date
    var notes: String?
    
    init(name: String, distance: Float, objectHeight: Float? = nil, notes: String? = nil) {
        self.id        = UUID()
        self.name      = name
        self.distance  = distance
        self.objectHeight = objectHeight
        self.timestamp = Date()
        self.notes     = notes
    }
}
