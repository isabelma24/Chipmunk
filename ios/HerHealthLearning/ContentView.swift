import SwiftUI

private enum Palette {
    static let ink = Color(red: 0.13, green: 0.17, blue: 0.18)
    static let muted = Color(red: 0.39, green: 0.43, blue: 0.42)
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let coral = Color(red: 0.58, green: 0.28, blue: 0.32)
    static let gold = Color(red: 0.67, green: 0.53, blue: 0.28)
    static let peach = Color(red: 0.96, green: 0.91, blue: 0.85)
    static let sage = Color(red: 0.83, green: 0.88, blue: 0.79)
    static let line = Color(red: 0.87, green: 0.86, blue: 0.82)
    static let keywordColors: [Color] = [coral, Color(red: 0.30, green: 0.48, blue: 0.43), gold, Color(red: 0.39, green: 0.39, blue: 0.64)]
}

private enum DailyRewardLedger {
    static let dailyCap = 100

    static func beginDay() {
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "chipmunk.careRulesVersion") < 3 {
            defaults.removeObject(forKey: "chipmunk.totalPoints")
            defaults.removeObject(forKey: "chipmunk.pointsToday")
            defaults.removeObject(forKey: "chipmunk.dailyCare")
            defaults.removeObject(forKey: "chipmunk.activityRewards")
            defaults.removeObject(forKey: "chipmunk.mapRewardDay")
            defaults.removeObject(forKey: "chipmunk.lessonsRewardedToday")
            defaults.removeObject(forKey: "chipmunk.wellnessStreak")
            defaults.removeObject(forKey: "chipmunk.bestWellnessStreak")
            defaults.removeObject(forKey: "chipmunk.lastWellnessDay")
            for need in CompanionNeed.allCases { defaults.removeObject(forKey: startKey(for: need)) }
            defaults.set(3, forKey: "chipmunk.careRulesVersion")
        }
        let key = dayKey
        if defaults.string(forKey: "chipmunk.rewardDay") == key {
            if CompanionNeed.allCases.contains(where: { defaults.object(forKey: startKey(for: $0)) == nil }) {
                for need in CompanionNeed.allCases {
                    let current = needValue(need, defaults: defaults)
                    defaults.set(current, forKey: startKey(for: need))
                }
                defaults.set(0, forKey: "chipmunk.dailyCare")
            }
            return
        }
        let previousDay = defaults.string(forKey: "chipmunk.rewardDay")
        if let previousDay {
            let daysAway = max(1, Calendar.current.dateComponents([.day], from: date(from: previousDay), to: Date()).day ?? 1)
            let previousDailyCare = defaults.integer(forKey: "chipmunk.dailyCare")
            if daysAway == 1, previousDailyCare > 90 {
                let previousDate = date(from: previousDay)
                let dayBeforePrevious = Calendar.current.date(byAdding: .day, value: -1, to: previousDate) ?? previousDate
                let lastCareDay = defaults.string(forKey: "chipmunk.lastCareBadgeDay") ?? ""
                let streak = lastCareDay == dateKey(dayBeforePrevious) ? defaults.integer(forKey: "chipmunk.careBadgeStreak") + 1 : 1
                defaults.set(streak, forKey: "chipmunk.careBadgeStreak")
                defaults.set(previousDay, forKey: "chipmunk.lastCareBadgeDay")
                defaults.set(max(streak, defaults.integer(forKey: "chipmunk.bestCareBadgeStreak")), forKey: "chipmunk.bestCareBadgeStreak")
            } else {
                defaults.set(0, forKey: "chipmunk.careBadgeStreak")
            }
            for need in CompanionNeed.allCases {
                let stored = needValue(need, defaults: defaults)
                defaults.set(Int(Double(stored) * pow(0.5, Double(daysAway))), forKey: need.storageKey)
            }
        } else {
            for need in CompanionNeed.allCases {
                if defaults.object(forKey: need.storageKey) == nil { defaults.set(55, forKey: need.storageKey) }
            }
        }
        defaults.set(key, forKey: "chipmunk.rewardDay")
        defaults.set(0, forKey: "chipmunk.dailyCare")
        for need in CompanionNeed.allCases {
            defaults.set(needValue(need, defaults: defaults), forKey: startKey(for: need))
        }
        defaults.removeObject(forKey: "chipmunk.lessonRewardsToday")
        defaults.removeObject(forKey: "chipmunk.activityRewards")
    }

    static func awardLesson(_ id: String) -> Int {
        beginDay()
        let defaults = UserDefaults.standard
        let ids = stringSet(defaults.string(forKey: "chipmunk.lessonRewardsToday"))
        guard !ids.contains(id) else { return 0 }
        let earned = award(10)
        if earned > 0 {
            defaults.set((ids.union([id])).sorted().joined(separator: ","), forKey: "chipmunk.lessonRewardsToday")
        }
        return earned
    }

    static func lessonRewardAmount(_ id: String) -> Int {
        beginDay()
        let defaults = UserDefaults.standard
        let ids = stringSet(defaults.string(forKey: "chipmunk.lessonRewardsToday"))
        return ids.contains(id) ? 0 : min(10, availableCare(defaults: defaults))
    }

    static func awardActivity(_ id: String) -> Int {
        beginDay()
        let defaults = UserDefaults.standard
        let ids = stringSet(defaults.string(forKey: "chipmunk.activityRewards"))
        guard !ids.contains(id) else { return 0 }
        let earned = award(5)
        if earned > 0 { defaults.set(ids.union([id]).sorted().joined(separator: ","), forKey: "chipmunk.activityRewards") }
        return earned
    }

    @discardableResult
    static func awardMastery() -> Int { award(10) }

    static func markStudyDay() {
        beginDay()
        let defaults = UserDefaults.standard
        let lastDay = defaults.string(forKey: "chipmunk.lastStudyDay") ?? ""
        guard lastDay != dayKey else { return }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayFormatter = DateFormatter()
        yesterdayFormatter.calendar = Calendar(identifier: .gregorian)
        yesterdayFormatter.timeZone = .current
        yesterdayFormatter.dateFormat = "yyyy-MM-dd"
        defaults.set(lastDay == yesterdayFormatter.string(from: yesterday) ? defaults.integer(forKey: "chipmunk.currentStreak") + 1 : 1, forKey: "chipmunk.currentStreak")
        defaults.set(dayKey, forKey: "chipmunk.lastStudyDay")
    }

    static var currentLocalDayKey: String { dayKey }

    private static func award(_ requested: Int) -> Int {
        beginDay()
        let defaults = UserDefaults.standard
        var remaining = min(requested, availableCare(defaults: defaults))
        let earned = remaining
        while remaining > 0,
              let need = CompanionNeed.allCases.filter({ needValue($0, defaults: defaults) < 100 }).min(by: {
                  needValue($0, defaults: defaults) < needValue($1, defaults: defaults)
              }) {
            let current = needValue(need, defaults: defaults)
            let added = min(remaining, 100 - current)
            defaults.set(current + added, forKey: need.storageKey)
            remaining -= added
        }
        guard earned > 0 else { return 0 }
        defaults.set(calculateDailyCare(defaults: defaults), forKey: "chipmunk.dailyCare")
        return earned
    }

    private static func availableCare(defaults: UserDefaults) -> Int {
        CompanionNeed.allCases.reduce(0) { $0 + max(0, 100 - needValue($1, defaults: defaults)) }
    }

    private static func calculateDailyCare(defaults: UserDefaults) -> Int {
        let startingTotal = CompanionNeed.allCases.reduce(0) { $0 + (defaults.object(forKey: startKey(for: $1)) == nil ? needValue($1, defaults: defaults) : defaults.integer(forKey: startKey(for: $1))) }
        let restoredTotal = CompanionNeed.allCases.reduce(0) { total, need in
            let starting = defaults.object(forKey: startKey(for: need)) == nil ? needValue(need, defaults: defaults) : defaults.integer(forKey: startKey(for: need))
            return total + max(0, needValue(need, defaults: defaults) - starting)
        }
        let totalRoom = CompanionNeed.allCases.count * 100 - startingTotal
        guard totalRoom > 0 else { return 100 }
        return min(dailyCap, restoredTotal * dailyCap / totalRoom)
    }

    private static func needValue(_ need: CompanionNeed, defaults: UserDefaults) -> Int {
        defaults.object(forKey: need.storageKey) == nil ? 55 : defaults.integer(forKey: need.storageKey)
    }

    private static func startKey(for need: CompanionNeed) -> String { "chipmunk.careStart.\(need.rawValue)" }

    private static var dayKey: String {
        dateKey(Date())
    }

    private static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func stringSet(_ raw: String?) -> Set<String> {
        Set((raw ?? "").split(separator: ",").map(String.init))
    }

    private static func date(from key: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key) ?? Date()
    }
}

private enum CompanionNeed: String, CaseIterable, Identifiable {
    case food, water, rest, strength, joy
    var id: String { rawValue }
    var storageKey: String { "chipmunk.need.\(rawValue)" }
    var title: String {
        switch self {
        case .food: "Nourishment"
        case .water: "Water"
        case .rest: "Rest"
        case .strength: "Strength"
        case .joy: "Happiness"
        }
    }
    var symbol: String {
        switch self {
        case .food: "carrot.fill"
        case .water: "drop.fill"
        case .rest: "moon.zzz.fill"
        case .strength: "dumbbell.fill"
        case .joy: "heart.fill"
        }
    }
    var tint: Color {
        switch self {
        case .food: Palette.coral
        case .water: Color(red: 0.30, green: 0.53, blue: 0.68)
        case .rest: Color(red: 0.42, green: 0.43, blue: 0.66)
        case .strength: Palette.gold
        case .joy: Color(red: 0.72, green: 0.39, blue: 0.47)
        }
    }
}

