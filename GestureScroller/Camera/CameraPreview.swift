import SwiftUI
import Vision

struct CameraPreview: View {
    let frame: CGImage?
    let landmarks: HandLandmarks?

    var body: some View {
        ZStack {
            Color.black
            if let frame {
                Image(frame, scale: 1, orientation: .up, label: Text("Camera"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay {
                        LandmarkOverlay(landmarks: landmarks)
                    }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Camera is off")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct LandmarkOverlay: View {
    let landmarks: HandLandmarks?

    var body: some View {
        Canvas { context, size in
            guard let landmarks else { return }

            var mapped: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
            for (key, value) in landmarks.joints {
                mapped[key] = CGPoint(x: value.point.x * size.width, y: value.point.y * size.height)
            }

            var bonePath = Path()
            for (a, b) in HandLandmarks.bonePairs {
                guard let p1 = mapped[a], let p2 = mapped[b] else { continue }
                bonePath.move(to: p1)
                bonePath.addLine(to: p2)
            }
            context.stroke(bonePath, with: .color(.green.opacity(0.9)), lineWidth: 2)

            for point in mapped.values {
                let rect = CGRect(x: point.x - 3.5, y: point.y - 3.5, width: 7, height: 7)
                context.fill(Path(ellipseIn: rect), with: .color(.green))
            }
        }
        .allowsHitTesting(false)
    }
}
