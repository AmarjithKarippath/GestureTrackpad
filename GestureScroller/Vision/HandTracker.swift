import CoreGraphics
import Foundation
import Vision

struct HandLandmark: Identifiable {
    let id: String
    let name: VNHumanHandPoseObservation.JointName
    let point: CGPoint
    let confidence: Float
}

struct HandLandmarks {
    let joints: [VNHumanHandPoseObservation.JointName: HandLandmark]

    var overlayPoints: [CGPoint] {
        joints.values.map(\.point)
    }

    func point(_ name: VNHumanHandPoseObservation.JointName) -> CGPoint? {
        joints[name]?.point
    }

    var wrist: CGPoint? { point(.wrist) }

    var palmCenter: CGPoint? {
        let names: [VNHumanHandPoseObservation.JointName] = [.wrist, .indexMCP, .middleMCP, .ringMCP, .littleMCP]
        let pts = names.compactMap(point)
        guard !pts.isEmpty else { return nil }
        let sum = pts.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(pts.count), y: sum.y / CGFloat(pts.count))
    }

    static let bonePairs: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
        (.wrist, .thumbCMC), (.thumbCMC, .thumbMP), (.thumbMP, .thumbIP), (.thumbIP, .thumbTip),
        (.wrist, .indexMCP), (.indexMCP, .indexPIP), (.indexPIP, .indexDIP), (.indexDIP, .indexTip),
        (.wrist, .middleMCP), (.middleMCP, .middlePIP), (.middlePIP, .middleDIP), (.middleDIP, .middleTip),
        (.wrist, .ringMCP), (.ringMCP, .ringPIP), (.ringPIP, .ringDIP), (.ringDIP, .ringTip),
        (.wrist, .littleMCP), (.littleMCP, .littlePIP), (.littlePIP, .littleDIP), (.littleDIP, .littleTip),
        (.indexMCP, .middleMCP), (.middleMCP, .ringMCP), (.ringMCP, .littleMCP)
    ]
}

final class HandTracker {
    private let request: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()

    func detect(in pixelBuffer: CVPixelBuffer) -> HandLandmarks? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observation = request.results?.first else { return nil }

        let recognized: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]
        do {
            recognized = try observation.recognizedPoints(.all)
        } catch {
            return nil
        }

        var joints: [VNHumanHandPoseObservation.JointName: HandLandmark] = [:]
        for (name, point) in recognized where point.confidence > 0.25 {
            // Vision is bottom-left. Convert to mirrored top-left so overlay and gestures match the selfie preview.
            let uiPoint = CGPoint(x: 1 - CGFloat(point.location.x), y: 1 - CGFloat(point.location.y))
            joints[name] = HandLandmark(
                id: name.rawValue.rawValue,
                name: name,
                point: uiPoint,
                confidence: point.confidence
            )
        }

        guard joints[.wrist] != nil, joints.count >= 6 else { return nil }
        return HandLandmarks(joints: joints)
    }
}