private enum LearningTrack: String, CaseIterable, Identifiable {
    case body = "Women’s health"
    case mind = "Mental health"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .body: "Start with how the body works, then explore health across a lifetime."
        case .mind: "Start with the foundations, then explore mood, anxiety, ADHD, and mind–body health."
        }
    }

    var symbol: String {
        switch self {
        case .body: "waveform.path.ecg"
        case .mind: "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .body: Color(red: 0.43, green: 0.18, blue: 0.24)
        case .mind: Color(red: 0.16, green: 0.34, blue: 0.31)
        }
    }

    var firstLesson: String {
        switch self {
        case .body: "How the body is organized"
        case .mind: "What mental health means"
        }
    }

    var nextLessons: [String] {
        switch self {
        case .body: ["Cells, tissues, and organs", "How body systems work together", "Keeping the body in balance"]
        case .mind: ["The brain, feelings, and behavior", "Depression and anxiety", "ADHD and attention", "Stress, sleep, and the body"]
        }
    }

    var lessonExplanation: String {
        switch self {
        case .body: "Anatomy describes body structures. Physiology explains how those structures work. Textbooks build from small pieces to larger systems: chemical, cellular, tissue, organ, organ system, and the whole organism."
        case .mind: "Mental health includes emotional, psychological, and social well-being. It is part of overall health and can change across time and circumstances. Learning about a condition is not the same as diagnosing yourself."
        }
    }

    var lessonExample: String {
        switch self {
        case .body: "A heart is an organ. Its muscle cells form tissues; those tissues work with other structures in the cardiovascular system."
        case .mind: "A stressful week can affect mood, sleep, concentration, and relationships. One experience by itself does not establish a mental health diagnosis."
        }
    }

    var quizPrompt: String {
        switch self {
        case .body: "Which level comes directly after tissue?"
        case .mind: "According to NIMH, which areas are part of mental health?"
        }
    }

    var quizOptions: [String] {
        switch self {
        case .body: ["Cell", "Organ", "Organ system"]
        case .mind: ["Emotional, psychological, and social well-being", "Mood only", "Whether someone has a diagnosis"]
        }
    }

    var quizAnswer: String {
        switch self {
        case .body: quizOptions[1]
        case .mind: quizOptions[0]
        }
    }

    var sourceTitle: String {
        switch self {
        case .body: "OpenStax · Anatomy & Physiology 2e, §1.2"
        case .mind: "National Institute of Mental Health · Caring for Your Mental Health"
        }
    }

    var sourceURL: URL {
        switch self {
        case .body: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/1-2-structural-organization-of-the-human-body")!
        case .mind: URL(string: "https://www.nimh.nih.gov/health/topics/caring-for-your-mental-health")!
        }
    }

    var secondLesson: String {
        switch self {
        case .body: "How the body keeps balance"
        case .mind: "Mental health in context"
        }
    }

    var secondExplanation: String {
        switch self {
        case .body: "Homeostasis is the body’s ongoing regulation of internal conditions within healthy ranges. Negative feedback helps reverse a change that moves a condition away from its usual range."
        case .mind: "Health is shaped by interacting biological, behavioral, social, structural, and environmental factors. A women-centered mental health course looks at those influences together instead of assuming one explanation fits everyone."
        }
    }

    var secondExample: String {
        switch self {
        case .body: "When body temperature rises, sensors and control centers help trigger responses such as sweating, which helps release heat."
        case .mind: "Sleep, stress, relationships, physical health, and life circumstances can all matter to well-being. Their effects vary from person to person, and a single factor does not diagnose a condition."
        }
    }

    var secondQuizPrompt: String {
        switch self {
        case .body: "What does negative feedback generally do?"
        case .mind: "Which is a useful way to study mental health in women?"
        }
    }

    var secondQuizOptions: [String] {
        switch self {
        case .body: ["Reverses a deviation toward its usual range", "Always intensifies a change", "Prevents the body from changing"]
        case .mind: ["Consider biological and social context together", "Assume one factor explains everyone", "Treat one symptom as a diagnosis"]
        }
    }

    var secondQuizAnswer: String { secondQuizOptions[0] }

    var secondSourceTitle: String {
        switch self {
        case .body: "OpenStax · Anatomy & Physiology 2e, §1.5"
        case .mind: "NIH Office of Research on Women’s Health · Strategic Plan"
        }
    }

    var secondSourceURL: URL {
        switch self {
        case .body: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/1-5-homeostasis")!
        case .mind: URL(string: "https://orwh.od.nih.gov/about/strategic-plan")!
        }
    }

    var lessonCount: Int { 10 }

    private func extendedLesson(_ number: Int) -> CourseLesson {
        (self == .mind ? MindCourse.lessons : BodyCourse.lessons)[number - 3]
    }

    func title(at number: Int) -> String {
        guard number > 2 else { return number == 1 ? firstLesson : secondLesson }
        return extendedLesson(number).title
    }

    func explanation(at number: Int) -> String {
        guard number > 2 else { return number == 1 ? lessonExplanation : secondExplanation }
        return extendedLesson(number).explanation
    }

    func example(at number: Int) -> String {
        guard number > 2 else { return number == 1 ? lessonExample : secondExample }
        return extendedLesson(number).example
    }

    func prompt(at number: Int) -> String {
        guard number > 2 else { return number == 1 ? quizPrompt : secondQuizPrompt }
        return extendedLesson(number).prompt
    }

    func options(at number: Int) -> [String] {
        guard number > 2 else { return number == 1 ? quizOptions : secondQuizOptions }
        return extendedLesson(number).options
    }

    func answer(at number: Int) -> String {
        guard number > 2 else { return number == 1 ? quizAnswer : secondQuizAnswer }
        return extendedLesson(number).answer
    }

    func sourceTitle(at number: Int) -> String {
        guard number > 2 else { return number == 1 ? sourceTitle : secondSourceTitle }
        return extendedLesson(number).sourceTitle
    }

    func sourceURL(at number: Int) -> URL {
        guard number > 2 else { return number == 1 ? sourceURL : secondSourceURL }
        return extendedLesson(number).sourceURL
    }

    func keywords(for lessonNumber: Int) -> [String] {
        if lessonNumber > 2 { return extendedLesson(lessonNumber).keywords }
        return switch (self, lessonNumber) {
        case (.body, 1): ["Anatomy", "Physiology", "Cell", "Tissue", "Organ", "Organ system"]
        case (.body, _): ["Homeostasis", "Negative feedback", "Set point", "Regulation"]
        case (.mind, 1): ["Mental health", "Emotional well-being", "Psychological well-being", "Social well-being"]
        default: ["Biopsychosocial context", "Biological factors", "Behavioral factors", "Social determinants"]
        }
    }
}

private struct CourseLesson {
    let title: String
    let explanation: String
    let example: String
    let prompt: String
    let options: [String]
    let answer: String
    let sourceTitle: String
    let sourceURL: URL
    let keywords: [String]
}

private enum MindCourse {
    // Introductory sequence informed by NIH and the U.S. Office on Women's Health.
    // These are learning prompts, not screening or self-diagnosis activities.
    static let lessons: [CourseLesson] = [
        CourseLesson(title: "Stress and the body", explanation: "Stress is a physical and mental response to an external demand. The response can affect attention, sleep, muscles, digestion, and mood; it is shaped by both biology and circumstances.", example: "A deadline may bring a faster heartbeat and narrowed attention. The response can be useful briefly, while prolonged stress may affect well-being.", prompt: "Which statement best describes stress?", options: ["A response to an external demand that can affect body and mind", "A mental-health diagnosis by itself", "A response that is always harmful"], answer: "A response to an external demand that can affect body and mind", sourceTitle: "Office on Women’s Health · Stress and your health", sourceURL: URL(string: "https://womenshealth.gov/mental-health/good-mental-health/stress-and-your-health")!, keywords: ["Stress", "Stress response", "Context", "Body–mind connection"]),
        CourseLesson(title: "Sleep, mood, and attention", explanation: "Sleep and mental well-being influence each other. Sleep timing, light, health, stress, and daily routines can all matter, and sleep difficulties have more than one possible cause.", example: "After a short night, a person may notice changes in focus or patience. That observation can describe a day without diagnosing a sleep or mental-health condition.", prompt: "What can one difficult night tell you on its own?", options: ["It proves a disorder", "It is one observation; patterns and context matter", "It means sleep has no effect on mood"], answer: "It is one observation; patterns and context matter", sourceTitle: "Office on Women’s Health · Sleep and your health", sourceURL: URL(string: "https://womenshealth.gov/mental-health/good-mental-health/sleep-and-your-health")!, keywords: ["Sleep", "Circadian rhythm", "Attention", "Pattern"]),
        CourseLesson(title: "Anxiety: the alarm system", explanation: "Anxiety is a normal response that can help someone prepare for a challenge. When fear or worry becomes persistent, difficult to control, or interferes with daily life, a qualified professional can help assess what is happening.", example: "Nervousness before a presentation can be a common stress response. Its presence alone does not establish an anxiety disorder.", prompt: "Which distinction is most accurate?", options: ["All anxiety is an illness", "Anxiety can be normal; persistence and interference are important context", "A body sensation alone identifies an anxiety disorder"], answer: "Anxiety can be normal; persistence and interference are important context", sourceTitle: "NIMH · Anxiety Disorders", sourceURL: URL(string: "https://www.nimh.nih.gov/health/topics/anxiety-disorders")!, keywords: ["Anxiety", "Threat response", "Avoidance", "Functional impact"]),
        CourseLesson(title: "Depression: more than sadness", explanation: "Depression can involve changes in mood, interest, thinking, energy, sleep, appetite, and physical experience. Researchers describe multiple contributing biological, psychological, and environmental factors rather than one simple cause.", example: "Trouble sleeping or concentrating can occur for many reasons. Clinicians consider duration, severity, impact, context, and other explanations rather than one sign alone.", prompt: "What is a careful way to interpret a single symptom?", options: ["Treat it as proof of depression", "Consider it one piece of information among duration, impact, and context", "Ignore it in every case"], answer: "Consider it one piece of information among duration, impact, and context", sourceTitle: "NIMH · Depression in Women", sourceURL: URL(string: "https://www.nimh.nih.gov/health/publications/depression-in-women")!, keywords: ["Depression", "Mood", "Anhedonia", "Context"]),
        CourseLesson(title: "ADHD and executive function", explanation: "ADHD is a neurodevelopmental disorder involving persistent patterns of inattention and/or hyperactivity-impulsivity that can affect functioning. Sleep problems, stress, anxiety, depression, and other conditions can produce overlapping difficulties, so a quiz cannot diagnose ADHD.", example: "Forgetting a task once is common. Assessment considers a persistent pattern across settings and a person’s developmental and health history.", prompt: "Why is a short attention game not an ADHD test?", options: ["Attention never varies", "Many factors affect attention; diagnosis requires a qualified assessment", "ADHD can be diagnosed from one missed task"], answer: "Many factors affect attention; diagnosis requires a qualified assessment", sourceTitle: "NIMH · Attention-Deficit/Hyperactivity Disorder", sourceURL: URL(string: "https://www.nimh.nih.gov/health/topics/attention-deficit-hyperactivity-disorder-adhd")!, keywords: ["ADHD", "Executive function", "Attention", "Assessment"]),
        CourseLesson(title: "Trauma, safety, and support", explanation: "Trauma exposure and responses vary. Post-traumatic stress disorder is one possible response, but not everyone who experiences trauma develops PTSD. Safety, support, culture, and access to care shape recovery and well-being.", example: "Two people can respond differently to a similar event. Their reactions deserve care without comparison or assumptions.", prompt: "Which statement about trauma responses is accurate?", options: ["Everyone responds the same way", "Responses vary, and not everyone develops PTSD", "A person’s reaction can be judged from one detail"], answer: "Responses vary, and not everyone develops PTSD", sourceTitle: "NIMH · Post-Traumatic Stress Disorder", sourceURL: URL(string: "https://www.nimh.nih.gov/health/topics/post-traumatic-stress-disorder-ptsd")!, keywords: ["Trauma", "PTSD", "Safety", "Social support"]),
        CourseLesson(title: "Hormones and life stages", explanation: "Some people experience mental-health symptoms around reproductive hormone transitions, including premenstrual dysphoric disorder, perinatal depression, or the menopause transition. Experiences differ; timing can be relevant information for a clinician but is not a diagnosis by itself.", example: "A person might notice a recurring change across a cycle. A careful record can help them describe timing to a health professional if they choose.", prompt: "What can a repeated timing pattern offer?", options: ["A diagnosis by itself", "Useful context to discuss with a qualified health professional", "Proof that hormones explain every mood change"], answer: "Useful context to discuss with a qualified health professional", sourceTitle: "NIMH · Women and Mental Health", sourceURL: URL(string: "https://www.nimh.nih.gov/health/topics/women-and-mental-health")!, keywords: ["Reproductive life stages", "Hormone transition", "PMDD", "Perinatal mental health"]),
        CourseLesson(title: "How women’s health research works", explanation: "A women-centered research lens asks how biological, behavioral, social, structural, and environmental factors interact across the life course. Sex and gender are distinct concepts, and study populations and methods affect what findings can tell us.", example: "A study in one age group or population may not answer the same question for everyone. Good evidence states who was studied and what remains uncertain.", prompt: "What should you check when reading a health claim?", options: ["Who was studied, how, and what is still uncertain", "Only whether the headline sounds confident", "Whether one finding applies to every person"], answer: "Who was studied, how, and what is still uncertain", sourceTitle: "NIH ORWH · Strategic Plan for Research on the Health of Women 2024–2028", sourceURL: URL(string: "https://orwh.od.nih.gov/about/strategic-plan")!, keywords: ["Study population", "Sex", "Gender", "Evidence limits"])
    ]
}

