//
//  MealScannerView.swift
//  FTMFitnessNutrition
//

import SwiftUI
import AVFoundation
import UIKit

/// AI meal scanner: capture a photo of a plate, review estimated foods with
/// calories/macros, and log them to a chosen meal. Runs the real AVFoundation
/// capture pipeline (no simulator fakes) and consumes one free scan per
/// analysis — when the weekly allotment is gone, the paywall opens in context.
struct MealScannerView: View {
    var onLog: ([FoodItem], MealType) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreService.self) private var store

    private enum Phase {
        case checkingPermission
        case camera
        case denied
        case unavailable
        case analyzing
        case limitReached
        case results([MealScanService.ScannedFood])
        case failed(String)
    }

    @State private var phase: Phase = .checkingPermission
    @State private var meal: MealType = .lunch
    @State private var captureTrigger: Int = 0

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .checkingPermission: checkingView
                case .camera: cameraView
                case .denied: deniedView
                case .unavailable: unavailableView
                case .analyzing: analyzingView
                case .limitReached: limitView
                case .results(let foods): resultsView(foods)
                case .failed(let message): failedView(message)
                }
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Scan a meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TF.blue)
                }
            }
        }
        .task { await checkPermission() }
    }

    // MARK: Camera

    private var cameraView: some View {
        ZStack {
            MealCameraPreview(
                captureTrigger: captureTrigger,
                onPhoto: handleCapturedPhoto,
                onUnavailable: { phase = .unavailable }
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                VStack(spacing: 14) {
                    Text("Fit the whole plate in frame")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                    captureButton
                }
                .padding(.bottom, 28)
            }
        }
    }

    private var captureButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            captureTrigger += 1
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 4)
                    .frame(width: 74, height: 74)
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
                Image(systemName: "camera.fill")
                    .font(.title3)
                    .foregroundStyle(TF.bg)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Take photo")
    }

    // MARK: States

    private var checkingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(TF.blue)
            Text("Checking camera…")
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var analyzingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(TF.blue)
                .scaleEffect(1.3)
            Text("Reading your plate…")
                .font(.headline.weight(.bold))
                .foregroundStyle(TF.text)
            Text("This usually takes a few seconds.")
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var deniedView: some View {
        stateView(
            icon: "lock.fill",
            title: "Camera access needed",
            message: "Scanning a meal needs the camera. You can turn it on in Settings at any time."
        ) {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(TF.blue)
        }
    }

    private var unavailableView: some View {
        stateView(
            icon: "camera.on.rectangle",
            title: "No camera available",
            message: "This device has no camera. Search for the food by name instead."
        ) {}
    }

    private var limitView: some View {
        ScrollView {
            LockedFeatureCard(
                icon: "camera.viewfinder",
                title: "Free scans used this week",
                message: "You've used your 3 free scans for this week. Go unlimited with Premium — your next scan is waiting.",
                buttonTitle: "Go unlimited",
                context: .scanLimit
            )
            .padding(16)
        }
    }

    private func failedView(_ message: String) -> some View {
        stateView(
            icon: "exclamationmark.triangle.fill",
            title: "Scan didn't work",
            message: message
        ) {
            TFButton(title: "Try again", systemImage: "arrow.clockwise", style: .primary) {
                phase = .camera
            }
        }
    }

    @ViewBuilder
    private func stateView<Actions: View>(icon: String, title: String, message: String,
                                           @ViewBuilder actions: () -> Actions) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(TF.blue)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(TF.text)
            Text(message)
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            actions()
                .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Results

    private func resultsView(_ foods: [MealScanService.ScannedFood]) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard(foods)
                VStack(spacing: 8) {
                    ForEach(foods) { food in
                        scannedRow(food)
                    }
                }
                mealPicker
                if !foods.isEmpty {
                    TFButton(
                        title: "Log \(foods.count) item\(foods.count == 1 ? "" : "s")",
                        systemImage: "plus.circle.fill",
                        style: .primary
                    ) {
                        log(foods)
                    }
                }
                Button {
                    phase = .camera
                } label: {
                    Label("Retake photo", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.blue)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private func summaryCard(_ foods: [MealScanService.ScannedFood]) -> some View {
        let cal = foods.reduce(0) { $0 + $1.calories }
        let pro = foods.reduce(0) { $0 + $1.protein }
        let carb = foods.reduce(0) { $0 + $1.carbs }
        let fat = foods.reduce(0) { $0 + $1.fat }
        return TFCard {
            VStack(spacing: 10) {
                Text("Estimated totals")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TF.textSecondary)
                HStack(spacing: 16) {
                    bigStat("\(Int(cal.rounded()))", "kcal", TF.blue)
                    bigStat("\(Int(pro.rounded()))", "P g", TF.protein)
                    bigStat("\(Int(carb.rounded()))", "C g", TF.carbs)
                    bigStat("\(Int(fat.rounded()))", "F g", TF.fat)
                }
                Text("AI estimates — tap − to remove anything it got wrong.")
                    .font(.caption2)
                    .foregroundStyle(TF.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func scannedRow(_ food: MealScanService.ScannedFood) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TF.blue.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: "fork.knife")
                    .foregroundStyle(TF.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TF.text)
                HStack(spacing: 8) {
                    Text("\(Int(food.calories.rounded())) kcal")
                    Text("P \(Int(food.protein.rounded()))g")
                    Text("C \(Int(food.carbs.rounded()))g")
                    Text("F \(Int(food.fat.rounded()))g")
                }
                .font(.caption)
                .foregroundStyle(TF.textSecondary)
            }
            Spacer()
            Button {
                removeFood(food)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(TF.danger.opacity(0.7))
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
        .overlay(
            RoundedRectangle(cornerRadius: TF.cornerM)
                .strokeBorder(TF.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func bigStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TF.textSecondary)
        }
    }

    private var mealPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log to")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TF.text)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MealType.allCases) { m in
                        Button {
                            withAnimation(.spring(response: 0.3)) { meal = m }
                        } label: {
                            HStack(spacing: 6) {
                                Text(m.emoji)
                                Text(m.rawValue)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(meal == m ? TF.bg : TF.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(meal == m ? TF.blue : TF.input))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Flow

    private func checkPermission() async {
        // Free users with no scans left see the upgrade card right away
        // instead of after taking a photo.
        if !store.isPremium, await MealScanService.shared.remainingScans() == 0 {
            phase = .limitReached
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            phase = .camera
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            phase = granted ? .camera : .denied
        default:
            phase = .denied
        }
    }

    private func handleCapturedPhoto(_ data: Data?) {
        guard let data else {
            phase = .failed("Couldn't take that photo. Try again.")
            return
        }
        phase = .analyzing
        Task {
            guard let image = UIImage(data: data) else {
                phase = .failed("Couldn't read that photo. Try again.")
                return
            }
            let scaled = image.resized(maxDimension: 1024)
            guard let jpeg = scaled.jpegData(compressionQuality: 0.6) else {
                phase = .failed("Couldn't process that photo. Try again.")
                return
            }
            do {
                // The server consumes (and refunds on failure) the free scan.
                let foods = try await MealScanService.shared.scan(imageData: jpeg)
                phase = .results(foods)
            } catch MealScanService.MealScanError.limitReached {
                phase = .limitReached
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private func removeFood(_ food: MealScanService.ScannedFood) {
        guard case .results(var foods) = phase else { return }
        foods.removeAll { $0.id == food.id }
        if foods.isEmpty {
            phase = .camera
        } else {
            withAnimation(.easeOut(duration: 0.15)) { phase = .results(foods) }
        }
    }

    private func log(_ foods: [MealScanService.ScannedFood]) {
        onLog(foods.map(Self.foodItem), meal)
        dismiss()
    }

    nonisolated private static func foodItem(from scanned: MealScanService.ScannedFood) -> FoodItem {
        FoodItem(
            name: scanned.name,
            serving: "1 portion (est.)",
            calories: Int(scanned.calories.rounded()),
            protein: Int(scanned.protein.rounded()),
            carbs: Int(scanned.carbs.rounded()),
            fat: Int(scanned.fat.rounded()),
            source: .aiScan
        )
    }
}

// MARK: - Camera preview

private struct MealCameraPreview: UIViewRepresentable {
    let captureTrigger: Int
    let onPhoto: (Data?) -> Void
    let onUnavailable: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(lastTrigger: captureTrigger) }

    final class Coordinator {
        var lastTrigger: Int
        init(lastTrigger: Int) { self.lastTrigger = lastTrigger }
    }

    func makeUIView(context: Context) -> MealPreviewView {
        let view = MealPreviewView()
        view.configure(onPhoto: onPhoto, onUnavailable: onUnavailable)
        return view
    }

    func updateUIView(_ uiView: MealPreviewView, context: Context) {
        if captureTrigger != context.coordinator.lastTrigger {
            context.coordinator.lastTrigger = captureTrigger
            uiView.capturePhoto()
        }
    }

    static func dismantleUIView(_ uiView: MealPreviewView, coordinator: Coordinator) {
        uiView.stopSession()
    }
}

final class MealPreviewView: UIView {
    private nonisolated(unsafe) let session = AVCaptureSession()
    private nonisolated(unsafe) let photoOutput = AVCapturePhotoOutput()
    private nonisolated(unsafe) let sessionQueue = DispatchQueue(label: "tf.mealscan.session")
    private nonisolated(unsafe) var onPhoto: ((Data?) -> Void)?
    private nonisolated(unsafe) var onUnavailable: (() -> Void)?

    override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    func configure(onPhoto: @escaping (Data?) -> Void, onUnavailable: @escaping () -> Void) {
        self.onPhoto = onPhoto
        self.onUnavailable = onUnavailable
        backgroundColor = .black
        // Without this the preview layer has nothing to draw and stays black.
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        sessionQueue.async { self.setupSession() }
    }

    private nonisolated func setupSession() {
        guard let device = Self.bestCamera(),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            Task { @MainActor in
                onUnavailable?()
            }
            return
        }
        session.beginConfiguration()
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        session.addInput(input)
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
        session.startRunning()
    }

    /// Back camera on a real iPhone; falls back to any camera (front, or the
    /// external webcam the Rork preview injects) when there is no back one.
    private nonisolated static func bestCamera() -> AVCaptureDevice? {
        if let back = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return back
        }
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        return discovery.devices.first
    }

    func capturePhoto() {
        sessionQueue.async {
            // Capturing before the session is live throws an Objective-C
            // exception (crash), so report a soft failure instead.
            guard self.session.isRunning,
                  let connection = self.photoOutput.connection(with: .video),
                  connection.isEnabled, connection.isActive else {
                Task { @MainActor in self.onPhoto?(nil) }
                return
            }
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

extension MealPreviewView: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: (any Error)?) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        Task { @MainActor in
            onPhoto?(data)
        }
    }
}

private extension UIImage {
    /// Downscales for upload — keeps payloads fast without losing detail.
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        // Render at 1x. The default format uses the screen scale (3x on most
        // iPhones), which turned the 1024 px target into a ~3000 px image and
        // pushed some uploads past the scan server's size limit.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
