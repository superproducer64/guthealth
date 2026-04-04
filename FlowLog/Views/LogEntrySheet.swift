import SwiftUI

struct LogEntrySheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState

    @State private var entryType: EntryType = .urine

    // Urine state
    @State private var selectedUrineColor: Int? = nil
    @State private var urineUrgency: Int = 1
    @State private var urineDuration: Double = 1
    @State private var urineSymptoms: Set<String> = []
    @State private var urineNotes: String = ""

    // Bowel state
    @State private var selectedBristol: Int? = nil
    @State private var bowelUrgency: Int = 1
    @State private var bowelDuration: Double = 5
    @State private var bowelSymptoms: Set<String> = ["Felt complete"]
    @State private var bowelNotes: String = ""

    // Camera
    @State private var showingCamera = false

    // Alert
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let urineSymptomOptions = ["Felt complete", "Burning or discomfort", "Cloudy appearance", "Blood noticed"]
    private let bowelSymptomOptions  = ["Felt complete", "Had to strain", "Experienced pain", "Blood noticed"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Type selector
                    HStack(spacing: 8) {
                        TypeButton(icon: "🚿", label: "Urine",  isSelected: entryType == .urine)  { entryType = .urine }
                        TypeButton(icon: "🪺", label: "Bowel",  isSelected: entryType == .bowel)  { entryType = .bowel }
                    }
                    .padding(20)

                    Color.gutBorder.frame(height: 1).padding(.horizontal, 20)

                    if entryType == .urine {
                        urineForm
                    } else {
                        bowelForm
                    }

                    // Submit
                    Button(action: submitEntry) {
                        Text(entryType == .urine ? "Log Urine" : "Log Bowel Movement")
                            .font(.system(size: 12, design: .monospaced))
                            .tracking(0.6)
                            .textCase(.uppercase)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.gutAccent)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.gutBg)
            .navigationTitle("Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.gutAccent)
                        .font(.system(size: 14, design: .monospaced))
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraColorScannerView(isPresented: $showingCamera) { level in
                selectedUrineColor = level
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Urine Form

    private var urineForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            formSection("Urine Color (1 = clear, 8 = dark)") {
                // Camera scan button
                Button(action: { showingCamera = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera")
                            .font(.system(size: 14))
                        Text("Scan with Camera")
                            .font(.system(size: 11, design: .monospaced))
                            .tracking(0.6)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(.gutAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gutSurface)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gutBorder, lineWidth: 1.5))
                    .cornerRadius(8)
                }
                .padding(.bottom, 10)

                // Color swatches
                HStack(spacing: 4) {
                    ForEach(urineColorData) { u in
                        Button(action: { selectedUrineColor = u.level }) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(u.color)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedUrineColor == u.level ? Color.gutText : Color.clear, lineWidth: 2)
                                )
                                .scaleEffect(selectedUrineColor == u.level ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: selectedUrineColor)
                                .frame(height: 36)
                        }
                    }
                }

                // Color indicator
                if let level = selectedUrineColor {
                    let ud = urineColorData[level - 1]
                    HStack(spacing: 10) {
                        Circle()
                            .fill(ud.color)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.gutBorder, lineWidth: 1))
                        Text(ud.label)
                            .font(.system(size: 11, design: .monospaced))
                            .tracking(0.2)
                            .foregroundColor(.gutText)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.gutSurface2)
                    .cornerRadius(8)
                    .padding(.top, 8)
                }
            }

            formDivider()
            formSection("Urgency Level") { urgencyGrid(current: urineUrgency) { urineUrgency = $0 } }
            formDivider()
            formSection("Duration") { durationSlider(value: $urineDuration, label: "urine") }
            formDivider()
            formSection("Symptoms") { symptomsChecklist(options: urineSymptomOptions, selected: $urineSymptoms) }
            formDivider()
            formSection("Notes (optional)") {
                notesField(text: $urineNotes, placeholder: "Foods eaten, medications, observations…")
            }
        }
    }

    // MARK: - Bowel Form

    private var bowelForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            formSection("Bristol Stool Scale — Select Type") {
                VStack(spacing: 6) {
                    ForEach(bristolData) { b in
                        Button(action: { selectedBristol = b.n }) {
                            HStack(spacing: 12) {
                                Text("\(b.n)")
                                    .font(.custom("Georgia", size: 20))
                                    .foregroundColor(.gutAccent)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(b.name)
                                        .font(.system(size: 12, design: .monospaced))
                                        .fontWeight(.medium)
                                        .tracking(0.3)
                                        .foregroundColor(.gutText)
                                    Text(b.desc)
                                        .font(.system(size: 10, design: .monospaced))
                                        .tracking(0.2)
                                        .foregroundColor(.gutMuted)
                                }
                                Spacer()
                                Text(b.visual)
                                    .font(.system(size: 20))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(selectedBristol == b.n ? Color.gutAccentLight : Color.gutSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedBristol == b.n ? Color.gutAccent : Color.gutBorder, lineWidth: 1.5)
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: selectedBristol)
                    }
                }
            }

            formDivider()
            formSection("Urgency Level") { urgencyGrid(current: bowelUrgency) { bowelUrgency = $0 } }
            formDivider()
            formSection("Duration") { durationSlider(value: $bowelDuration, label: "bowel") }
            formDivider()
            formSection("Symptoms") { symptomsChecklist(options: bowelSymptomOptions, selected: $bowelSymptoms) }
            formDivider()
            formSection("Notes (optional)") {
                notesField(text: $bowelNotes, placeholder: "Foods eaten, medications, observations…")
            }
        }
    }

    // MARK: - Shared Form Components

    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, design: .monospaced))
                .tracking(0.8)
                .foregroundColor(.gutMuted)
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func formDivider() -> some View {
        Color.gutBorder.frame(height: 1).padding(.horizontal, 20)
    }

    private func urgencyGrid(current: Int, onSelect: @escaping (Int) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)], spacing: 7) {
            ForEach(1...4, id: \.self) { level in
                Button(action: { onSelect(level) }) {
                    VStack(spacing: 6) {
                        Text(urgencyEmojis[level])
                            .font(.system(size: 22))
                        Text(urgencyLabels[level])
                            .font(.system(size: 11, design: .monospaced))
                            .tracking(0.3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(current == level ? .gutAccent : .gutText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(current == level ? Color.gutAccentLight : Color.gutSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(current == level ? Color.gutAccent : Color.gutBorder, lineWidth: 1.5)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: current)
            }
        }
    }

    private func durationSlider(value: Binding<Double>, label: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text(value.wrappedValue < 1 ? "<1 min" : "\(Int(value.wrappedValue)) min")
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(.gutAccent)
            }
            Slider(value: value, in: 0...30, step: 1)
                .accentColor(.gutAccent)
            HStack {
                ForEach(["<1", "5", "10", "15", "20", "25", "30+"], id: \.self) { tick in
                    Text(tick)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gutMuted)
                    if tick != "30+" { Spacer() }
                }
            }
        }
    }

    private func symptomsChecklist(options: [String], selected: Binding<Set<String>>) -> some View {
        VStack(spacing: 8) {
            ForEach(options, id: \.self) { symptom in
                Button(action: {
                    if selected.wrappedValue.contains(symptom) {
                        selected.wrappedValue.remove(symptom)
                    } else {
                        selected.wrappedValue.insert(symptom)
                    }
                }) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(selected.wrappedValue.contains(symptom) ? Color.gutAccent : Color.gutBorder, lineWidth: 1.5)
                                .frame(width: 20, height: 20)
                            if selected.wrappedValue.contains(symptom) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.gutAccent)
                                    .frame(width: 20, height: 20)
                                Text("✓")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        Text(symptom)
                            .font(.system(size: 12, design: .monospaced))
                            .tracking(0.2)
                            .foregroundColor(.gutText)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func notesField(text: Binding<String>, placeholder: String) -> some View {
        TextEditor(text: text)
            .font(.system(size: 12, design: .monospaced))
            .frame(minHeight: 60)
            .padding(10)
            .background(Color.gutSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gutBorder, lineWidth: 1.5)
            )
            .cornerRadius(8)
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gutMuted.opacity(0.7))
                        .padding(.top, 18)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }
            }
    }

    // MARK: - Submit

    private func submitEntry() {
        let id = Int64(Date().timeIntervalSince1970 * 1000)

        if entryType == .urine {
            guard let color = selectedUrineColor else {
                alertMessage = "Please select a urine color."; showAlert = true; return
            }
            let ud = urineColorData[color - 1]
            appState.submitEntry(Entry(
                id: id, type: .urine, date: appState.todayKey(), time: Date(),
                color: color, colorLabel: ud.label, colorHex: ud.hexColor,
                bristol: nil, bristolName: nil, bristolVisual: nil, healthy: nil,
                urgency: urineUrgency, duration: Int(urineDuration),
                symptoms: Array(urineSymptoms), notes: urineNotes
            ))
        } else {
            guard let bristol = selectedBristol else {
                alertMessage = "Please select a Bristol type."; showAlert = true; return
            }
            let bd = bristolData[bristol - 1]
            appState.submitEntry(Entry(
                id: id, type: .bowel, date: appState.todayKey(), time: Date(),
                color: nil, colorLabel: nil, colorHex: nil,
                bristol: bristol, bristolName: bd.name, bristolVisual: bd.visual, healthy: bd.healthy,
                urgency: bowelUrgency, duration: Int(bowelDuration),
                symptoms: Array(bowelSymptoms), notes: bowelNotes
            ))
        }
        isPresented = false
    }
}

// MARK: - Type Button

private struct TypeButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 24))
                Text(label.uppercased())
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(isSelected ? Color.gutAccentLight : Color.gutSurface)
            .foregroundColor(isSelected ? .gutAccent : .gutText)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.gutAccent : Color.gutBorder, lineWidth: 2)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