private enum BodyCourse {
    // A textbook-style sequence from chemistry and cells into women-specific physiology.
    static let lessons: [CourseLesson] = [
        CourseLesson(title: "Water, ions, and pH", explanation: "Water is the body’s main solvent. Dissolved ions such as sodium, potassium, and chloride help establish electrical and chemical conditions that cells need. Buffers and organ systems help keep pH within a narrow range.", example: "Electrolytes carry charge in body fluids. Their concentrations are regulated; a sports drink is not a general treatment for every symptom.", prompt: "What is an electrolyte in body fluids?", options: ["A charged particle dissolved in fluid", "A type of tissue", "A hormone released by the ovary"], answer: "A charged particle dissolved in fluid", sourceTitle: "OpenStax · Anatomy & Physiology 2e, Ch. 26", sourceURL: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/26-introduction")!, keywords: ["Water", "Ion", "Electrolyte", "pH"]),
        CourseLesson(title: "Inside a cell", explanation: "A cell’s membrane separates its internal environment from its surroundings. The cytoplasm contains organelles that carry out specialized tasks; the nucleus stores most of the cell’s DNA. Cell structure varies with function.", example: "A neuron’s long extensions support communication over distance, while epithelial cells form closely packed protective surfaces.", prompt: "Which structure forms a selective boundary around a cell?", options: ["Cell membrane", "Endometrium", "Hair shaft"], answer: "Cell membrane", sourceTitle: "OpenStax · Anatomy & Physiology 2e, Ch. 3", sourceURL: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/3-introduction")!, keywords: ["Cell membrane", "Cytoplasm", "Organelle", "Nucleus"]),
        CourseLesson(title: "Four tissue families", explanation: "The body’s tissues are commonly grouped as epithelial, connective, muscle, and nervous tissue. Their structures support different functions, from lining surfaces to transmitting signals and producing movement.", example: "Skin contains epithelial tissue at its surface and connective tissue below. Organs combine multiple tissue types.", prompt: "Which tissue family is specialized for contraction?", options: ["Muscle", "Epithelial", "Nervous"], answer: "Muscle", sourceTitle: "OpenStax · Anatomy & Physiology 2e, Ch. 4", sourceURL: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/4-introduction")!, keywords: ["Tissue", "Epithelial", "Connective", "Nervous"]),
        CourseLesson(title: "Skin, hair, and nails", explanation: "The integumentary system includes skin and its accessory structures, including hair, nails, and glands. It helps form a barrier, senses the environment, and contributes to temperature regulation. Skin has distinct layers with different structures and roles.", example: "Hair follicles sit within the skin; the visible hair shaft is made of keratinized cells. Hair growth varies across body regions and people.", prompt: "Which structures are part of the integumentary system?", options: ["Skin, hair, nails, and associated glands", "Ovaries and uterine tubes", "Heart and blood vessels"], answer: "Skin, hair, nails, and associated glands", sourceTitle: "OpenStax · Anatomy & Physiology 2e, Ch. 5", sourceURL: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/5-introduction")!, keywords: ["Integumentary system", "Epidermis", "Dermis", "Hair follicle"]),
        CourseLesson(title: "Hormones and target cells", explanation: "Endocrine glands release hormones into the circulation. A hormone affects cells with compatible receptors, coordinating processes such as growth, metabolism, stress responses, and reproduction. Hormone effects depend on dose, timing, tissue, and feedback.", example: "The same hormone can have different effects in different tissues because receptor expression and local cell responses differ.", prompt: "What makes a cell responsive to a particular hormone?", options: ["A compatible receptor and cellular response machinery", "Its location near the skin", "The presence of any hormone in blood"], answer: "A compatible receptor and cellular response machinery", sourceTitle: "OpenStax · Anatomy & Physiology 2e, §17.1", sourceURL: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/17-1-an-overview-of-the-endocrine-system")!, keywords: ["Endocrine system", "Hormone", "Receptor", "Target cell"]),
        CourseLesson(title: "Reproductive anatomy", explanation: "The ovarian reproductive system includes ovaries, uterine tubes, uterus, cervix, vagina, and external genital structures called the vulva. Their structures have distinct roles. Anatomy varies, and reproductive anatomy does not determine a person’s gender identity.", example: "An oocyte released from an ovary may enter a uterine tube. The uterus has a muscular wall and an endometrium that changes over the cycle.", prompt: "Where does an oocyte typically enter after ovulation?", options: ["Uterine tube", "Urethra", "Cervical canal"], answer: "Uterine tube", sourceTitle: "OpenStax · Anatomy & Physiology 2e, §27.2", sourceURL: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/27-2-anatomy-and-physiology-of-the-ovarian-reproductive-system")!, keywords: ["Ovary", "Oocyte", "Uterine tube", "Uterus"]),
        CourseLesson(title: "The ovarian and uterine cycles", explanation: "The ovarian cycle describes follicle development and ovulation; the uterine cycle describes changes in the endometrium. These cycles are coordinated by hormones, but cycle length and bleeding patterns vary between people and across time.", example: "The first day of menstrual bleeding is counted as day one of a cycle. A 28-day cycle is a teaching reference, not a universal schedule.", prompt: "Which event marks day one of a menstrual cycle?", options: ["The onset of menstrual bleeding", "Ovulation in every cycle", "The midpoint of a 28-day calendar"], answer: "The onset of menstrual bleeding", sourceTitle: "OpenStax · Anatomy & Physiology 2e, §27.2", sourceURL: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/27-2-anatomy-and-physiology-of-the-ovarian-reproductive-system")!, keywords: ["Ovarian cycle", "Uterine cycle", "Ovulation", "Endometrium"]),
        CourseLesson(title: "Hormone feedback across the cycle", explanation: "The hypothalamus and pituitary communicate with the ovaries through GnRH, FSH, and LH. Ovarian hormones then affect reproductive tissues and feed back to the brain and pituitary. A mid-cycle LH surge usually triggers ovulation, though timing varies.", example: "Follicular and luteal phases describe ovarian events; menses, proliferative, and secretory phases describe the uterine lining.", prompt: "What does the mid-cycle LH surge usually trigger?", options: ["Ovulation", "Menstruation in every cycle", "The start of puberty"], answer: "Ovulation", sourceTitle: "OpenStax · Anatomy & Physiology 2e, §27.2", sourceURL: URL(string: "https://openstax.org/books/anatomy-and-physiology-2e/pages/27-2-anatomy-and-physiology-of-the-ovarian-reproductive-system")!, keywords: ["Hypothalamus", "FSH", "LH surge", "Progesterone"])
    ]
}

private struct CareBadge: Identifiable {
    let title: String
    let detail: String
    let symbol: String
    let wellnessDays: Int

    var id: String { title }
    func earned(bestStreak: Int) -> Bool { bestStreak >= wellnessDays }
}

private enum BadgeCatalog {
    static let all = [
        CareBadge(title: "Care Keeper", detail: "Daily care above 90 for one local day", symbol: "heart.fill", wellnessDays: 1),
        CareBadge(title: "Explorer", detail: "Daily care above 90 for three days in a row", symbol: "sparkle.magnifyingglass", wellnessDays: 3),
        CareBadge(title: "Guardian", detail: "Daily care above 90 for one week", symbol: "shield.lefthalf.filled", wellnessDays: 7),
        CareBadge(title: "Expert", detail: "Daily care above 90 for two weeks", symbol: "rosette", wellnessDays: 14)
    ]

    static func highestEarned(bestStreak: Int) -> CareBadge? {
        all.last(where: { $0.earned(bestStreak: bestStreak) })
    }

    static func next(bestStreak: Int) -> CareBadge? {
        all.first(where: { !$0.earned(bestStreak: bestStreak) })
    }
}

private struct CareBadgeProgressCard: View {
    let bestCareStreak: Int
    private var earnedBadge: CareBadge? { BadgeCatalog.highestEarned(bestStreak: bestCareStreak) }
    private var nextBadge: CareBadge? { BadgeCatalog.next(bestStreak: bestCareStreak) }

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: earnedBadge?.symbol ?? nextBadge?.symbol ?? "rosette")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Palette.gold)
                .frame(width: 42, height: 42)
                .background(Palette.gold.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(earnedBadge.map { "Learner level · \($0.title)" } ?? "Next learner badge · \(nextBadge?.title ?? "All earned")")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text(nextBadge?.detail ?? "You’ve earned every care-streak badge.")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct TrackPickerView: View {
    let onSelect: (LearningTrack) -> Void
    @State private var placementTrack: LearningTrack?

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.paper.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        introduction

                        VStack(spacing: 12) {
                            ForEach(LearningTrack.allCases) { track in
                                VStack(spacing: 6) {
                                    Button {
                                        onSelect(track)
                                    } label: {
                                        TrackCard(track: track)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        placementTrack = track
                                    } label: {
                                        Text("Already know the basics?  Take a placement quiz →")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Palette.muted)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .padding(.trailing, 10)
                                            .padding(.vertical, 5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        evidenceNote
                        footer
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $placementTrack) { track in
            PlacementQuizView(track: track) {
                onSelect(track)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .tint(Palette.coral)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Text("🐿️")
                    .font(.system(size: 22))
                    .foregroundStyle(Palette.coral)
                Text("CHIPMUNK")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.7)
                    .foregroundStyle(Palette.ink)
            }
            Spacer()
            Text("AGES 16+")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Palette.muted)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(.white.opacity(0.75), in: Capsule())
        }
        .padding(.top, 8)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("HEALTH, MADE\nUNDERSTANDABLE.")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(-1.1)
                .lineSpacing(-1)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

                        Text("Discover the science of your body and mind.")
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .lineSpacing(4)
                .foregroundStyle(Palette.muted)

            HStack(spacing: 7) {
                Image(systemName: "checkmark.seal")
                Text("RESEARCH-BASED")
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(Palette.coral)
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var evidenceNote: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 15))
                .foregroundStyle(Palette.coral)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 5) {
                Text("Evidence-led learning")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("Explore the body and mind through research, clinical guidance, and clear explanations.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .lineSpacing(3)
                    .foregroundStyle(Palette.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
    }

    private var footer: some View {
        Text("Education for curiosity and understanding. Not a diagnosis.")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(Palette.muted)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.top, 1)
    }
}

private struct TrackCard: View {
    let track: LearningTrack

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: track.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(track.color)
                .frame(width: 48, height: 48)
                .background(track.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 7) {
                Text(track.rawValue)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text(track.subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Palette.muted)
                Text("START THIS TRACK  →")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(track.color)
                    .padding(.top, 5)
            }
            Spacer(minLength: 0)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 21))
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .stroke(Palette.line.opacity(0.75), lineWidth: 1)
        }
    }
}

private struct LearningPathView: View {
    let track: LearningTrack
    let onSwitchTrack: () -> Void
    @AppStorage("chipmunk.dailyCare") private var dailyCare = 0
    @AppStorage("chipmunk.currentStreak") private var currentStreak = 0
    @AppStorage("chipmunk.completedLessonIDs") private var completedLessonIDs = ""
    @AppStorage("chipmunk.placementPassedTrack") private var placementPassedTrack = ""
    @AppStorage("chipmunk.lastCompletedTrack") private var lastCompletedTrack = ""
    @AppStorage("chipmunk.lastCompletedLessonNumber") private var lastCompletedLessonNumber = 0
    @AppStorage("chipmunk.lastLessonCompletedDay") private var lastLessonCompletedDay = ""
    @AppStorage("chipmunk.bestCareBadgeStreak") private var bestCareStreak = 0

    private var completedIDs: Set<String> {
        Set(completedLessonIDs.split(separator: ",").map(String.init))
    }

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    private func isUnlocked(_ number: Int) -> Bool {
        if number == 1 { return true }
        if number == 2 && placementPassedTrack == track.rawValue { return true }
        return completedIDs.contains("\(track.rawValue).\(String(format: "%02d", number - 1))")
    }

    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 12) {
                        Image(systemName: track.symbol)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(track.color)
                            .frame(width: 46, height: 46)
                            .background(track.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(track.rawValue.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(1.1)
                                .foregroundStyle(track.color)
                            Text("Course")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                        }
                    }

                    HStack(spacing: 12) {
                        StatPill(symbol: "flame.fill", value: "\(currentStreak)", label: "DAY STREAK", tint: Palette.coral)
                        StatPill(symbol: "heart.fill", value: "\(dailyCare)/100", label: "DAILY CARE", tint: Palette.gold)
                    }
                    CareBadgeProgressCard(bestCareStreak: bestCareStreak)

                    if lastLessonCompletedDay == todayKey, lastCompletedTrack == track.rawValue, lastCompletedLessonNumber < track.lessonCount {
                        NavigationLink {
                            LearningLessonView(track: track, lessonNumber: lastCompletedLessonNumber + 1)
                        } label: {
                            TomorrowTeaserCard(track: track, nextLessonNumber: lastCompletedLessonNumber + 1)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(1...track.lessonCount, id: \.self) { number in
                            let unlocked = isUnlocked(number)
                            let completed = completedIDs.contains("\(track.rawValue).\(String(format: "%02d", number))")
                            let title = track.keywords(for: number).prefix(2).joined(separator: " · ")
                            let subtitle = track.title(at: number)
                            if unlocked {
                                NavigationLink {
                                    LearningLessonView(track: track, lessonNumber: number)
                                } label: {
                                    pathLesson(number: String(format: "%02d", number), title: title, detail: subtitle, active: true, completed: completed)
                                }.buttonStyle(.plain)
                            } else {
                                pathLesson(number: String(format: "%02d", number), title: title, detail: "Unlock after the previous lesson", active: false, completed: false)
                            }
                        }
                    }

                    if completedIDs.contains("\(track.rawValue).10") {
                        NavigationLink {
                            CourseReviewQuizView(track: track)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rosette")
                                    .font(.system(size: 20)).foregroundStyle(Palette.gold)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(track == .body ? "Unit 1 · Body foundations" : "Unit 1 · Mind & body")
                                        .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                                    Text("10-question mastery quiz")
                                        .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                Image(systemName: "arrow.right").foregroundStyle(Palette.coral)
                            }
                            .padding(15).background(.white, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                    } else {
                        Label(track == .body ? "Unit 1 · Body foundations" : "Unit 1 · Mind & body", systemImage: "lock.fill")
                            .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Palette.muted).padding(.top, 4)
                    }
                }
                .padding(22)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("CHIPMUNK")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Palette.ink)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Tracks", action: onSwitchTrack)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.coral)
            }
        }
        .onAppear {
            DailyRewardLedger.beginDay()
        }
    }

    private func pathLesson(number: String, title: String, detail: String, active: Bool, completed: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(active ? track.color : Palette.line).frame(width: 34, height: 34)
                    if completed {
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                    } else if active {
                        Image(systemName: "play.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
                    }
                }
                Rectangle().fill(Palette.line).frame(width: 2, height: 50)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("LESSON \(number)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(active ? track.color : Palette.muted)
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(active ? Palette.ink : Palette.muted)
                Text(detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.muted)
            }
            .padding(.top, 2)
            Spacer(minLength: 0)
        }
    }
}

