//
//  CheckInView.swift
//  FTMFitnessNutrition
//

import SwiftUI
import PhotosUI
import Charts
import UIKit

/// Standalone weekly check-in screen, opened from the Home prompt card:
/// wellbeing ratings, workout adherence, progress feeling, open notes,
/// mandatory front-on progress photo (side/back/pose optional), score and
/// lifting-volume trends, and history. Mason reads these every week.
struct CheckInScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    CheckInContent()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TF.blue)
                }
            }
        }
    }
}

/// Check-in content shared by the standalone screen: form, summary, trends,
/// and history.
struct CheckInContent: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 18) {
            headerCard
            if let existing = app.currentWeekCheckIn(), !showingEdit {
                summaryCard(existing)
                editButton
            } else {
                checkInForm
            }
            trendsSection
            historySection
        }
    }

    // MARK: Header

    private var headerCard: some View {
        TFHeroBanner {
            VStack(alignment: .leading, spacing: 6) {
                Label("Submit your weekly check-in", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.title2.weight(.bold))
                Text("A quick weekly check-in. Not about numbers — about how you feel. Take a minute for yourself.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: Summary (if already checked in)

    @ViewBuilder
    private func summaryCard(_ checkIn: WeeklyCheckIn) -> some View {
        TFCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(TF.blue)
                    Text("This week's check-in")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Spacer()
                    Text(checkIn.progressFeeling.emoji)
                        .font(.title2)
                }
                if let data = checkIn.frontPhoto {
                    HStack(spacing: 10) {
                        photoThumb(data: data)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Front-on photo saved")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TF.blue)
                            Text("Only you can see these.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                ratingSummary(checkIn)
                Divider()
                adherenceRow(checkIn)
                feelingRow(checkIn)
                if !checkIn.notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your notes")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(checkIn.notes)
                            .font(.subheadline)
                            .foregroundStyle(TF.text)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ratingSummary(_ checkIn: WeeklyCheckIn) -> some View {
        VStack(spacing: 8) {
            ratingBadge("Energy", value: checkIn.energy, color: TF.blue)
            ratingBadge("Sleep", value: checkIn.sleep, color: TF.blue)
            ratingBadge("Stress", value: checkIn.stress, color: TF.pink)
            ratingBadge("Hunger", value: checkIn.hunger, color: TF.hunger)
        }
    }

    @ViewBuilder
    private func ratingBadge(_ label: String, value: Int, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TF.text)
            Spacer()
            HStack(spacing: 2) {
                ForEach(1...10, id: \.self) { i in
                    Circle()
                        .fill(i <= value ? color : color.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
            Text("\(value)/10")
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 36, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func adherenceRow(_ checkIn: WeeklyCheckIn) -> some View {
        HStack {
            Text("Workouts")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TF.text)
            Spacer()
            Text("\(checkIn.workoutAdherence.emoji) \(checkIn.workoutAdherence.rawValue)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TF.blue)
        }
    }

    @ViewBuilder
    private func feelingRow(_ checkIn: WeeklyCheckIn) -> some View {
        HStack {
            Text("Progress feeling")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TF.text)
            Spacer()
            Text("\(checkIn.progressFeeling.emoji) \(checkIn.progressFeeling.rawValue)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TF.text)
        }
    }

    private var editButton: some View {
        TFButton(title: "Update this week's check-in", systemImage: "pencil", style: .secondary) {
            showingEdit = true
        }
    }

    // MARK: Check-in form

    @State private var energy: Int = 5
    @State private var sleep: Int = 5
    @State private var stress: Int = 5
    @State private var hunger: Int = 5
    @State private var adherence: WorkoutAdherence = .some
    @State private var feeling: ProgressFeeling = .good
    @State private var notes: String = ""
    @State private var showingEdit: Bool = false
    @State private var hasLoadedExisting: Bool = false

    // Progress photos: front-on is mandatory, the rest are optional.
    @State private var frontPhoto: Data? = nil
    @State private var sidePhoto: Data? = nil
    @State private var backPhoto: Data? = nil
    @State private var posePhoto: Data? = nil
    @State private var frontItem: PhotosPickerItem? = nil
    @State private var sideItem: PhotosPickerItem? = nil
    @State private var backItem: PhotosPickerItem? = nil
    @State private var poseItem: PhotosPickerItem? = nil

    @ViewBuilder
    private var checkInForm: some View {
        TFCard {
            VStack(spacing: 18) {
                RatingPicker(label: "Energy", subtitle: "1 = exhausted, 10 = energized", value: $energy, color: TF.blue)
                RatingPicker(label: "Sleep", subtitle: "1 = terrible, 10 = great", value: $sleep, color: TF.blue)
                RatingPicker(label: "Stress", subtitle: "1 = calm, 10 = very stressed", value: $stress, color: TF.pink)
                RatingPicker(label: "Hunger", subtitle: "1 = not hungry, 10 = very hungry", value: $hunger, color: TF.hunger)

                Divider()

                // Workout adherence
                VStack(alignment: .leading, spacing: 8) {
                    Text("Did you hit your workouts this week?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                    HStack(spacing: 8) {
                        ForEach(WorkoutAdherence.allCases) { a in
                            Button {
                                withAnimation(.spring(response: 0.3)) { adherence = a }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(a.emoji).font(.title3)
                                    Text(a.rawValue)
                                        .font(.caption2.weight(.semibold))
                                }
                                .foregroundStyle(adherence == a ? .white : TF.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background {
                                    if adherence == a {
                                        RoundedRectangle(cornerRadius: 10).fill(TF.blue)
                                    } else {
                                        RoundedRectangle(cornerRadius: 10).fill(TF.input)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()

                // Progress feeling
                VStack(alignment: .leading, spacing: 8) {
                    Text("How are you feeling about your progress?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                    VStack(spacing: 8) {
                        ForEach(ProgressFeeling.allCases) { f in
                            Button {
                                withAnimation(.spring(response: 0.3)) { feeling = f }
                            } label: {
                                HStack(spacing: 10) {
                                    Text(f.emoji)
                                    Text(f.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    if feeling == f {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(TF.blue)
                                    }
                                }
                                .foregroundStyle(feeling == f ? TF.blue : TF.text)
                                .padding(12)
                                .background {
                                    if feeling == f {
                                        RoundedRectangle(cornerRadius: 10).fill(TF.blue.opacity(0.16))
                                    } else {
                                        RoundedRectangle(cornerRadius: 10).fill(TF.input)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()

                // Progress photos
                VStack(alignment: .leading, spacing: 10) {
                    Text("Progress photos")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                    Text("A front-on photo is required so we can track your physique over time — no face needed. Side, back, and a favorite pose are optional. These stay on your device and are only visible to you.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        photoSlot(title: "Front", required: true, data: frontPhoto, item: $frontItem)
                        photoSlot(title: "Side", required: false, data: sidePhoto, item: $sideItem)
                        photoSlot(title: "Back", required: false, data: backPhoto, item: $backItem)
                        photoSlot(title: "Pose", required: false, data: posePhoto, item: $poseItem)
                    }
                }

                Divider()

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Anything you want Mason to know this week?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                    TextEditor(text: $notes)
                        .foregroundStyle(TF.text)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
                        .overlay(
                            RoundedRectangle(cornerRadius: TF.cornerS)
                                .stroke(TF.border, lineWidth: 0.5)
                        )
                }

                TFButton(
                    title: frontPhoto == nil ? "Add your front-on photo to save" : "Save check-in",
                    systemImage: frontPhoto == nil ? "camera.fill" : "checkmark",
                    style: .primary,
                    disabled: frontPhoto == nil
                ) {
                    let checkIn = WeeklyCheckIn(
                        weekStart: app.currentWeekStart,
                        energy: energy, sleep: sleep, stress: stress, hunger: hunger,
                        workoutAdherence: adherence, progressFeeling: feeling,
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                        frontPhoto: frontPhoto, sidePhoto: sidePhoto,
                        backPhoto: backPhoto, posePhoto: posePhoto
                    )
                    app.saveCheckIn(checkIn)
                    showingEdit = false
                }
            }
        }
        .onAppear {
            if !hasLoadedExisting, let existing = app.currentWeekCheckIn() {
                energy = existing.energy
                sleep = existing.sleep
                stress = existing.stress
                hunger = existing.hunger
                adherence = existing.workoutAdherence
                feeling = existing.progressFeeling
                notes = existing.notes
                frontPhoto = existing.frontPhoto
                sidePhoto = existing.sidePhoto
                backPhoto = existing.backPhoto
                posePhoto = existing.posePhoto
            }
            hasLoadedExisting = true
        }
        .onChange(of: frontItem) { _, newValue in
            loadPhoto(newValue) { frontPhoto = $0 }
        }
        .onChange(of: sideItem) { _, newValue in
            loadPhoto(newValue) { sidePhoto = $0 }
        }
        .onChange(of: backItem) { _, newValue in
            loadPhoto(newValue) { backPhoto = $0 }
        }
        .onChange(of: poseItem) { _, newValue in
            loadPhoto(newValue) { posePhoto = $0 }
        }
    }

    // MARK: Photo slots

    private func photoSlot(title: String, required: Bool, data: Data?, item: Binding<PhotosPickerItem?>) -> some View {
        VStack(spacing: 6) {
            if let data, let image = UIImage(data: data) {
                PhotosPicker(selection: item, matching: .images) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay {
                            ZStack(alignment: .bottom) {
                                Rectangle().fill(.black.opacity(0.35)).frame(height: 20)
                                Text("Retake")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            } else {
                PhotosPicker(selection: item, matching: .images) {
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.headline)
                        Text(title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(TF.blue)
                    .frame(width: 72, height: 72)
                    .background(RoundedRectangle(cornerRadius: 12).fill(TF.input))
                }
                .buttonStyle(.plain)
            }
            Text(required ? "Required" : "Optional")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(required ? TF.pink : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadPhoto(_ item: PhotosPickerItem?, assign: @escaping (Data?) -> Void) {
        guard let item else { return }
        Task {
            if let data = await Self.imageData(from: item) {
                assign(data)
            }
        }
    }

    /// Downscales the picked image and compresses it so weekly photos stay small.
    private static func imageData(from item: PhotosPickerItem) async -> Data? {
        guard let raw = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: raw) else { return nil }
        let maxSide: CGFloat = 900
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let rendered = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.jpegData(compressionQuality: 0.55)
    }

    private func photoThumb(data: Data) -> some View {
        Group {
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(TF.input)
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(.rect(cornerRadius: 10))
    }

    // MARK: Trends

    private struct WeekScore {
        let week: Date
        let score: Double
    }

    /// Wellbeing score per week: energy + sleep + low stress + low hunger,
    /// normalized to 0-100.
    private var weekScores: [WeekScore] {
        var scores: [WeekScore] = []
        for checkIn in app.sortedCheckIns.reversed() {
            let raw = Double(checkIn.energy + checkIn.sleep + (10 - checkIn.stress) + (10 - checkIn.hunger))
            scores.append(WeekScore(week: checkIn.weekStart, score: raw / 40 * 100))
        }
        return scores
    }

    @ViewBuilder
    private var trendsSection: some View {
        let scores = weekScores
        if scores.count >= 2 {
            TFSectionHeader(title: "Trends", subtitle: "How you've been tracking week to week")
                .padding(.top, 8)
            TFCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Wellbeing score")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Chart(scores, id: \.week) {
                        LineMark(
                            x: .value("Week", $0.week),
                            y: .value("Score", $0.score)
                        )
                        .foregroundStyle(TF.blue)
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Week", $0.week),
                            y: .value("Score", $0.score)
                        )
                        .foregroundStyle(TF.blue)
                    }
                    .chartYScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .weekOfYear)) {
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .font(.caption2)
                        }
                    }
                    .frame(height: 150)
                }
            }

            let volume = app.weeklyLiftingVolume()
            if volume.contains(where: { $0.volume > 0 }) {
                TFCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lifting volume")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(TF.text)
                        Chart(volume, id: \.week) {
                            BarMark(
                                x: .value("Week", $0.week, unit: .weekOfYear),
                                y: .value("Volume", $0.volume)
                            )
                            .foregroundStyle(TF.blue.opacity(0.75))
                            .cornerRadius(3)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .weekOfYear)) {
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    .font(.caption2)
                            }
                        }
                        .frame(height: 140)
                        Text("Total weight × reps logged each week.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: History

    @ViewBuilder
    private var historySection: some View {
        let past = app.sortedCheckIns.filter { !$0.weekStart.isSameDay(as: app.currentWeekStart) }
        if !past.isEmpty {
            TFSectionHeader(title: "History", subtitle: "\(past.count) past check-in\(past.count == 1 ? "" : "s")")
                .padding(.top, 8)
            ForEach(past) { checkIn in
                historyCard(checkIn)
            }
        }
    }

    @ViewBuilder
    private func historyCard(_ checkIn: WeeklyCheckIn) -> some View {
        let dateString = checkIn.weekStart.formatted(date: .abbreviated, time: .omitted)
        TFCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(dateString)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Spacer()
                    if checkIn.frontPhoto != nil {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundStyle(TF.blue)
                    }
                    Text(checkIn.progressFeeling.emoji)
                        .font(.title3)
                }
                HStack(spacing: 12) {
                    miniRating("E", checkIn.energy, TF.blue)
                    miniRating("S", checkIn.sleep, TF.blue)
                    miniRating("St", checkIn.stress, TF.pink)
                    miniRating("H", checkIn.hunger, TF.hunger)
                }
                HStack {
                    Label(checkIn.workoutAdherence.rawValue, systemImage: "dumbbell")
                    Spacer()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                if !checkIn.notes.isEmpty {
                    Text(checkIn.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    @ViewBuilder
    private func miniRating(_ label: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Rating picker (1-10 tappable dots)

struct RatingPicker: View {
    let label: String
    var subtitle: String? = nil
    @Binding var value: Int
    var color: Color = TF.blue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TF.text)
                Spacer()
                Text("\(value)/10")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 5) {
                ForEach(1...10, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { value = i }
                    } label: {
                        Circle()
                            .fill(i <= value ? color : TF.input)
                            .overlay {
                                if i <= value {
                                    Circle().stroke(.white.opacity(0.3), lineWidth: 1)
                                }
                            }
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    CheckInScreen()
        .environment(AppModel())
}
