import Foundation

enum UnitHelper {

    static var isImperial: Bool {
        UserDefaults.standard.string(forKey: "measurementUnit") == "imperial"
    }

    static func length(_ meters: Float) -> String {
        if isImperial {
            let feet = meters * 3.28084
            if feet < 1 {
                return String(format: "%.1f in", feet * 12)
            }
            return String(format: "%.2f ft", feet)
        } else {
            if meters < 1 {
                return String(format: "%.0f см", meters * 100)
            }
            return String(format: "%.2f м", meters)
        }
    }

    static func lengthFull(_ meters: Float) -> String {
        if isImperial {
            return String(format: "%.2f ft", meters * 3.28084)
        }
        return String(format: "%.2f м", meters)
    }

    static func size(_ w: Float, _ h: Float) -> String {
        if isImperial {
            let wIn = w * 3.28084 * 12
            let hIn = h * 3.28084 * 12
            if wIn >= 12 || hIn >= 12 {
                return String(format: "%.2f × %.2f ft", w * 3.28084, h * 3.28084)
            }
            return String(format: "%.1f × %.1f in", wIn, hIn)
        } else {
            if w < 1 || h < 1 {
                return String(format: "%.0f × %.0f см", w * 100, h * 100)
            }
            return String(format: "%.2f × %.2f м", w, h)
        }
    }

    static func area(_ sqMeters: Float) -> String {
        if isImperial {
            return String(format: "%.1f ft²", sqMeters * 10.7639)
        }
        return String(format: "%.1f м²", sqMeters)
    }

    static func volume(_ cubMeters: Float) -> String {
        if isImperial {
            return String(format: "%.2f ft³", cubMeters * 35.3147)
        }
        return String(format: "%.2f м³", cubMeters)
    }

    static var lengthUnit: String  { isImperial ? "ft"  : "м"  }
    static var areaUnit: String    { isImperial ? "ft²" : "м²" }
    static var volumeUnit: String  { isImperial ? "ft³" : "м³" }

    static func sigma(_ meters: Float) -> String {
        "Σ \(lengthFull(meters))"
    }
}