private struct LearningLessonView: View {
    let track: LearningTrack
    let lessonNumber: Int
    @AppStorage("chipmunk.dailyCare") private var dailyCare = 0
    @AppStorage("chipmunk.completedLessonIDs") private var completedLessonIDs = ""
    @AppStorage("chipmunk.lastCompletedTrack") private var lastCompletedTrack = ""
    @AppStorage("chipmunk.lastCompletedLessonNumber") private var lastCompletedLessonNumber = 0
    @AppStorage("chipmunk.lastLessonCompletedDay") private var lastLessonCompletedDay = ""
    @State private var selectedAnswer: String?
    @State private var submitted = false
    @State private var completed = false
    @State private var activityCareEarned = 0
    @State private var lessonCareEarned = 0

    private var isFirstLesson: Bool { lessonNumber == 1 }
    private var lessonTitle: String { track.title(at: lessonNumber) }
    private var explanation: String { track.explanation(at: lessonNumber) }
    private var example: String { track.example(at: lessonNumber) }
    private var quizPrompt: String { track.prompt(at: lessonNumber) }
    private var quizOptions: [String] { track.options(at: lessonNumber) }
    private var quizAnswer: String { track.answer(at: lessonNumber) }
    private var sourceTitle: String { track.sourceTitle(at: lessonNumber) }
    private var sourceURL: URL { track.sourceURL(at: lessonNumber) }
    private var lessonID: String { "\(track.rawValue).\(String(format: "%02d", lessonNumber))" }
    private var answerIsCorrect: Bool { selectedAnswer == quizAnswer }
    private var markedExplanation: AttributedString {
        var result = AttributedString(explanation)
        result.foregroundColor = Palette.muted
        for (index, keyword) in track.keywords(for: lessonNumber).enumerated() {
            if let range = result.range(of: keyword, options: [.caseInsensitive]) {
                result[range].underlineStyle = .single
                result[range].foregroundColor = Palette.keywordColors[index % Palette.keywordColors.count]
                result[range].font = .system(size: 16, weight: .bold, design: .rounded)
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Text("LESSON \(String(format: "%02d", lessonNumber))")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(track.color)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(lessonTitle)
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                            .tracking(-0.5)
                            .foregroundStyle(Palette.ink)
                        FlashcardDeck(words: track.keywords(for: lessonNumber), track: track)
                        Text(markedExplanation)
                            .font(.system(size: 16, design: .rounded))
                            .lineSpacing(5)
                    }

                    LessonVisualCard(track: track, lessonNumber: lessonNumber) {
                        DailyRewardLedger.markStudyDay()
                        let earned = DailyRewardLedger.awardActivity(lessonID)
                        activityCareEarned = earned
                        dailyCare = UserDefaults.standard.integer(forKey: "chipmunk.dailyCare")
                    }
                    if activityCareEarned > 0 {
                        Label("+\(activityCareEarned) care · Concept activity complete", systemImage: "sparkle")
                            .font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(Palette.gold)
                    } else if dailyCare >= DailyRewardLedger.dailyCap {
                        Text("All five care needs are full today.")
                            .font(.system(size: 10, design: .rounded)).foregroundStyle(Palette.muted)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkle").foregroundStyle(Palette.gold)
                            Text("EXAMPLE")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(Palette.ink)
                        }
                        Text(example)
                            .font(.system(size: 14, design: .rounded))
                            .lineSpacing(4)
                            .foregroundStyle(Palette.ink)
                    }
                    .padding(17)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECALL")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(track.color)
                        Text(quizPrompt)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)

                        ForEach(quizOptions, id: \.self) { option in
                            Button {
                                if !submitted { selectedAnswer = option }
                            } label: {
                                HStack(spacing: 11) {
                                    Image(systemName: selectedAnswer == option ? "largecircle.fill.circle" : "circle")
                                        .font(.system(size: 17))
                                        .foregroundStyle(selectedAnswer == option ? track.color : Palette.muted)
                                    Text(option)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(Palette.ink)
                                    Spacer(minLength: 0)
                                }
                                .padding(13)
                                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 13))
                                .overlay(RoundedRectangle(cornerRadius: 13).stroke(selectedAnswer == option ? track.color.opacity(0.65) : Palette.line, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(submitted)
                        }

                        if submitted {
                            Text(answerIsCorrect ? "Correct: \(quizAnswer)" : "Review: \(quizAnswer)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(answerIsCorrect ? Color(red: 0.22, green: 0.42, blue: 0.34) : Palette.coral)
                                .padding(.top, 3)
                        }
                    }

                    Link(destination: sourceURL) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "book.closed")
                                .foregroundStyle(Palette.gold)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SOURCE")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .tracking(0.9)
                                    .foregroundStyle(Palette.muted)
                                Text(sourceTitle)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Palette.ink)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(.vertical, 12)
                    }

                    if completed {
                        if lessonCareEarned > 0 {
                            Label("+\(lessonCareEarned) care · Chip feels better", systemImage: "heart.fill")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Palette.coral)
                        } else {
                            Text("Chip has already received care for this lesson today, or all five needs are full.")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.muted)
                        }
                        if lessonNumber < track.lessonCount {
                            NavigationLink {
                                LearningLessonView(track: track, lessonNumber: lessonNumber + 1)
                            } label: {
                                lessonActionLabel("Continue to lesson \(String(format: "%02d", lessonNumber + 1))")
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                CourseReviewQuizView(track: track)
                            } label: {
                                lessonActionLabel("Start unit quiz")
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button {
                            if submitted && !answerIsCorrect {
                                submitted = false
                                selectedAnswer = nil
                            } else if submitted && answerIsCorrect {
                                lessonCareEarned = DailyRewardLedger.awardLesson(lessonID)
                                if !completedLessonIDs.split(separator: ",").contains(Substring(lessonID)) {
                                    completedLessonIDs = [completedLessonIDs, lessonID].filter { !$0.isEmpty }.joined(separator: ",")
                                }
                                lastCompletedTrack = track.rawValue
                                lastCompletedLessonNumber = lessonNumber
                                DailyRewardLedger.markStudyDay()
                                lastLessonCompletedDay = DailyRewardLedger.currentLocalDayKey
                                completed = true
                            } else {
                                submitted = true
                            }
                        } label: {
                            lessonActionLabel(buttonTitle)
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedAnswer == nil)
                        .opacity(selectedAnswer == nil ? 0.45 : 1)
                    }

                    if completed {
                        if lessonNumber < track.lessonCount {
                            NavigationLink {
                                LearningLessonView(track: track, lessonNumber: lessonNumber + 1)
                            } label: {
                                TomorrowTeaserCard(track: track, nextLessonNumber: lessonNumber + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(22)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("CHIPMUNK")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Palette.ink)
            }
        }
    }

    private var buttonTitle: String {
        if !submitted { return "Check answer" }
        if !answerIsCorrect { return "Try again" }
        let careEarned = DailyRewardLedger.lessonRewardAmount(lessonID)
        return careEarned > 0 ? "Complete lesson · +\(careEarned) care" : "Complete lesson"
    }

    private func lessonActionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(track.color, in: Capsule())
    }

}

