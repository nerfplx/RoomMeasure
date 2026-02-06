import simd

struct MeasurementSegment {
    let start: SIMD3<Float>
    let end: SIMD3<Float>
    var distance: Float { simd_distance(start, end) }
}
