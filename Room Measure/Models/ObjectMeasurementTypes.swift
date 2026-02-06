import SwiftUI
import simd

struct MeasurementResult: Identifiable {
    let id = UUID()
    let screenRect: CGRect
    let worldCorners: [simd_float3]
    let width:  Float
    let height: Float
}

enum InteractionState: Equatable {
    case idle
    case creating(start: CGPoint, current: CGPoint)
    case confirming(rect: CGRect)
    case resizing(edge: ResizeEdge, original: CGRect)
    case moving(startDrag: CGPoint, originalRect: CGRect)
}

enum ResizeEdge: Equatable {
    case topLeft, topRight, bottomLeft, bottomRight
    case top, bottom, left, right
}