private struct StatPill: View {
    let symbol: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text(label)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ConceptNode: View {
    let title: String
    let tint: Color
    let prominent: Bool
    var body: some View {
        Text(title).font(.system(size: prominent ? 11 : 9, weight: .semibold, design: .rounded))
            .foregroundStyle(prominent ? .white : Palette.ink)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(prominent ? tint : tint.opacity(0.11), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(prominent ? 0 : 0.25), lineWidth: 1))
    }
}

private struct FlashcardDeck: View {
    let words: [String]
    let track: LearningTrack
    @State private var index = 0
    @State private var revealed = false

    private var word: String { words[index] }
    private var accent: Color { Palette.keywordColors[index % Palette.keywordColors.count] }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FLASHCARDS").font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1).foregroundStyle(Palette.muted)
                Spacer()
                Text("\(index + 1) / \(words.count)").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(Palette.muted)
            }
            Button {
                withAnimation(.easeInOut(duration: 0.16)) { revealed.toggle() }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(revealed ? "DEFINITION" : "TERM")
                        .font(.system(size: 8, weight: .heavy, design: .rounded)).tracking(1)
                        .foregroundStyle(accent)
                    Text(word)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                        .underline(color: accent)
                    if revealed {
                        Text(termDefinition(word))
                            .font(.system(size: 13, design: .rounded)).lineSpacing(3)
                            .foregroundStyle(Palette.ink).multilineTextAlignment(.leading)
                    } else {
                        Text("What does this mean?")
                            .font(.system(size: 12, design: .rounded)).foregroundStyle(Palette.muted)
                    }
                    Spacer(minLength: 0)
                    HStack { Image(systemName: revealed ? "arrow.uturn.backward" : "arrow.triangle.2.circlepath"); Text(revealed ? "Recall the definition" : "Definition") }
                        .font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundStyle(accent.opacity(0.9))
                }
                .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
                .padding(15)
                .background(LinearGradient(colors: [.white, accent.opacity(0.11)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            HStack {
                Button { index = (index - 1 + words.count) % words.count; revealed = false } label: {
                    Label("Previous", systemImage: "chevron.left").labelStyle(.titleAndIcon)
                }.disabled(words.count < 2)
                Spacer()
                Button { index = (index + 1) % words.count; revealed = false } label: {
                    Label("Next", systemImage: "chevron.right").labelStyle(.titleAndIcon)
                }.disabled(words.count < 2)
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(track.color)
            .buttonStyle(.plain)
        }
    }

    private func termDefinition(_ term: String) -> String {
        let definitions: [String: String] = [
            "Anatomy": "The study of the structures of the body and how they relate to one another.",
            "Physiology": "The study of how body structures function.",
            "Cell": "The smallest living unit that carries out the processes needed for life.",
            "Tissue": "A group of similar cells working together to perform a function.",
            "Organ": "A structure made of multiple tissue types working together.",
            "Organ system": "A group of organs coordinating to perform major body functions.",
            "Homeostasis": "Regulation of internal conditions within ranges compatible with healthy function.",
            "Negative feedback": "A control process that counteracts a change and helps return a variable toward its regulated range.",
            "Set point": "A reference value or range used in a regulated process; it can shift with context and time.",
            "Regulation": "Processes that detect and respond to changes in the body.",
            "Mental health": "Emotional, psychological, and social well-being; it can change across a person’s life.",
            "Emotional well-being": "The emotional dimension of mental health, including feelings and how they are experienced.",
            "Psychological well-being": "The psychological dimension of mental health, including thought and mental functioning.",
            "Social well-being": "The social dimension of mental health, including relationships and social context.",
            "Biopsychosocial context": "A framework considering biological, psychological, and social influences together.",
            "Biological factors": "Body and brain processes that can influence health.",
            "Behavioral factors": "Actions and patterns that interact with health and circumstances.",
            "Social determinants": "Conditions in which people are born, grow, live, work, and age that shape health.",
            "Stress": "A physical and mental response to an external demand.",
            "Stress response": "Body and mind processes activated in response to a demand or challenge.",
            "Context": "The circumstances surrounding an experience or health finding.",
            "Body–mind connection": "The two-way ways physical processes and mental experiences can interact.",
            "Sleep": "A recurring biological state important to physical and mental functioning.",
            "Circadian rhythm": "Internal timing processes that organize daily patterns, including sleep and wakefulness.",
            "Attention": "The selection and maintenance of focus on information or tasks.",
            "Pattern": "A repeated observation across time; it still needs context to interpret.",
            "Anxiety": "A state of worry, nervousness, or fear that can be a normal response to stress.",
            "Threat response": "A set of mental and physical responses to perceived danger or challenge.",
            "Avoidance": "Moving away from a feared situation; persistent avoidance can interfere with daily activities.",
            "Functional impact": "The effect an experience has on daily activities and responsibilities.",
            "Depression": "A mental-health condition that can affect mood, interest, thinking, energy, sleep, and more.",
            "Mood": "A sustained emotional state that can vary over time.",
            "Anhedonia": "A reduced ability to feel interest or pleasure in activities.",
            "ADHD": "A neurodevelopmental disorder involving persistent inattention and/or hyperactivity-impulsivity that affects functioning.",
            "Executive function": "Mental processes that support planning, working memory, task switching, and self-regulation.",
            "Assessment": "A structured evaluation by a qualified professional using relevant history and criteria.",
            "Trauma": "An experience or series of experiences that can overwhelm a person’s ability to cope; responses differ.",
            "PTSD": "A condition that can develop after trauma exposure; not everyone exposed to trauma develops it.",
            "Safety": "Protection from immediate and ongoing harm, interpreted in a person’s context.",
            "Social support": "Practical, informational, or emotional help from other people and communities.",
            "Reproductive life stages": "Periods across life associated with reproductive development and transitions.",
            "Hormone transition": "A period when hormone levels or patterns change; individual experiences vary.",
            "PMDD": "Premenstrual dysphoric disorder, a diagnosis involving severe cyclical mood symptoms.",
            "Perinatal mental health": "Mental health during pregnancy and the period after birth.",
            "Study population": "The people included in a study; findings may not generalize beyond them.",
            "Sex": "A set of biological attributes used in research; its measures and relevance depend on the question.",
            "Gender": "Socially and culturally shaped identities, roles, and relations that can influence health.",
            "Evidence limits": "Constraints on what a study can establish, including design, sample, and uncertainty.",
            "Water": "The body’s main solvent; many cellular and physiological processes take place in aqueous fluids.",
            "Ion": "An atom or molecule with an electrical charge because it has gained or lost electrons.",
            "Electrolyte": "A substance that forms charged ions when dissolved in body fluids.",
            "pH": "A measure related to hydrogen-ion concentration that describes how acidic or basic a solution is.",
            "Cell membrane": "A selectively permeable boundary that separates a cell from its environment.",
            "Cytoplasm": "The cell’s internal material outside the nucleus, including cytosol and organelles.",
            "Organelle": "A specialized structure inside a cell that carries out particular functions.",
            "Nucleus": "A membrane-bound organelle that contains most of a cell’s DNA.",
            "Epithelial": "A tissue family that covers body surfaces, lines spaces, and forms many glands.",
            "Connective": "A diverse tissue family that supports, connects, protects, stores, and transports.",
            "Integumentary system": "Skin and its accessory structures, including hair, nails, and glands.",
            "Epidermis": "The outer epithelial layer of the skin.",
            "Dermis": "The connective-tissue layer beneath the epidermis.",
            "Hair follicle": "A skin structure from which a hair grows.",
            "Endocrine system": "Glands and cells that release hormones to coordinate body processes.",
            "Receptor": "A protein that binds a particular signal molecule and helps a cell respond to it.",
            "Target cell": "A cell that can respond to a signal, often because it has a compatible receptor.",
            "Ovary": "A gonad that can produce oocytes and reproductive hormones.",
            "Oocyte": "An immature egg cell that may complete development through meiosis.",
            "Uterine tube": "A tube through which an oocyte travels from the ovary toward the uterus.",
            "Uterus": "A muscular pelvic organ whose endometrium changes across the menstrual cycle.",
            "Ovarian cycle": "Follicular development, ovulation, and luteal activity in the ovary.",
            "Uterine cycle": "Cyclic changes in the endometrium, including menstrual, proliferative, and secretory phases.",
            "Ovulation": "Release of an oocyte from an ovarian follicle.",
            "Endometrium": "The inner lining of the uterus.",
            "Hypothalamus": "A brain region that helps regulate endocrine activity, including reproductive hormone signaling.",
            "FSH": "Follicle-stimulating hormone, released by the anterior pituitary and involved in follicular development.",
            "LH surge": "A sharp rise in luteinizing hormone that usually triggers ovulation.",
            "Progesterone": "A steroid hormone involved in the ovarian cycle and changes in the endometrium."
        ]
        return definitions[term] ?? "A key concept in this lesson. Explore the source to learn more."
    }
}

private struct TomorrowTeaserCard: View {
    let track: LearningTrack
    let nextLessonNumber: Int
    private var preview: String { String(track.explanation(at: nextLessonNumber).prefix(88)).trimmingCharacters(in: .whitespacesAndNewlines) + "…" }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "sunrise.fill").font(.system(size: 17)).foregroundStyle(Palette.gold)
            VStack(alignment: .leading, spacing: 4) {
                Text("TOMORROW").font(.system(size: 8, weight: .heavy, design: .rounded)).tracking(1).foregroundStyle(Palette.gold)
                Text(track.title(at: nextLessonNumber)).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                Text(preview).font(.system(size: 10, design: .rounded)).lineSpacing(2).foregroundStyle(Palette.muted)
            }
        }
        .padding(13).frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.peach.opacity(0.65), in: RoundedRectangle(cornerRadius: 15))
    }
}

private struct ChipmunkCompanionCard: View {
    @AppStorage("chipmunk.companion.name") private var companionName = "Chip"
    @AppStorage("chipmunk.dailyCare") private var careToday = 0
    @AppStorage("chipmunk.bestCareBadgeStreak") private var bestCareStreak = 0
    @AppStorage("chipmunk.completedLessonIDs") private var completedLessonIDs = ""
    @AppStorage("chipmunk.need.food") private var food = 55
    @AppStorage("chipmunk.need.water") private var water = 55
    @AppStorage("chipmunk.need.rest") private var rest = 55
    @AppStorage("chipmunk.need.strength") private var strength = 55
    @AppStorage("chipmunk.need.joy") private var joy = 55
    @AppStorage("chipmunk.companion.coat") private var coat = "Chestnut"

    private let coats: [(name: String, badgeDays: Int, color: Color)] = [
        ("Chestnut", 0, Palette.coral),
        ("Cream", 1, Color(red: 0.78, green: 0.65, blue: 0.43)),
        ("Silver", 3, Color(red: 0.46, green: 0.52, blue: 0.57)),
        ("Sage", 7, Color(red: 0.35, green: 0.52, blue: 0.42)),
        ("Cocoa", 14, Color(red: 0.42, green: 0.30, blue: 0.25))
    ]

