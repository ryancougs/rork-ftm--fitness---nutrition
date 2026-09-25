//
//  BarcodeScannerView.swift
//  FTMFitnessNutrition
//

import SwiftUI
import AVFoundation
import UIKit

/// Live camera barcode scanner for the Add Food sheet. Runs the real
/// AVFoundation capture pipeline; shows distinct denied / unavailable states
/// when the camera isn't accessible.
struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onCode: (String) -> Void

    @State private var permission: PermissionState = .checking
    @State private var cameraAvailable: Bool = true

    private enum PermissionState { case checking, granted, denied }

    var body: some View {
        ZStack {
            TF.bg.ignoresSafeArea()
            switch permission {
            case .checking:
                ProgressView().tint(TF.blue)
            case .denied:
                deniedView
            case .granted:
                if cameraAvailable {
                    BarcodeCameraPreview(onCode: handleCode, onUnavailable: { cameraAvailable = false })
                        .ignoresSafeArea()
                    hintOverlay
                } else {
                    unavailableView
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(TF.blue)
            }
        }
        .task { await checkPermission() }
    }

    private var hintOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "viewfinder")
                Text("Point at a product barcode")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(TF.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(TF.card.opacity(0.9)))
            .padding(.bottom, 32)
        }
    }

    private var deniedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(TF.blue.opacity(0.7))
            Text("Camera access is off")
                .font(.headline)
                .foregroundStyle(TF.text)
            Text("Barcode scanning needs the camera. You can turn it on in Settings at any time.")
                .font(.subheadline)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TF.blue)
            .padding(.top, 6)
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(TF.textSecondary)
            Text("No camera available")
                .font(.headline)
                .foregroundStyle(TF.text)
            Text("Barcode scanning needs a camera. Search for the food by name instead.")
                .font(.subheadline)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func handleCode(_ code: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onCode(code)
        dismiss()
    }

    private func checkPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permission = .granted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permission = granted ? .granted : .denied
        default:
            permission = .denied
        }
    }
}

// MARK: - Camera preview

/// UIView hosting the capture preview layer. Session lifecycle runs on a
/// dedicated serial queue; results hop back to the main actor.
private struct BarcodeCameraPreview: UIViewRepresentable {
    let onCode: (String) -> Void
    let onUnavailable: () -> Void

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        view.onCode = onCode
        view.onUnavailable = onUnavailable
        view.start()
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: ScannerPreviewView, coordinator: ()) {
        uiView.stop()
    }
}

private final class ScannerPreviewView: UIView {
    nonisolated(unsafe) var onCode: ((String) -> Void)?
    nonisolated(unsafe) var onUnavailable: (() -> Void)?

    private nonisolated(unsafe) let session = AVCaptureSession()
    private nonisolated(unsafe) let sessionQueue = DispatchQueue(label: "tf.barcode.session")
    private nonisolated(unsafe) var lastCode: String?
    private nonisolated(unsafe) var lastAt: Date = .distantPast

    override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func start() {
        sessionQueue.async { self.configureAndRun() }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func configureAndRun() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        guard let device = discovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            Task { @MainActor in onUnavailable?() }
            return
        }
        session.beginConfiguration()
        session.sessionPreset = .high
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: sessionQueue)
            output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .code39]
        }
        session.commitConfiguration()
        session.startRunning()
    }
}

extension ScannerPreviewView: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
              let value = object.stringValue else { return }
        // Throttle repeated reads of the same code.
        if value == lastCode, Date().timeIntervalSince(lastAt) < 2 { return }
        lastCode = value
        lastAt = Date()
        Task { @MainActor in
            onCode?(value)
        }
    }
}
