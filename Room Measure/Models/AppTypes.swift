import SwiftUI
import RoomPlan

enum MeasurementType: Identifiable {
    case roomScan
    case manual
    case objectMeasurement
    
    var id: MeasurementToolMode {
        switch self {
        case .roomScan:          return .space
        case .manual:            return .ruler
        case .objectMeasurement: return .object3D
        }
    }
}

extension MeasurementType {
    var icon: String {
        switch self {
        case .roomScan:          return "cube.transparent"
        case .manual:            return "ruler"
        case .objectMeasurement: return "arrow.counterclockwise"
        }
    }

    var accentColor: Color {
        switch self {
        case .roomScan:          return .blue
        case .manual:            return .green
        case .objectMeasurement: return .purple
        }
    }

    var selectorTitle: String {
        switch self {
        case .roomScan:          return LocalizedKey.projectSelector3DScan.localized
        case .manual:            return LocalizedKey.projectSelectorManualMeasurement.localized
        case .objectMeasurement: return LocalizedKey.measurementObjectScan.localized
        }
    }
}

enum MeasurementToolMode: Int, CaseIterable, Identifiable {
    case space    = 0
    case object3D = 1
    case ruler    = 2
    case level    = 3
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .space:    return LocalizedKey.spaceTitle.localized
        case .object3D: return LocalizedKey.object3DTitle.localized
        case .ruler:    return LocalizedKey.rulerTitle.localized
        case .level:    return LocalizedKey.levelTitle.localized
        }
    }
    
    var icon: String {
        switch self {
        case .space:    return "cube.transparent"
        case .object3D: return "move.3d"
        case .ruler:    return "ruler"
        case .level:    return "level"
        }
    }
}

enum RoomSource {
    case live(CapturedRoom)
    case saved(
        usdzData:    Data,
        wallInfos:   [WallInfo],
        doorInfos:   [DoorWindowInfo],
        windowInfos: [DoorWindowInfo],
        dimensions:  RoomDimensions?
    )
}