    private var chipAge: Int {
        let lessons = completedLessonIDs.split(separator: ",").count
        return min(100, 16 + lessons / 10)
    }
    private var coatColor: Color { coats.first(where: { $0.name == coat })?.color ?? Palette.coral }
    private func coatUnlocked(_ option: (name: String, badgeDays: Int, color: Color)) -> Bool { bestCareStreak >= option.badgeDays }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                Text("🐿️")
                    .font(.system(size: 58))
                    .frame(width: 88, height: 88)
                    .background(coatColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(coatColor.opacity(0.7), lineWidth: 2))
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("YOUR CHIPMUNK")
                            .font(.system(size: 8, weight: .heavy, design: .rounded)).tracking(1).foregroundStyle(Palette.gold)
                        TextField("Name your chipmunk", text: $companionName)
                            .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .accessibilityLabel("Chipmunk name")
                    }
                    Text("Age · \(chipAge)/100")
                        .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                    Text("Daily care · \(careToday)/\(DailyRewardLedger.dailyCap)")
                        .font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
            }
            ProgressView(value: Double(min(careToday, DailyRewardLedger.dailyCap)), total: Double(DailyRewardLedger.dailyCap)).tint(coatColor)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(CompanionNeed.allCases) { need in
                    needRow(need)
                }
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("COMPANION ACCENTS").font(.system(size: 8, weight: .heavy, design: .rounded)).tracking(0.9).foregroundStyle(Palette.muted)
                    Spacer()
                    Text("Earn care badges to unlock").font(.system(size: 8, design: .rounded)).foregroundStyle(Palette.muted)
                }
                HStack(spacing: 8) {
                    ForEach(coats, id: \.name) { option in
                        Button {
                            guard coatUnlocked(option) else { return }
                            coat = option.name
                        } label: {
                            Circle().fill(option.color).frame(width: 25, height: 25)
                                .overlay(Circle().stroke(coat == option.name ? Palette.ink : .clear, lineWidth: 2).padding(-3))
                                .overlay {
                                    if !coatUnlocked(option) { Image(systemName: "lock.fill").font(.system(size: 8, weight: .bold)).foregroundStyle(.white) }
                                }
                                .frame(width: 34, height: 34)
                                .background(coat == option.name ? option.color.opacity(0.12) : .clear, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!coatUnlocked(option))
                        .accessibilityLabel(coatUnlocked(option) ? "Use \(option.name) companion accent" : "\(option.name) companion accent unlocks with the \(BadgeCatalog.all.first(where: { $0.wellnessDays == option.badgeDays })?.title ?? "care") badge")
                    }
                    Spacer()
                    Text(coat).font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundStyle(Palette.ink)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 20))
        .onAppear { DailyRewardLedger.beginDay() }
    }

    @ViewBuilder private func needRow(_ need: CompanionNeed) -> some View {
        let value: Int = switch need {
        case .food: food
        case .water: water
        case .rest: rest
        case .strength: strength
        case .joy: joy
        }
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: need.symbol).font(.system(size: 9, weight: .semibold)).foregroundStyle(need.tint)
                Text(need.title).font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundStyle(Palette.ink)
                Spacer(minLength: 0)
                Text("\(value)").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundStyle(Palette.muted)
            }
            ProgressView(value: Double(value), total: 100).tint(need.tint)
        }
        .padding(8).background(Palette.paper.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct CourseReviewQuizView: View {
    let track: LearningTrack
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chipmunk.dailyCare") private var dailyCare = 0
    @AppStorage("chipmunk.body.unitQuizComplete") private var bodyQuizComplete = false
    @AppStorage("chipmunk.mind.unitQuizComplete") private var mindQuizComplete = false
    @State private var questionIndex = 0
    @State private var selectedAnswer: String?
    @State private var submitted = false
    @State private var score = 0
    @State private var showingResult = false
    @State private var quizCareEarned = 0

    private var answer: String { track.answer(at: questionIndex + 1) }
    private var correct: Bool { selectedAnswer == answer }
    private var quizComplete: Bool {
        get { track == .body ? bodyQuizComplete : mindQuizComplete }
        set {
            if track == .body { bodyQuizComplete = newValue } else { mindQuizComplete = newValue }
        }
    }

    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            if showingResult {
                resultView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                Text(track == .body ? "UNIT 1 · BODY FOUNDATIONS" : "UNIT 1 · MIND & BODY").font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1).foregroundStyle(track.color)
                            Spacer()
                            Text("\(questionIndex + 1) / 10").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Palette.muted)
                        }
                        ProgressView(value: Double(questionIndex + 1), total: 10).tint(Palette.gold)
                        Text(track.title(at: questionIndex + 1).uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(0.9).foregroundStyle(Palette.keywordColors[questionIndex % Palette.keywordColors.count])
                        Text(track.prompt(at: questionIndex + 1))
                            .font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                        ForEach(track.options(at: questionIndex + 1), id: \.self) { option in
                            Button { if !submitted { selectedAnswer = option } } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: selectedAnswer == option ? "largecircle.fill.circle" : "circle")
                                        .foregroundStyle(selectedAnswer == option ? Palette.coral : Palette.muted)
                                    Text(option).font(.system(size: 14, design: .rounded)).multilineTextAlignment(.leading).foregroundStyle(Palette.ink)
                                    Spacer(minLength: 0)
                                }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedAnswer == option ? Palette.coral.opacity(0.6) : Palette.line, lineWidth: 1))
                            }.buttonStyle(.plain).disabled(submitted)
                        }
                        if submitted {
                            Text(correct ? "Correct: \(answer)" : "Review: \(answer)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(correct ? Color(red: 0.22, green: 0.42, blue: 0.34) : Palette.coral)
                            Link(track.sourceTitle(at: questionIndex + 1), destination: track.sourceURL(at: questionIndex + 1))
                                .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.muted)
                        }
                        Button(action: advance) {
                            Text(submitted ? (questionIndex == 9 ? "See results" : "Next question") : "Check answer")
                                .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14).background(Palette.coral, in: Capsule())
                        }.buttonStyle(.plain).disabled(selectedAnswer == nil && !submitted).opacity(selectedAnswer == nil && !submitted ? 0.45 : 1)
                    }.padding(22).frame(maxWidth: 560).frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Unit review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: score >= 8 ? "rosette" : "books.vertical.fill")
                .font(.system(size: 32)).foregroundStyle(Palette.gold)
            Text(score >= 8 ? "Unit mastered" : "Keep building your map")
                .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            Text("\(score) of 10 correct")
                .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(Palette.coral)
            if score >= 8 {
                Text(quizCareEarned > 0 ? "Unit complete · +\(quizCareEarned) care for Chip" : "Chip’s daily care meter is full.")
                    .font(.system(size: 13, design: .rounded)).foregroundStyle(Palette.muted)
            }
            Spacer()
            Button {
                if score >= 8 {
                    dismiss()
                } else {
                    restart()
                }
            } label: {
                Text(score >= 8 ? "Return to course" : "Review and try again")
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(Palette.coral, in: Capsule())
            }.buttonStyle(.plain)
        }.padding(22)
    }

    private func advance() {
        if !submitted {
            if correct { score += 1 }
            submitted = true
        } else if questionIndex == 9 {
            DailyRewardLedger.markStudyDay()
            if score >= 8 && !quizComplete {
                quizCareEarned = DailyRewardLedger.awardMastery()
                dailyCare = UserDefaults.standard.integer(forKey: "chipmunk.dailyCare")
                if track == .body { bodyQuizComplete = true } else { mindQuizComplete = true }
            }
            showingResult = true
        } else {
            questionIndex += 1
            selectedAnswer = nil
            submitted = false
        }
    }

    private func restart() {
        questionIndex = 0
        selectedAnswer = nil
        submitted = false
        score = 0
        showingResult = false
    }
}

private struct FlowKeywordList: View {
    let words: [String]
    let tint: Color
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 7) { ForEach(words, id: \.self) { ConceptNode(title: $0, tint: tint, prominent: false) } }
            VStack(alignment: .leading, spacing: 7) {
                ForEach(words, id: \.self) { word in
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(tint)
                        Text(word).font(.system(size: 12, weight: .semibold, design: .rounded)).underline(color: tint.opacity(0.7)).foregroundStyle(Palette.ink)
                    }
                }
            }
        }
    }
}

