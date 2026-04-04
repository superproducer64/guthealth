import SwiftUI
import AVFoundation

// MARK: - Camera Color Scanner View

struct CameraColorScannerView: View {
    @Binding var isPresented: Bool
    var onColorSelected: (Int) -> Void

    @StateObject private var camera = CameraManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.isReady {
                CameraPreviewLayer(session: camera.session)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Color Scanner")
                        .font(.custom("Georgia", size: 20))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { camera.stop(); isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                Spacer()

                // Reticle
                ZStack {
                    Circle()
                        .stroke(camera.reticleColor, lineWidth: 3)
                        .frame(width: 110, height: 110)
                        .shadow(color: .black.opacity(0.3), radius: 20)

                    Circle()
                        .fill(camera.sampledColor)
                        .frame(width: 90, height: 90)
                }
                .animation(.easeInOut(duration: 0.1), value: camera.reticleColor)

                Text("Hold over sample · center in circle")
                    .font(.system(size: 12, design: .monospaced))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.8), radius: 4)
                    .padding(.top, 16)

                Spacer()

                // Result bar
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(camera.matchedColor)
                            .frame(width: 48, height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 2))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Level \(camera.detectedLevel)")
                                .font(.custom("Georgia", size: 28))
                                .foregroundColor(.white)
                            Text(urineColorData[camera.detectedLevel - 1].label)
                                .font(.system(size: 11, design: .monospaced))
                                .tracking(0.3)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        Spacer()
                    }

                    // Mini scale
                    HStack(spacing: 4) {
                        ForEach(urineColorData) { u in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(u.color)
                                .frame(height: u.level == camera.detectedLevel ? 16 : 10)
                                .opacity(u.level == camera.detectedLevel ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 0.15), value: camera.detectedLevel)
                        }
                    }

                    // Action buttons
                    HStack(spacing: 10) {
                        Button("Cancel") {
                            camera.stop()
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .font(.system(size: 12, design: .monospaced))
                        .textCase(.uppercase)
                        .cornerRadius(10)

                        Button("Use This Color") {
                            onColorSelected(camera.detectedLevel)
                            camera.stop()
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(hex: "#2D6A4F"))
                        .foregroundColor(.white)
                        .font(.system(size: 12, design: .monospaced))
                        .textCase(.uppercase)
                        .cornerRadius(10)
                    }
                }
                .padding(20)
                .padding(.bottom, 30)
                .background(.ultraThinMaterial.opacity(0.9))
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}

// MARK: - Camera Manager

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var detectedLevel: Int = 2
    @Published var sampledColor: Color = Color(hex: "#F0E070")
    @Published var matchedColor: Color = Color(hex: "#F0E070")
    @Published var reticleColor: Color = .white
    @Published var isReady = false

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.flowlog.cameraQueue")

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .medium

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true

            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }

            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async { self.isReady = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Frame Processing

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }

        let width  = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)

        let sampleSize = 20
        let cx = width / 2
        let cy = height / 2
        let x0 = max(0, cx - sampleSize / 2)
        let y0 = max(0, cy - sampleSize / 2)

        var r: Double = 0, g: Double = 0, b: Double = 0, count: Double = 0
        for y in y0..<(y0 + sampleSize) {
            for x in x0..<(x0 + sampleSize) {
                let pixel = (baseAddress + y * bytesPerRow).load(fromByteOffset: x * 4, as: UInt32.self)
                b += Double(pixel        & 0xFF)
                g += Double(pixel >> 8  & 0xFF)
                r += Double(pixel >> 16 & 0xFF)
                count += 1
            }
        }
        guard count > 0 else { return }
        r /= count; g /= count; b /= count

        let level = matchUrineColor(r: r, g: g, b: b)
        let ud = urineColorData[level - 1]

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.detectedLevel = level
            self.sampledColor  = Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255)
            self.matchedColor  = ud.color
            self.reticleColor  = level <= 3
                ? Color(.sRGB, red: 0.47, green: 0.86, blue: 0.63)
                : level <= 5
                    ? Color(.sRGB, red: 1.0,  green: 0.78, blue: 0.31)
                    : Color(.sRGB, red: 0.86, green: 0.39, blue: 0.31)
        }
    }

    // MARK: - Color Matching (weighted Euclidean distance in RGB)

    private func matchUrineColor(r: Double, g: Double, b: Double) -> Int {
        let refs: [(Double, Double, Double)] = [
            (245, 240, 192), (240, 224, 112), (232, 200,  48), (212, 160,  32),
            (176, 112,  16), (139,  72,   0), ( 92,  46,   0), ( 58,  24,   0),
        ]
        var bestLevel = 1
        var bestDist  = Double.infinity
        for (i, ref) in refs.enumerated() {
            let dr = r - ref.0, dg = g - ref.1, db = b - ref.2
            let dist = (dr * dr * 0.30) + (dg * dg * 0.59) + (db * db * 0.11)
            if dist < bestDist { bestDist = dist; bestLevel = i + 1 }
        }
        return bestLevel
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.setup(session: session)
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

final class VideoPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    func setup(session: AVCaptureSession) {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
