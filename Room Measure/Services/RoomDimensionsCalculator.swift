import RoomPlan
import simd

struct RoomDimensionsCalculator {

    static func calculate(from capturedRoom: CapturedRoom) -> (height: Float, area: Float, volume: Float)? {
        guard !capturedRoom.walls.isEmpty else { return nil }
        let avgHeight = capturedRoom.walls.map(\.dimensions.y).reduce(0, +) / Float(capturedRoom.walls.count)
        let area      = polygonArea(walls: capturedRoom.walls)
        return (avgHeight, area, area * avgHeight)
    }

    private static func polygonArea(walls: [CapturedRoom.Surface]) -> Float {
        typealias Seg = (a: SIMD2<Float>, b: SIMD2<Float>)
        var segments: [Seg] = []
        for wall in walls {
            let t = wall.transform
            let cx = Float(t.columns.3.x), cz = Float(t.columns.3.z)
            let dx = Float(t.columns.0.x), dz = Float(t.columns.0.z)
            let len = sqrt(dx*dx + dz*dz)
            let nx = len > 0.001 ? dx/len : 1, nz = len > 0.001 ? dz/len : 0
            let hw = wall.dimensions.x / 2
            segments.append((SIMD2(cx-nx*hw, cz-nz*hw), SIMD2(cx+nx*hw, cz+nz*hw)))
        }
        var polygon = buildPolygon(from: segments, snap: 0.30)
        if polygon.count < 3 { polygon = convexHull(points: segments.flatMap { [$0.a, $0.b] }) }
        return shoelace(polygon)
    }

    private static func buildPolygon(from segs: [(a: SIMD2<Float>, b: SIMD2<Float>)], snap: Float) -> [SIMD2<Float>] {
        var verts: [SIMD2<Float>] = []
        func snapped(_ p: SIMD2<Float>) -> SIMD2<Float> {
            verts.first(where: { simd_distance($0, p) < snap }) ?? { verts.append(p); return p }()
        }
        var edges: [(Int, Int)] = []
        for s in segs {
            let va = snapped(s.a), vb = snapped(s.b)
            guard let ia = verts.firstIndex(of: va), let ib = verts.firstIndex(of: vb), ia != ib else { continue }
            edges.append((ia, ib))
        }
        guard !edges.isEmpty else { return verts }
        var adj = [Int:[Int]]()
        for (a,b) in edges { adj[a, default:[]].append(b); adj[b, default:[]].append(a) }
        var path = [edges[0].0], visited: Set<Int> = [edges[0].0], cur = edges[0].0
        while let next = adj[cur]?.first(where: { !visited.contains($0) }) {
            path.append(next); visited.insert(next); cur = next
        }
        return path.map { verts[$0] }
    }

    private static func shoelace(_ p: [SIMD2<Float>]) -> Float {
        guard p.count >= 3 else { return 0 }
        var s: Float = 0
        for i in 0..<p.count { let j = (i+1) % p.count; s += p[i].x*p[j].y - p[j].x*p[i].y }
        return abs(s) / 2
    }

    private static func convexHull(points: [SIMD2<Float>]) -> [SIMD2<Float>] {
        guard points.count >= 3 else { return points }
        var s = 0
        for i in 1..<points.count { if points[i].x < points[s].x { s = i } }
        var hull: [SIMD2<Float>] = [], cur = s
        repeat {
            hull.append(points[cur]); var next = (cur+1) % points.count
            for i in 0..<points.count {
                let cross = (points[next].x-points[cur].x)*(points[i].y-points[cur].y)
                          - (points[next].y-points[cur].y)*(points[i].x-points[cur].x)
                if cross < 0 { next = i }
            }
            cur = next
        } while cur != s && hull.count <= points.count
        return hull
    }
}
