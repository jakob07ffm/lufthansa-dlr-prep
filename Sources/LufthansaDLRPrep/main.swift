import SwiftUI

@main
struct LufthansaDLRPrepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowResizability(.contentSize)
    }
}

enum TrainingModule: String, CaseIterable, Identifiable {
    case speed = "Geschwindigkeit"
    case mathematics = "Mathematik"
    case memory = "Merkfähigkeit"
    case concentration = "Konzentration"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .speed: "gauge.with.dots.needle.67percent"
        case .mathematics: "function"
        case .memory: "brain.head.profile"
        case .concentration: "scope"
        }
    }

    var summary: String {
        switch self {
        case .speed: "Reaktionszeit und visuelle Verarbeitung"
        case .mathematics: "Kopfrechnen unter Zeitdruck"
        case .memory: "Zahlen- und Musterfolgen merken"
        case .concentration: "Aufmerksamkeits- und Genauigkeitstraining"
        }
    }
}

struct ContentView: View {
    @AppStorage("selectedModule") private var selectedModule = TrainingModule.speed.rawValue
    @AppStorage("sessionDuration") private var sessionDuration = 5.0
    @AppStorage("difficulty") private var difficulty = 3.0
    @AppStorage("stimulusSpeed") private var stimulusSpeed = 1.0
    @State private var showingTraining = false

    private var module: TrainingModule {
        TrainingModule(rawValue: selectedModule) ?? .speed
    }

    var body: some View {
        NavigationSplitView {
            List(TrainingModule.allCases, selection: $selectedModule) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item.rawValue)
            }
            .navigationTitle("DLR Vorbereitung")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Lokale Einstellungen", systemImage: "checkmark.shield")
                        .font(.caption.weight(.semibold))
                    Text("Deine Trainingswerte werden nur auf diesem Mac gespeichert.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        } detail: {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(module: module)
                SettingsCard(
                    sessionDuration: $sessionDuration,
                    difficulty: $difficulty,
                    stimulusSpeed: $stimulusSpeed
                )
                Spacer()
                HStack {
                    Text("Bereit für eine Übungseinheit?")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Training starten", systemImage: "play.fill") {
                        showingTraining = true
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                }
            }
            .padding(32)
            .sheet(isPresented: $showingTraining) {
                TrainingView(
                    module: module,
                    duration: Int(sessionDuration * 60),
                    difficulty: Int(difficulty),
                    stimulusSpeed: stimulusSpeed
                )
            }
        }
    }
}

struct HeaderView: View {
    let module: TrainingModule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(module.rawValue, systemImage: module.icon)
                .font(.largeTitle.bold())
            Text(module.summary)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Passe die Parameter an dein aktuelles Trainingsniveau an.")
                .font(.body)
        }
    }
}

struct SettingsCard: View {
    @Binding var sessionDuration: Double
    @Binding var difficulty: Double
    @Binding var stimulusSpeed: Double

    var body: some View {
        GroupBox("Trainingsparameter") {
            VStack(spacing: 18) {
                ParameterRow(
                    title: "Dauer",
                    value: "\(Int(sessionDuration)) Min.",
                    help: "Gesamtdauer der Übungseinheit"
                ) {
                    Slider(value: $sessionDuration, in: 1...30, step: 1)
                }
                ParameterRow(
                    title: "Schwierigkeit",
                    value: difficultyLabel,
                    help: "Anzahl und Komplexität der Aufgaben"
                ) {
                    Slider(value: $difficulty, in: 1...5, step: 1)
                }
                ParameterRow(
                    title: "Reizgeschwindigkeit",
                    value: String(format: "%.1f s", stimulusSpeed),
                    help: "Zeit zwischen zwei Reizen"
                ) {
                    Slider(value: $stimulusSpeed, in: 0.3...3.0, step: 0.1)
                }
            }
            .padding(8)
        }
    }

    private var difficultyLabel: String {
        switch Int(difficulty) {
        case 1: "Einfach"
        case 2: "Leicht"
        case 3: "Mittel"
        case 4: "Schwer"
        default: "Sehr schwer"
        }
    }
}

struct ParameterRow<Control: View>: View {
    let title: String
    let value: String
    let help: String
    @ViewBuilder let control: Control

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).fontWeight(.semibold)
                Spacer()
                Text(value).monospacedDigit().foregroundStyle(.secondary)
            }
            control
            Text(help).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct TrainingView: View {
    let module: TrainingModule
    let duration: Int
    let difficulty: Int
    let stimulusSpeed: Double
    @Environment(\.dismiss) private var dismiss
    @State private var remaining: Int
    @State private var score = 0
    @State private var isRunning = false
    @State private var prompt = "Drücke Start, wenn du bereit bist."
    @State private var timer: Timer?

    init(module: TrainingModule, duration: Int, difficulty: Int, stimulusSpeed: Double) {
        self.module = module
        self.duration = duration
        self.difficulty = difficulty
        self.stimulusSpeed = stimulusSpeed
        _remaining = State(initialValue: duration)
    }

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Label(module.rawValue, systemImage: module.icon)
                    .font(.title2.bold())
                Spacer()
                Text(timeString(remaining))
                    .font(.title2.monospacedDigit())
            }
            .padding(.horizontal, 28)
            Divider()
            VStack(spacing: 18) {
                Text(prompt)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620, minHeight: 140)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
                Text("Punkte: \(score)")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack {
                Button("Beenden") { stop() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill") {
                    isRunning ? pause() : start()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 28)
        }
        .padding(.vertical, 28)
        .frame(minWidth: 720, minHeight: 480)
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        isRunning = true
        nextPrompt()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard remaining > 0 else {
                stop()
                return
            }
            remaining -= 1
        }
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        prompt = "Pausiert – drücke Start zum Fortsetzen."
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        dismiss()
    }

    private func nextPrompt() {
        switch module {
        case .speed:
            prompt = "Reagiere so schnell wie möglich auf den nächsten Reiz."
        case .mathematics:
            prompt = "\(Int.random(in: 12...48)) × \(Int.random(in: 2...9)) = ?"
        case .memory:
            prompt = (0..<(difficulty + 3)).map { _ in String(Int.random(in: 0...9)) }.joined(separator: "  ")
        case .concentration:
            prompt = "Finde das abweichende Symbol:  ● ● ● ○ ● ●"
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
