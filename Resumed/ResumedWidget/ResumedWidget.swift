//
//  ResumedWidget.swift
//  ResumedWidget
//
//  iOS Widget Extension - Home Screen Widgets
//
//  SETUP: Add new Widget Extension target in Xcode:
//  File > New > Target > Widget Extension
//  Name: ResumedWidget
//  Include Configuration Intent: Yes
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct ResumedEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let dailyGoal: Int
    let dailyProgress: Int
    let pendingCards: Int
    let quote: String
    let accuracy: Int
    let level: Int
    let xpProgress: Double
}

// MARK: - Timeline Provider

struct ResumedProvider: TimelineProvider {
    func placeholder(in context: Context) -> ResumedEntry {
        ResumedEntry(
            date: Date(),
            streak: 7,
            dailyGoal: 20,
            dailyProgress: 12,
            pendingCards: 5,
            quote: "A persistência é o caminho do êxito.",
            accuracy: 78,
            level: 12,
            xpProgress: 0.62
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ResumedEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ResumedEntry>) -> Void) {
        let entry = loadEntry()

        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func loadEntry() -> ResumedEntry {
        // Load from App Group shared UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.resumed.app") ?? .standard

        return ResumedEntry(
            date: Date(),
            streak: defaults.integer(forKey: "widget_streak"),
            dailyGoal: defaults.integer(forKey: "widget_dailyGoal") == 0 ? 20 : defaults.integer(forKey: "widget_dailyGoal"),
            dailyProgress: defaults.integer(forKey: "widget_dailyProgress"),
            pendingCards: defaults.integer(forKey: "widget_pendingCards"),
            quote: defaults.string(forKey: "widget_quote") ?? "Sua aprovação começa hoje!",
            accuracy: defaults.integer(forKey: "widget_accuracy"),
            level: defaults.integer(forKey: "widget_level") == 0 ? 1 : defaults.integer(forKey: "widget_level"),
            xpProgress: defaults.double(forKey: "widget_xpProgress")
        )
    }
}

// MARK: - Small Widget View (Streak Focus)

struct SmallWidgetView: View {
    let entry: ResumedEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.black)

            VStack(spacing: 8) {
                // Logo
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "FFD700"))

                    Text("RESUMED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "FFD700"))

                    Spacer()
                }

                Spacer()

                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)

                    Text("\(entry.streak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("dias de streak")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                Spacer()

                // Daily Progress
                ProgressView(value: entry.dailyGoal > 0 ? Double(entry.dailyProgress) / Double(entry.dailyGoal) : 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "FFD700")))

                Text("\(entry.dailyProgress)/\(entry.dailyGoal) questões")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Widget View (Stats Overview)

struct MediumWidgetView: View {
    let entry: ResumedEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.black)

            HStack(spacing: 16) {
                // Left: Streak & Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "FFD700"))

                        Text("RESUMED")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "FFD700"))
                    }

                    Spacer()

                    // Streak
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(entry.streak)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("dias")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    // Daily Progress
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meta diária")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)

                        ProgressView(value: entry.dailyGoal > 0 ? Double(entry.dailyProgress) / Double(entry.dailyGoal) : 0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "FFD700")))

                        Text("\(entry.dailyProgress)/\(entry.dailyGoal)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)

                // Right: Stats Grid
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        StatBlock(icon: "rectangle.stack.fill", value: "\(entry.pendingCards)", label: "Cards", color: .blue)
                        StatBlock(icon: "chart.bar.fill", value: "\(entry.accuracy)%", label: "Acurácia", color: .green)
                    }

                    HStack(spacing: 16) {
                        StatBlock(icon: "star.fill", value: "Lv.\(entry.level)", label: "Nível", color: Color(hex: "FFD700"))
                        LevelProgressBlock(progress: entry.xpProgress)
                    }
                }
            }
            .padding(14)
        }
    }
}

struct StatBlock: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LevelProgressBlock: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: "FFD700"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("XP")
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Large Widget View (Full Dashboard)

struct LargeWidgetView: View {
    let entry: ResumedEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.black)

            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "FFD700"))

                    Text("RESUMED")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "FFD700"))

                    Spacer()

                    Text("Level \(entry.level)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "FFD700"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "FFD700").opacity(0.2))
                        .cornerRadius(8)
                }

                // Streak & Daily Goal
                HStack(spacing: 16) {
                    // Streak Card
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(entry.streak) dias")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Text("Streak")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Daily Progress Card
                    VStack(spacing: 8) {
                        Text("\(entry.dailyProgress)/\(entry.dailyGoal)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        ProgressView(value: entry.dailyGoal > 0 ? Double(entry.dailyProgress) / Double(entry.dailyGoal) : 0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "FFD700")))

                        Text("Meta diária")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }

                // Stats Row
                HStack(spacing: 12) {
                    MiniStatCard(icon: "rectangle.stack.fill", value: "\(entry.pendingCards)", label: "Cards para revisar", color: .blue)
                    MiniStatCard(icon: "chart.bar.fill", value: "\(entry.accuracy)%", label: "Acurácia geral", color: .green)
                }

                // Quote
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "FFD700").opacity(0.5))

                    Text(entry.quote)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .italic()
                        .lineLimit(2)

                    Spacer()
                }
                .padding(12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)

                // CTA
                HStack {
                    Spacer()
                    Text("Toque para estudar →")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "FFD700"))
                }
            }
            .padding(16)
        }
    }
}

struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Lock Screen Widget (iOS 16+)

struct LockScreenWidgetView: View {
    let entry: ResumedEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("\(entry.streak)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .widgetBackground(Color.clear)
    }
}

// MARK: - Widget Configuration

@main
struct ResumedWidgetBundle: WidgetBundle {
    var body: some Widget {
        ResumedWidget()
        ResumedLockScreenWidget()
        NextTaskWidget()
        DayProgressWidget()
        ExamCountdownWidget()
        StudyLockScreenWidget()
    }
}

struct ResumedWidget: Widget {
    let kind: String = "ResumedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ResumedProvider()) { entry in
            ResumedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("RESUMED")
        .description("Acompanhe seu progresso de estudos")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ResumedLockScreenWidget: Widget {
    let kind: String = "ResumedLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ResumedProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Seu streak de estudos")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct ResumedWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ResumedEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .widgetBackground(Color(hex: "000000"))
    }
}

// MARK: - Study Widget Configurations

struct NextTaskWidget: Widget {
    let kind: String = "StudyNextTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextTaskProvider()) { entry in
            NextTaskWidgetView(entry: entry)
        }
        .configurationDisplayName("Próxima Tarefa")
        .description("Veja sua próxima tarefa de estudo do dia.")
        .supportedFamilies([.systemSmall])
    }
}

struct DayProgressWidget: Widget {
    let kind: String = "StudyDayProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DayProgressProvider()) { entry in
            DayProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Progresso do Dia")
        .description("Acompanhe todas as tarefas de estudo de hoje.")
        .supportedFamilies([.systemMedium])
    }
}

struct ExamCountdownWidget: Widget {
    let kind: String = "StudyExamCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExamCountdownProvider()) { entry in
            ExamCountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Contagem da Prova")
        .description("Quantos dias faltam para sua prova.")
        .supportedFamilies([.systemSmall])
    }
}

struct StudyLockScreenWidget: Widget {
    let kind: String = "StudyLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DayProgressProvider()) { entry in
            StudyLockScreenEntryView(progressEntry: entry)
        }
        .configurationDisplayName("Plano de Estudo")
        .description("Progresso e próxima tarefa na tela de bloqueio.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct StudyLockScreenEntryView: View {
    @Environment(\.widgetFamily) var family
    let progressEntry: DayProgressEntry

    var nextTaskEntry: NextTaskEntry {
        let first = progressEntry.tasks.first { !$0.completed }
        guard let task = first else {
            return progressEntry.tasks.isEmpty ? .empty : NextTaskEntry(
                date: progressEntry.date,
                taskTitle: "Tudo concluído!",
                taskTheme: "",
                taskMinutes: 0,
                taskId: "",
                isCompleted: true,
                isEmpty: false
            )
        }
        return NextTaskEntry(
            date: progressEntry.date,
            taskTitle: task.subject,
            taskTheme: "",
            taskMinutes: task.minutes,
            taskId: task.id,
            isCompleted: false,
            isEmpty: false
        )
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            StudyLockCircularView(entry: progressEntry)
        case .accessoryRectangular:
            StudyLockRectangularView(entry: nextTaskEntry)
        case .accessoryInline:
            StudyLockInlineView(entry: progressEntry)
        default:
            StudyLockCircularView(entry: progressEntry)
        }
    }
}

// MARK: - Color Extension for Widget

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ResumedWidget()
} timeline: {
    ResumedEntry(date: Date(), streak: 7, dailyGoal: 20, dailyProgress: 12, pendingCards: 5, quote: "A persistência é o caminho.", accuracy: 78, level: 12, xpProgress: 0.62)
}

#Preview(as: .systemMedium) {
    ResumedWidget()
} timeline: {
    ResumedEntry(date: Date(), streak: 7, dailyGoal: 20, dailyProgress: 12, pendingCards: 5, quote: "A persistência é o caminho.", accuracy: 78, level: 12, xpProgress: 0.62)
}

#Preview(as: .systemLarge) {
    ResumedWidget()
} timeline: {
    ResumedEntry(date: Date(), streak: 7, dailyGoal: 20, dailyProgress: 12, pendingCards: 5, quote: "A persistência é o caminho.", accuracy: 78, level: 12, xpProgress: 0.62)
}