private struct LessonVisualCard: View {
    let track: LearningTrack
    let lessonNumber: Int
    let onActivityComplete: () -> Void
    @State private var visitedNodes: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if track == .body {
                bodyDiagram
                Text(bodyCaption).font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.muted)
            } else {
                MentalMediaExperience(lessonNumber: lessonNumber, onComplete: onActivityComplete)
            }
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [.white, Palette.peach.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 1))
    }

    private var bodyCaption: String {
        switch lessonNumber {
        case 1: "Cells form tissues, tissues form organs, and organs work together in systems."
        case 2: "Stimulus → sensor → control center → effector: a basic negative-feedback loop."
        case 3: "Water carries dissolved ions; acid–base balance is maintained within narrow ranges."
        case 4: "Membrane, cytoplasm, nucleus, and organelles each contribute to cell function."
        case 5: "Epithelial · connective · muscle · nervous: four broad tissue families."
        case 6: "The epidermis overlies the dermis; follicles and glands are associated structures."
        case 7: "Endocrine gland → hormone in blood → receptor-bearing target cell."
        case 8: "Ovaries · uterine tubes · uterus · cervix · vagina · vulva."
        case 9: "Ovarian events and endometrial changes are coordinated, but cycle timing varies."
        default: "Brain–pituitary signals and ovarian hormones coordinate reproductive physiology."
        }
    }

    private var bodyNodes: [(String, String)] {
        switch lessonNumber {
        case 1: [("Cell", "circle.hexagongrid.fill"), ("Tissue", "square.grid.3x3.fill"), ("Organ", "heart.fill"), ("System", "point.3.connected.trianglepath.dotted")]
        case 2: [("Stimulus", "waveform.path"), ("Sensor", "dot.radiowaves.left.and.right"), ("Control", "slider.horizontal.3"), ("Response", "arrow.uturn.backward")]
        case 3: [("Water", "drop.fill"), ("Ions", "plus.forwardslash.minus"), ("pH", "equal") , ("Cells", "circle.hexagongrid.fill")]
        case 4: [("Membrane", "circle"), ("Nucleus", "circle.inset.filled"), ("Organelles", "circle.grid.3x3.fill"), ("Cell", "circle.hexagongrid.fill")]
        case 5: [("Epithelial", "square.grid.3x3.fill"), ("Connective", "circle.grid.cross"), ("Muscle", "waveform.path.ecg"), ("Nervous", "point.3.connected.trianglepath.dotted")]
        case 6: [("Epidermis", "square.stack.3d.up.fill"), ("Dermis", "square.stack.3d.up"), ("Follicle", "line.3.horizontal.decrease.circle"), ("Hair", "wind")]
        case 7: [("Gland", "circle.grid.cross"), ("Hormone", "drop.fill"), ("Blood", "drop") , ("Target", "scope")]
        case 8: [("Ovary", "circle.fill"), ("Tube", "point.topleft.down.curvedto.point.bottomright.up") , ("Uterus", "figure.dress.line.vertical.figure"), ("Vulva", "circle.hexagongrid")]
        case 9: [("Follicular", "circle.lefthalf.filled"), ("Ovulation", "sparkle"), ("Luteal", "circle.righthalf.filled"), ("Menses", "drop.fill")]
        default: [("GnRH", "brain.head.profile"), ("FSH / LH", "arrow.right"), ("Ovary", "circle.fill"), ("Feedback", "arrow.uturn.backward")]
        }
    }

    private var bodyDiagram: some View {
        HStack(spacing: 7) {
            ForEach(Array(bodyNodes.enumerated()), id: \.offset) { index, node in
                Button {
                    visitedNodes.insert(index)
                    if visitedNodes.count == bodyNodes.count { onActivityComplete() }
                } label: {
                    diagramNode(node.0, icon: node.1, color: Palette.keywordColors[index % Palette.keywordColors.count], selected: visitedNodes.contains(index))
                }.buttonStyle(.plain)
                if index < bodyNodes.count - 1 { Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(Palette.muted) }
            }
        }.font(.system(size: 9, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity).padding(.vertical, 8)
    }
    private func diagramNode(_ title: String, icon: String, color: Color, selected: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: selected ? "checkmark.circle.fill" : icon).font(.system(size: 18)).foregroundStyle(color)
            Text(title).font(.system(size: 8, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
        }.frame(maxWidth: .infinity).padding(5).background(selected ? color.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MentalMediaExperience: View {
    let lessonNumber: Int
    let onComplete: () -> Void
    var body: some View {
        Group {
            switch lessonNumber {
            case 1: BreathMedia(onComplete: onComplete)
            case 2: FactorMapMedia(onComplete: onComplete)
            case 3: StressResponseMedia(onComplete: onComplete)
            case 4: SleepTimelineMedia(onComplete: onComplete)
            case 5: AnxietyContinuumMedia(onComplete: onComplete)
            case 6: DepressionLensMedia(onComplete: onComplete)
            case 7: AttentionSwitchMedia(onComplete: onComplete)
            case 8: SupportScenarioMedia(onComplete: onComplete)
            case 9: LifeStageTimelineMedia(onComplete: onComplete)
            default: EvidenceLensMedia(onComplete: onComplete)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BreathMedia: View {
    let onComplete: () -> Void
    @State private var active = false
    var body: some View {
        HStack(spacing: 13) {
            Circle().fill(Palette.sage.opacity(0.65)).frame(width: 58, height: 58)
                .overlay(Circle().stroke(Palette.coral.opacity(0.55), lineWidth: 2).padding(6))
                .scaleEffect(active ? 1.08 : 0.9)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: active)
            VStack(alignment: .leading, spacing: 5) {
                Text("Follow the visual rhythm").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                Text("Optional. Keep your breathing comfortable; stop if it feels unpleasant.").font(.system(size: 10, design: .rounded)).foregroundStyle(Palette.muted)
                Button(active ? "Pause" : "Start") {
                    if !active { onComplete() }
                    active.toggle()
                }.font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Palette.coral)
            }
        }
    }
}

private struct FactorMapMedia: View {
    let onComplete: () -> Void
    @State private var selected: Set<String> = []
    private let factors = [("Biology", "heart.text.square"), ("Thoughts & behavior", "brain.head.profile"), ("Relationships", "person.2"), ("Environment", "globe.americas")]
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Tap the parts that can shape well-being").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                ForEach(factors, id: \.0) { factor in
                    Button { if selected.contains(factor.0) { selected.remove(factor.0) } else { selected.insert(factor.0) }; onComplete() } label: {
                        Label(factor.0, systemImage: factor.1).font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(selected.contains(factor.0) ? .white : Palette.ink).frame(maxWidth: .infinity).padding(9)
                            .background(selected.contains(factor.0) ? Palette.coral : Palette.paper, in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                }
            }
            Text("These factors interact; no single tile explains a whole person.").font(.system(size: 9, design: .rounded)).foregroundStyle(Palette.muted)
        }
    }
}

private struct StressResponseMedia: View {
    let onComplete: () -> Void
    @State private var revealed = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trace one possible response pathway").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            HStack(spacing: 5) {
                mediaStep("Demand", "bolt.fill")
                Image(systemName: "arrow.right").foregroundStyle(Palette.gold)
                mediaStep("Body & mind respond", "waveform.path.ecg")
                Image(systemName: "arrow.right").foregroundStyle(Palette.gold)
                mediaStep("Recovery / support", "leaf")
            }
            Button(revealed ? "Hide the explanation" : "Reveal the explanation") { revealed.toggle(); onComplete() }.font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(Palette.coral)
            if revealed { Text("This is a simplified teaching model; real stress responses vary and are influenced by circumstances and available support.").font(.system(size: 10, design: .rounded)).foregroundStyle(Palette.muted) }
        }
    }
    private func mediaStep(_ title: String, _ icon: String) -> some View {
        VStack(spacing: 4) { Image(systemName: icon).foregroundStyle(Palette.coral); Text(title).font(.system(size: 8, weight: .semibold, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(Palette.ink) }.frame(maxWidth: .infinity).padding(7).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct SleepTimelineMedia: View {
    let onComplete: () -> Void
    @State private var selection = "Light"
    private let moments = ["Light", "Wind-down", "Sleep", "Wake"]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explore a 24-hour rhythm").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            HStack(spacing: 5) {
                ForEach(moments, id: \.self) { item in
                    Button { selection = item; onComplete() } label: {
                        Text(item).font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundStyle(selection == item ? .white : Palette.ink).frame(maxWidth: .infinity).padding(8).background(selection == item ? Palette.coral : Palette.paper, in: Capsule())
                    }.buttonStyle(.plain)
                }
            }
            Text("Daily timing cues are one part of sleep biology; health, schedule, age, and environment also matter.").font(.system(size: 9, design: .rounded)).foregroundStyle(Palette.muted)
        }
    }
}

private struct AnxietyContinuumMedia: View {
    let onComplete: () -> Void
    @State private var amount = 0.45
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Model: a normal alarm can rise and settle").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            Slider(value: $amount).tint(Palette.coral).onChange(of: amount) { _, _ in onComplete() }
            HStack { Text("Settled"); Spacer(); Text("Activated") }.font(.system(size: 9, design: .rounded)).foregroundStyle(Palette.muted)
            Text("Move the model slider. It does not measure your anxiety or screen for a condition.").font(.system(size: 9, design: .rounded)).foregroundStyle(Palette.muted)
        }
    }
}

private struct DepressionLensMedia: View {
    let onComplete: () -> Void
    @State private var shown: Set<String> = []
    private let lenses = [("Biology", "Body and brain systems are part of a complex picture."), ("Experience", "Psychological and life circumstances may also contribute."), ("Support", "Care decisions belong with the person and qualified professionals.")]
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Turn over the evidence lenses").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            HStack(spacing: 6) {
                ForEach(lenses, id: \.0) { item in
                    Button { if shown.contains(item.0) { shown.remove(item.0) } else { shown.insert(item.0) }; onComplete() } label: {
                        VStack(spacing: 5) { Text(shown.contains(item.0) ? item.1 : item.0).font(.system(size: 9, weight: .semibold, design: .rounded)).multilineTextAlignment(.center).foregroundStyle(Palette.ink) }.frame(maxWidth: .infinity, minHeight: 52).padding(5).background(Palette.peach.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                }
            }
            Text("Tap each card. There is no one cause or one symptom that explains every person.").font(.system(size: 9, design: .rounded)).foregroundStyle(Palette.muted)
        }
    }
}

private struct AttentionSwitchMedia: View {
    let onComplete: () -> Void
    @State private var taps = 0
    @State private var target = "diamond"
    private let sequence = ["circle", "diamond", "diamond", "circle", "diamond", "circle"]
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Mini-game: switch the rule").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            Text("Tap the ◆ diamond. After three turns, switch and tap the ○ circle.").font(.system(size: 10, design: .rounded)).foregroundStyle(Palette.muted)
            HStack {
                ForEach(["circle", "diamond"], id: \.self) { shape in
                    Button {
                        if shape == sequence[min(taps, sequence.count - 1)] {
                            taps += 1
                            onComplete()
                            if taps == 3 { target = "circle" }
                            if taps >= sequence.count { taps = 0; target = "diamond" }
                        }
                    } label: {
                        Image(systemName: shape == "circle" ? "circle.fill" : "diamond.fill").font(.system(size: 25)).foregroundStyle(shape == target ? Palette.coral : Palette.gold).frame(maxWidth: .infinity).padding(9).background(.white, in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                }
            }
            Text("Moves: \(taps) / 6 · This is a game, not an ADHD test. Focus varies with task and context.").font(.system(size: 9, design: .rounded)).foregroundStyle(Palette.muted)
        }
    }
}

private struct SupportScenarioMedia: View {
    let onComplete: () -> Void
    @State private var choice: String?
    private let answer = "Listen, ask what support they want, and respect their choices."
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Scenario: a friend shares a difficult experience").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            ForEach([answer, "Demand details so you can decide how serious it was."], id: \.self) { option in
                Button { choice = option; onComplete() } label: { Text(option).font(.system(size: 10, design: .rounded)).multilineTextAlignment(.leading).foregroundStyle(Palette.ink).frame(maxWidth: .infinity, alignment: .leading).padding(9).background(choice == option ? Palette.sage.opacity(0.55) : .white, in: RoundedRectangle(cornerRadius: 9)) }.buttonStyle(.plain)
            }
            if choice != nil { Text(choice == answer ? "Support respects safety and autonomy." : "Try a response that centers the person’s choice and safety.").font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(Palette.muted) }
        }
    }
}

private struct LifeStageTimelineMedia: View {
    let onComplete: () -> Void
    @State private var selection = "Cycle"
    private let stages = ["Puberty", "Cycle", "Pregnancy", "Menopause"]
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Tap a life stage to explore the research lens").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            HStack(spacing: 4) { ForEach(stages, id: \.self) { stage in
                Button { selection = stage; onComplete() } label: { Text(stage).font(.system(size: 8, weight: .semibold, design: .rounded)).foregroundStyle(selection == stage ? .white : Palette.ink).frame(maxWidth: .infinity).padding(7).background(selection == stage ? Palette.coral : Palette.paper, in: Capsule()) }.buttonStyle(.plain)
            } }
            Text("Researchers study mental health across life stages; effects and evidence differ, and a stage alone does not explain an individual’s experience.").font(.system(size: 9, design: .rounded)).foregroundStyle(Palette.muted)
        }
    }
}

private struct EvidenceLensMedia: View {
    let onComplete: () -> Void
    @State private var choice: String?
    private let strongest = "Names who was studied and what remains uncertain."
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Choose the more careful research summary").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            ForEach([strongest, "One study proves this applies to all women."], id: \.self) { statement in
                Button { choice = statement; onComplete() } label: { Text(statement).font(.system(size: 10, design: .rounded)).multilineTextAlignment(.leading).foregroundStyle(Palette.ink).frame(maxWidth: .infinity, alignment: .leading).padding(9).background(choice == statement ? Palette.sage.opacity(0.55) : .white, in: RoundedRectangle(cornerRadius: 9)) }.buttonStyle(.plain)
            }
            if choice != nil { Text(choice == strongest ? "Good evidence reports the study population and limits." : "Health findings need context; study results may not generalize to everyone.").font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(Palette.muted) }
        }
    }
}

private struct PlacementQuestion {
    let prompt: String
    let options: [String]
    let answer: String
}

private struct PlacementQuizView: View {
    let track: LearningTrack
    let onStart: () -> Void

