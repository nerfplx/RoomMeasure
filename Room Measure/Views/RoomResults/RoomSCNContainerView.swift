import UIKit
import SceneKit
import simd

final class RoomSCNContainerView: UIView {

    private let scnView = SCNView()
    private var labelViews: [WallLabelView] = []

    private struct WallLabel {
        let labelPos: SCNVector3
        let text: String
    }
    private var wallLabels: [WallLabel] = []
    private var displayLink: CADisplayLink?

    func setup(usdzURL: URL, wallInfos: [WallInfo]) {
        scnView.frame = bounds
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scnView)

        guard let scene = try? SCNScene(url: usdzURL) else { return }
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = UIColor.systemBackground

        applyMaterials(to: scene.rootNode)
        addCustomLighting(to: scene)
        buildLabelsAndLines(wallInfos: wallInfos, scene: scene)
        startLabelTracking()
    }

    private func applyMaterials(to node: SCNNode) {
        if let geometry = node.geometry {
            let name = (node.name ?? "").lowercased()
            let isDoor   = name.contains("door")   || name.contains("дверь")
            let isWindow = name.contains("window") || name.contains("окно")
            let isOpening = isDoor || isWindow

            geometry.materials = geometry.materials.map { _ in
                let mat = SCNMaterial()
                if isOpening {
                    mat.diffuse.contents = UIColor(white: 0.15, alpha: 1.0)
                } else {
                    mat.diffuse.contents = UIColor(white: 0.60, alpha: 1.0)
                }
                mat.specular.contents = UIColor(white: 0.3, alpha: 1.0)
                mat.shininess = 0.2
                mat.lightingModel = .phong
                return mat
            }
        }
        for child in node.childNodes { applyMaterials(to: child) }
    }

    private func addCustomLighting(to scene: SCNScene) {
        let ambientNode = SCNNode()
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(white: 0.55, alpha: 1.0)
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let keyNode = SCNNode()
        let key = SCNLight()
        key.type = .directional
        key.color = UIColor(white: 1.0, alpha: 1.0)
        key.intensity = 850
        keyNode.light = key
        keyNode.eulerAngles = SCNVector3(-Float.pi / 3.5, Float.pi / 5, 0)
        scene.rootNode.addChildNode(keyNode)

        let fillNode = SCNNode()
        let fill = SCNLight()
        fill.type = .directional
        fill.color = UIColor(white: 0.8, alpha: 1.0)
        fill.intensity = 250
        fillNode.light = fill
        fillNode.eulerAngles = SCNVector3(-Float.pi / 8, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillNode)
    }

    private func buildLabelsAndLines(wallInfos: [WallInfo], scene: SCNScene) {
        for (index, wall) in wallInfos.enumerated() {
            let wallNumber = index + 1
            let topY  = wall.centerY + wall.height / 2
            let halfW = wall.width / 2
            let nx    = wall.directionX
            let nz    = wall.directionZ

            let leftPos  = SCNVector3(wall.centerX - nx * halfW, topY, wall.centerZ - nz * halfW)
            let rightPos = SCNVector3(wall.centerX + nx * halfW, topY, wall.centerZ + nz * halfW)
            let labelPos = SCNVector3(wall.centerX, topY + 0.12, wall.centerZ)

            let text = "\(wallNumber).  \(UnitHelper.lengthFull(wall.width))"
            wallLabels.append(WallLabel(labelPos: labelPos, text: text))

            addLineNode(from: leftPos, to: rightPos, in: scene)

            let tickH: Float = 0.10
            addLineNode(from: SCNVector3(leftPos.x,  leftPos.y  - tickH/2, leftPos.z),
                        to:   SCNVector3(leftPos.x,  leftPos.y  + tickH/2, leftPos.z), in: scene)
            addLineNode(from: SCNVector3(rightPos.x, rightPos.y - tickH/2, rightPos.z),
                        to:   SCNVector3(rightPos.x, rightPos.y + tickH/2, rightPos.z), in: scene)

            let label = WallLabelView()
            label.setText(text)
            label.alpha = 0
            addSubview(label)
            labelViews.append(label)
        }
    }

    private func addLineNode(from start: SCNVector3, to end: SCNVector3, in scene: SCNScene) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        let length = sqrt(dx*dx + dy*dy + dz*dz)
        guard length > 0.001 else { return }

        let cylinder = SCNCylinder(radius: 0.007, height: CGFloat(length))
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(white: 0.95, alpha: 1.0)
        mat.lightingModel = .constant
        cylinder.materials = [mat]

        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3((start.x+end.x)/2, (start.y+end.y)/2, (start.z+end.z)/2)

        let direction = simd_normalize(simd_float3(dx, dy, dz))
        let yAxis     = simd_float3(0, 1, 0)
        let rotAxis   = simd_cross(yAxis, direction)
        if simd_length(rotAxis) > 0.001 {
            let angle = acos(max(-1, min(1, simd_dot(yAxis, direction))))
            node.simdOrientation = simd_quaternion(angle, simd_normalize(rotAxis))
        }
        scene.rootNode.addChildNode(node)
    }

    private func startLabelTracking() {
        let link = CADisplayLink(target: self, selector: #selector(updateLabelPositions))
        link.add(to: .main, forMode: .default)
        displayLink = link
    }

    @objc private func updateLabelPositions() {
        guard wallLabels.count == labelViews.count else { return }
        for (i, entry) in wallLabels.enumerated() {
            let label     = labelViews[i]
            let projected = scnView.projectPoint(entry.labelPos)
            guard projected.z > 0, projected.z < 1 else { label.alpha = 0; continue }
            let pt = CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y))
            guard bounds.contains(pt) else { label.alpha = 0; continue }
            let sz = label.intrinsicContentSize
            label.frame = CGRect(x: pt.x - sz.width/2, y: pt.y - sz.height/2,
                                 width: sz.width, height: sz.height)
            if label.alpha == 0 { UIView.animate(withDuration: 0.15) { label.alpha = 1 } }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scnView.frame = bounds
    }

    deinit { displayLink?.invalidate() }
}

final class WallLabelView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = UIColor(white: 0.08, alpha: 0.82)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9)
        ])
    }

    func setText(_ text: String) { label.text = text; invalidateIntrinsicContentSize() }

    override var intrinsicContentSize: CGSize {
        let s = label.intrinsicContentSize
        return CGSize(width: s.width + 18, height: s.height + 10)
    }
}