    @AppStorage("chipmunk.placementPassedTrack") private var placementPassedTrack = ""
    @Environment(\.dismiss) private var dismiss
    @State private var questionIndex = 0
    @State private var selectedAnswer: String?
    @State private var score = 0
    @State private var showingResult = false

    private var questions: [PlacementQuestion] {
        switch track {
        case .body:
            [
                PlacementQuestion(prompt: "Which sequence moves from smaller structures to larger ones?", options: ["Cell → tissue → organ → organ system", "Organ → tissue → cell → organ system", "Tissue → cell → organ system → organ"], answer: "Cell → tissue → organ → organ system"),
                PlacementQuestion(prompt: "What is homeostasis?", options: ["The body regulating internal conditions within ranges", "The body stopping all change", "A name for one organ system"], answer: "The body regulating internal conditions within ranges")
            ]
        case .mind:
            [
                PlacementQuestion(prompt: "NIMH describes mental health as including…", options: ["Emotional, psychological, and social well-being", "Mood only", "Whether someone has a diagnosis"], answer: "Emotional, psychological, and social well-being"),
                PlacementQuestion(prompt: "A women-centered mental health course should…", options: ["Consider biological and social context together", "Assume one factor explains everyone", "Treat one symptom as a diagnosis"], answer: "Consider biological and social context together")
            ]
        }
    }

    private var passed: Bool { score == questions.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.paper.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("OPTIONAL PLACEMENT")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(track.color)
                            Spacer()
                            Text("\(min(questionIndex + 1, questions.count)) / \(questions.count)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.muted)
                        }

                        if showingResult {
                            resultContent
                        } else {
                            Text(questions[questionIndex].prompt)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)

                            ForEach(questions[questionIndex].options, id: \.self) { option in
                                Button {
                                    selectedAnswer = option
                                } label: {
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: selectedAnswer == option ? "largecircle.fill.circle" : "circle")
                                            .foregroundStyle(selectedAnswer == option ? track.color : Palette.muted)
                                            .padding(.top, 2)
                                        Text(option)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .multilineTextAlignment(.leading)
                                            .foregroundStyle(Palette.ink)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(13)
                                    .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.line, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }

                            Button(action: submitAnswer) {
                                Text(questionIndex == questions.count - 1 ? "See my starting point" : "Check answer")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(track.color, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedAnswer == nil)
                            .opacity(selectedAnswer == nil ? 0.45 : 1)
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Choose your starting point")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Palette.coral)
                }
            }
        }
    }

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: passed ? "sparkles" : "book.closed")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Palette.gold)
            Text(passed ? "You know these foundations." : "Let’s build from the basics.")
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.ink)
            Text(passed ? "We’ll start you with lesson two. Lesson one stays available to review." : "We’ll start at lesson one and build each idea in order.")
                .font(.system(size: 14, design: .rounded))
                .lineSpacing(4)
                .foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
            Button {
                placementPassedTrack = passed ? track.rawValue : ""
                onStart()
            } label: {
                Text("Start learning")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(track.color, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func submitAnswer() {
        guard let selected = selectedAnswer else { return }
        if selected == questions[questionIndex].answer { score += 1 }
        selectedAnswer = nil
        if questionIndex == questions.count - 1 {
            showingResult = true
        } else {
            questionIndex += 1
        }
    }
}

struct RootView: View {
    @AppStorage("chipmunk.selectedTrack") private var selectedTrackRaw = ""

    var body: some View {
        Group {
            if let track = LearningTrack(rawValue: selectedTrackRaw) {
                LearningAppShell(track: track) {
                    selectedTrackRaw = ""
                }
            } else {
                TrackPickerView { track in
                    selectedTrackRaw = track.rawValue
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTrackRaw)
    }
}

private struct LearningAppShell: View {
    let track: LearningTrack
    let onSwitchTrack: () -> Void
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            NavigationStack {
                LearningPathView(track: track, onSwitchTrack: onSwitchTrack)
            }
            .tabItem { Label("Learn", systemImage: "map") }

            NavigationStack {
                ReferenceLibraryView()
            }
            .tabItem { Label("Library", systemImage: "books.vertical") }

            NavigationStack {
                RewardCollectionView()
            }
            .tabItem { Label("Collection", systemImage: "rosette") }
        }
        .tint(Palette.coral)
        .onAppear { DailyRewardLedger.beginDay() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { DailyRewardLedger.beginDay() }
        }
    }
}

private struct RewardCollectionView: View {
    @AppStorage("chipmunk.bestCareBadgeStreak") private var bestCareStreak = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CHIP’S CARE BADGES").font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.2).foregroundStyle(Palette.gold)
                            Text(BadgeCatalog.highestEarned(bestStreak: bestCareStreak)?.title ?? "Your first badge is ahead")
                                .font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                        }
                        Spacer()
                        Image(systemName: "rosette").font(.system(size: 39, weight: .regular)).foregroundStyle(Palette.gold)
                    }
                    Text(BadgeCatalog.next(bestStreak: bestCareStreak)?.detail ?? "You’ve earned every care-streak badge.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Palette.muted)
                }
                .padding(18).background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 20))

                ChipmunkCompanionCard()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(BadgeCatalog.all) { badge in
                        BadgeCollectionCard(badge: badge, earned: badge.earned(bestStreak: bestCareStreak))
                    }
                }
            }
            .padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(Palette.paper)
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Collection")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }
        }
        .onAppear { DailyRewardLedger.beginDay() }
    }
}

private struct BadgeCollectionCard: View {
    let badge: CareBadge
    let earned: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: earned ? badge.symbol : "lock.fill")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(earned ? Palette.gold : Palette.muted.opacity(0.65))
                .frame(width: 38, height: 38)
                .background(earned ? Palette.gold.opacity(0.12) : Palette.line.opacity(0.35), in: Circle())
            Text(badge.title).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(earned ? Palette.ink : Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text(badge.detail).font(.system(size: 9, design: .rounded)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text(earned ? "EARNED" : "LOCKED").font(.system(size: 7, weight: .heavy, design: .rounded)).tracking(0.8).foregroundStyle(earned ? Palette.gold : Palette.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .padding(11)
        .background(earned ? .white : .white.opacity(0.52), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(earned ? Palette.gold.opacity(0.3) : Palette.line, lineWidth: 1))
    }
}

private struct ReferenceLibraryView: View {
    @AppStorage("chipmunk.completedLessonIDs") private var completedLessonIDs = ""

    private var completedIDs: Set<String> {
        Set(completedLessonIDs.split(separator: ",").map(String.init))
    }

    var body: some View {
        List {
            Section {
                Text("Definitions and diagrams from both courses, connected by the ideas they share.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Palette.muted)
                    .listRowBackground(Color.white)
            }

            Section {
                NavigationLink {
                    ReflectionNotesView()
                } label: {
                    Label("Notes & reflection", systemImage: "square.and.pencil")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                }
                .listRowBackground(Color.white)
            } header: {
                Text("MY NOTES").foregroundStyle(Palette.ink)
            }

            ForEach(LearningTrack.allCases) { track in
                Section {
                    let secondUnlocked = completedIDs.contains("\(track.rawValue).02")
                    DisclosureGroup {
                        ConceptMapDetail(track: track, lessonNumber: 1)
                        Link(track.sourceTitle, destination: track.sourceURL)
                            .font(.system(size: 11, design: .rounded))
                    } label: {
                        LibraryKeywordRow(lesson: track.firstLesson, words: track.keywords(for: 1), tint: track.color)
                    }
                    .listRowBackground(Color.white)
                    if secondUnlocked {
                        DisclosureGroup {
                            ConceptMapDetail(track: track, lessonNumber: 2)
                            Link(track.secondSourceTitle, destination: track.secondSourceURL)
                                .font(.system(size: 11, design: .rounded))
                        } label: {
                            LibraryKeywordRow(lesson: track.secondLesson, words: track.keywords(for: 2), tint: track.color)
                        }
                        .listRowBackground(Color.white)
                    }
                    ForEach(3...10, id: \.self) { lessonNumber in
                            if completedIDs.contains("\(track.rawValue).\(String(format: "%02d", lessonNumber))") {
                                DisclosureGroup {
                                    ConceptMapDetail(track: track, lessonNumber: lessonNumber)
                                    Link(track.sourceTitle(at: lessonNumber), destination: track.sourceURL(at: lessonNumber))
                                        .font(.system(size: 11, design: .rounded))
                                } label: {
                                    LibraryKeywordRow(lesson: track.title(at: lessonNumber), words: track.keywords(for: lessonNumber), tint: track.color)
                                }
                                .listRowBackground(Color.white)
                            }
                    }
                }
                header: {
                    Text(track.rawValue.uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(track.color)
                }
            }

        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.paper)
        .navigationTitle("Reference library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Reference library")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }
        }
    }
}

private struct LibraryKeywordRow: View {
    let lesson: String
    let words: [String]
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(words.joined(separator: " · ")).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(tint)
            Text(lesson).font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.ink.opacity(0.72))
        }.padding(.vertical, 3)
    }
}

private struct ConceptMapDetail: View {
    let track: LearningTrack
    let lessonNumber: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                ConceptNode(title: track.keywords(for: lessonNumber)[0], tint: track.color, prominent: true)
                Image(systemName: "arrow.right").foregroundStyle(Palette.gold)
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(track.keywords(for: lessonNumber).dropFirst()), id: \.self) { word in
                        HStack(spacing: 6) {
                            Rectangle().fill(track.color.opacity(0.35)).frame(width: 14, height: 1)
                            ConceptNode(title: word, tint: track.color, prominent: false)
                        }
                    }
                }
            }
            Text("Tap the next unlocked lesson to add new branches to your map.")
                .font(.system(size: 10, design: .rounded)).foregroundStyle(Palette.muted)
        }.padding(.vertical, 7)
    }
}

private struct ReflectionNotesView: View {
    @AppStorage("chipmunk.reflectionNote") private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A private space to connect ideas to your own life. Reflection is optional and isn’t a symptom check or diagnosis.")
                .font(.system(size: 14, design: .rounded))
                .lineSpacing(4)
                .foregroundStyle(Palette.muted)

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("What would you like to remember from a lesson?")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Palette.muted.opacity(0.75))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $note)
                    .font(.system(size: 15, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .padding(6)
            }
            .frame(minHeight: 220)
            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(Palette.line, lineWidth: 1))

            Label("Saved on this device", systemImage: "lock.fill")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.muted)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle("Notes & reflection")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ChallengePreviewView: View {
    @AppStorage("chipmunk.challengeInterest") private var interested = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Learn alongside others, while keeping your health activity private.")
                    .font(.system(size: 15, design: .rounded))
                    .lineSpacing(4)
                    .foregroundStyle(Palette.muted)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Palette.gold)
                        Text("5-DAY LEARNING CHALLENGE")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(Palette.ink)
                    }
                    Text("Build a small learning rhythm")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text("A future anonymous group challenge can count lesson days without sharing which health topics anyone studies.")
                        .font(.system(size: 13, design: .rounded))
                        .lineSpacing(4)
                        .foregroundStyle(Palette.muted)

                    Button {
                        interested.toggle()
                    } label: {
                        Text(interested ? "Interest saved on this device" : "I’m interested")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Palette.coral, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(19)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.line, lineWidth: 1))

                Text("Group challenges need a shared service; this preview only saves your interest locally.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Palette.muted)
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.paper)
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RootView()
}
