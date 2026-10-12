import Foundation

enum UserRole: String, CaseIterable, Codable {
    case parent
    case guide
    case visitor

    var title: String {
        switch self {
        case .parent: return "家长"
        case .guide: return "前沿引路人"
        case .visitor: return "游客"
        }
    }

    var subtitle: String {
        switch self {
        case .parent: return "为孩子寻找可信的前沿引路人"
        case .guide: return "分享真实行业经验与前沿知识"
        case .visitor: return "暂不登录，先看看课程与引路人"
        }
    }

    var symbol: String {
        switch self {
        case .parent: return "figure.and.child.holdinghands"
        case .guide: return "sparkles"
        case .visitor: return "eyes"
        }
    }
}

enum CourseStatus: String, Codable {
    case available = "可报名"
    case soon = "即将开始"
    case full = "已满员"
}

struct Lesson: Codable {
    let title: String
    let detail: String
    let time: String
}

struct Course: Hashable, Codable {
    let id: String
    let title: String
    let instructor: String
    let instructorRole: String
    let duration: String
    let schedule: String
    let age: String
    let format: String
    let category: String
    let status: CourseStatus
    let artSymbol: String
    let colors: [UInt32]
    let summary: String
    let outcomes: [String]
    let lessons: [Lesson]

    static func == (lhs: Course, rhs: Course) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct FrontierProject: Hashable, Codable {
    let id: String
    let title: String
    let guide: String
    let guideRole: String
    let category: String
    let age: String
    let duration: String
    let format: String
    let city: String
    let schedule: String
    let status: String
    let symbol: String
    let colors: [UInt32]
    let summary: String
    let highlights: [String]
}

enum NeedStatus: String, Codable {
    case pending = "已收到需求"
    case matching = "正在筛选合适引路人"
    case recommended = "已为你找到推荐方案"
    case confirmed = "预约已确认"
}

struct ParentNeed: Hashable, Codable {
    let id: String
    var title: String
    let anonymousName: String
    let age: String
    let city: String
    let interests: [String]
    let foundation: String
    let goal: String
    let format: String
    let schedule: String
    let budget: String
    let scope: String
    var status: NeedStatus
    let createdAt: String
}

struct GuideProfile: Codable {
    let name: String
    let role: String
    let city: String
    let bio: String
    let avatarSymbol: String
    let tags: [String]
    let verification: [String]
    let courses: Int
    let participants: Int
    let reviews: Int
    let rating: Double
}

extension Notification.Name {
    static let appStateDidChange = Notification.Name("frontierStar.appStateDidChange")
    static let roleDidChange = Notification.Name("frontierStar.roleDidChange")
}

final class AppStore {
    static let shared = AppStore()

    private let defaults = UserDefaults.standard
    var hasSelectedRole: Bool { defaults.bool(forKey: "hasSelectedRole") }
    var isLoggedIn: Bool { defaults.bool(forKey: "isLoggedIn") }
    var verifiedPhone: String? { defaults.string(forKey: "verifiedPhone") }
    var activeRole: UserRole {
        get { UserRole(rawValue: defaults.string(forKey: "activeRole") ?? "visitor") ?? .visitor }
        set {
            defaults.set(newValue.rawValue, forKey: "activeRole")
            defaults.set(true, forKey: "hasSelectedRole")
            NotificationCenter.default.post(name: .roleDidChange, object: nil)
        }
    }

    private(set) var enrolledCourseIDs: Set<String>
    private(set) var favoriteCourseIDs: Set<String>
    private(set) var appliedProjectIDs: Set<String>
    private(set) var readMessageIDs: Set<String>
    private(set) var reviewedCourseIDs: Set<String>
    private(set) var interestedNeedIDs: Set<String>
    private(set) var needs: [ParentNeed]
    private(set) var submittedProjects: [FrontierProject]

    /// The public discovery catalog must never expose a guide's locally submitted
    /// project while it is still awaiting platform review. Guides can still see
    /// those projects from their own workspace.
    var discoverableProjects: [FrontierProject] {
        activeRole == .guide ? submittedProjects + projects : projects
    }

    private init() {
        enrolledCourseIDs = Set(defaults.stringArray(forKey: "enrolledCourseIDs") ?? [])
        favoriteCourseIDs = Set(defaults.stringArray(forKey: "favoriteCourseIDs") ?? [])
        appliedProjectIDs = Set(defaults.stringArray(forKey: "appliedProjectIDs") ?? [])
        readMessageIDs = Set(defaults.stringArray(forKey: "readMessageIDs") ?? [])
        reviewedCourseIDs = Set(defaults.stringArray(forKey: "reviewedCourseIDs") ?? [])
        interestedNeedIDs = Set(defaults.stringArray(forKey: "interestedNeedIDs") ?? [])
        let defaultNeeds = [
            ParentNeed(
                id: "N20260729021",
                title: "为 12 岁有基础孩子寻找 AI 项目引路人",
                anonymousName: "北京家长 0321",
                age: "12 岁",
                city: "北京",
                interests: ["AI", "机器人", "动手制作"],
                foundation: "接触过 Scratch，完成过简单小车项目",
                goal: "希望通过 4–6 周项目判断孩子是否愿意继续深入",
                format: "线下小组",
                schedule: "周末下午",
                budget: "¥2,000–4,000",
                scope: "向已认证引路人展示",
                status: .recommended,
                createdAt: "今天 09:42"
            )
        ]
        needs = Self.decode([ParentNeed].self, from: defaults, key: "parentNeeds") ?? defaultNeeds
        submittedProjects = Self.decode([FrontierProject].self, from: defaults, key: "submittedProjects") ?? []
    }

    func choose(role: UserRole) {
        activeRole = role
    }

    func login(phone: String? = nil) {
        defaults.set(true, forKey: "isLoggedIn")
        if let phone { defaults.set(phone, forKey: "verifiedPhone") }
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func logout() {
        defaults.set(false, forKey: "isLoggedIn")
        defaults.removeObject(forKey: "verifiedPhone")
        defaults.set(false, forKey: "hasSelectedRole")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func enroll(_ course: Course) {
        guard !enrolledCourseIDs.contains(course.id) else { return }
        enrolledCourseIDs.insert(course.id)
        defaults.set(Array(enrolledCourseIDs), forKey: "enrolledCourseIDs")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func toggleFavorite(_ course: Course) {
        if favoriteCourseIDs.contains(course.id) { favoriteCourseIDs.remove(course.id) }
        else { favoriteCourseIDs.insert(course.id) }
        defaults.set(Array(favoriteCourseIDs), forKey: "favoriteCourseIDs")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func addNeed(_ need: ParentNeed) {
        needs.insert(need, at: 0)
        persist(needs, key: "parentNeeds")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func addProject(_ project: FrontierProject) {
        submittedProjects.insert(project, at: 0)
        persist(submittedProjects, key: "submittedProjects")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func apply(to project: FrontierProject) {
        guard !appliedProjectIDs.contains(project.id) else { return }
        appliedProjectIDs.insert(project.id)
        defaults.set(Array(appliedProjectIDs), forKey: "appliedProjectIDs")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func markMessageRead(_ id: String) {
        guard !readMessageIDs.contains(id) else { return }
        readMessageIDs.insert(id)
        defaults.set(Array(readMessageIDs), forKey: "readMessageIDs")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func submitReview(courseID: String, rating: Int, comment: String) {
        reviewedCourseIDs.insert(courseID)
        defaults.set(Array(reviewedCourseIDs), forKey: "reviewedCourseIDs")
        defaults.set(["rating": rating, "comment": comment], forKey: "review.\(courseID)")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func expressInterest(in need: ParentNeed) {
        guard !interestedNeedIDs.contains(need.id) else { return }
        interestedNeedIDs.insert(need.id)
        defaults.set(Array(interestedNeedIDs), forKey: "interestedNeedIDs")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func review(courseID: String) -> (rating: Int, comment: String)? {
        guard let value = defaults.dictionary(forKey: "review.\(courseID)"),
              let rating = value["rating"] as? Int,
              let comment = value["comment"] as? String else { return nil }
        return (rating, comment)
    }

    func setting(_ key: String, default defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: "setting.\(key)") != nil else { return defaultValue }
        return defaults.bool(forKey: "setting.\(key)")
    }

    func setSetting(_ value: Bool, key: String) {
        defaults.set(value, forKey: "setting.\(key)")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func profileText(_ key: String, default defaultValue: String) -> String {
        defaults.string(forKey: "guideProfile.\(key)") ?? defaultValue
    }

    func setProfileText(_ value: String, key: String) {
        defaults.set(value, forKey: "guideProfile.\(key)")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    var currentGuideProfile: GuideProfile {
        let base = guides["林昊"]!
        return GuideProfile(
            name: base.name,
            role: profileText("role", default: base.role),
            city: profileText("city", default: base.city),
            bio: profileText("bio", default: base.bio),
            avatarSymbol: base.avatarSymbol,
            tags: base.tags,
            verification: base.verification,
            courses: base.courses,
            participants: base.participants,
            reviews: base.reviews,
            rating: base.rating
        )
    }

    func guideApplicationStep(_ step: Int) -> [String: String] {
        defaults.dictionary(forKey: "guideApplication.step.\(step)") as? [String: String] ?? [:]
    }

    func saveGuideApplicationStep(_ step: Int, main: String, note: String) {
        defaults.set(["main": main, "note": note], forKey: "guideApplication.step.\(step)")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func projectDraft() -> [String: String] {
        defaults.dictionary(forKey: "projectDraft") as? [String: String] ?? [:]
    }

    func saveProjectDraft(_ draft: [String: String]) {
        defaults.set(draft, forKey: "projectDraft")
        NotificationCenter.default.post(name: .appStateDidChange, object: nil)
    }

    func clearProjectDraft() {
        defaults.removeObject(forKey: "projectDraft")
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    let courses: [Course] = [
        Course(
            id: "course-ai-lab", title: "AI 大模型\n创造力实验室", instructor: "林昊", instructorRole: "AI 产品专家",
            duration: "4 周 · 共 8 次", schedule: "每周六、周日 14:00–16:00", age: "10–13 岁", format: "北京线下",
            category: "AI 与大模型", status: .available, artSymbol: "wand.and.stars", colors: [0x12152F, 0x6246EA, 0xFF7A90],
            summary: "不是教孩子使用一个工具，而是和真正做 AI 产品的人一起，把一个好奇的问题变成可以演示的小作品。",
            outcomes: ["理解大模型能做什么、不能做什么", "掌握安全、清晰地与 AI 协作", "完成一个属于自己的 AI 创意项目"],
            lessons: [Lesson(title: "认识大模型与安全使用", detail: "从生活中的 AI 开始，建立正确认知", time: "8 月 8 日 14:00"), Lesson(title: "从问题到提示词", detail: "把模糊想法变成可执行步骤", time: "8 月 9 日 14:00"), Lesson(title: "制作第一个 AI 小项目", detail: "完成原型并进行分享", time: "8 月 15 日 14:00")]
        ),
        Course(
            id: "course-robot", title: "让机器人\n学会看见", instructor: "周岑", instructorRole: "机器视觉工程师",
            duration: "3 周 · 共 6 次", schedule: "每周六 09:30–11:30", age: "12–15 岁", format: "上海线下",
            category: "机器人", status: .soon, artSymbol: "camera.metering.center.weighted", colors: [0x0A2431, 0x087F8C, 0xF5B642],
            summary: "从摄像头、颜色与距离出发，让孩子亲手搭建一套可以识别和响应环境的机器人视觉系统。",
            outcomes: ["理解感知、决策和执行的关系", "接触真实机器视觉工作流", "小组完成循迹与识别挑战"],
            lessons: [Lesson(title: "机器人如何看见", detail: "认识镜头、像素与传感器", time: "8 月 16 日 09:30"), Lesson(title: "颜色与目标识别", detail: "让机器找到正确物体", time: "8 月 23 日 09:30"), Lesson(title: "完成视觉挑战", detail: "调试并复盘机器人的判断", time: "8 月 30 日 09:30")]
        ),
        Course(
            id: "course-drone", title: "无人机航拍\n与飞行科学", instructor: "顾燃", instructorRole: "无人机系统设计师",
            duration: "单次 · 150 分钟", schedule: "8 月 23 日 周日 09:00–11:30", age: "9–14 岁", format: "深圳户外",
            category: "无人机", status: .available, artSymbol: "airplane", colors: [0x17233F, 0x3C79F5, 0xA7E8FF],
            summary: "一次兼顾飞行原理、操控体验与安全意识的户外科技体验，监护人全程可见。",
            outcomes: ["理解升力、姿态与航向", "完成基础飞行和构图任务", "认识无人机在真实行业中的应用"],
            lessons: [Lesson(title: "飞行安全说明", detail: "场地、设备与应急规则", time: "09:00"), Lesson(title: "基础操控训练", detail: "起降、悬停与航向", time: "09:30"), Lesson(title: "航拍任务", detail: "完成一段安全的主题镜头", time: "10:30")]
        ),
        Course(
            id: "course-hardware", title: "为房间做一个\n环境感知器", instructor: "唐琳", instructorRole: "智能硬件产品设计师",
            duration: "2 周 · 共 4 次", schedule: "每周日 14:00–16:30", age: "10–14 岁", format: "在线小组",
            category: "智能硬件", status: .available, artSymbol: "sensor.tag.radiowaves.forward", colors: [0x26123D, 0x9A4DCC, 0xFFB36B],
            summary: "把温度、光线和空气变成可读的数据，经历从传感器接线到产品外观的完整小项目。",
            outcomes: ["认识常见传感器与数据", "完成简单硬件连接与调试", "理解产品功能与使用场景"],
            lessons: [Lesson(title: "认识环境数据", detail: "从房间里的问题开始", time: "8 月 9 日 14:00"), Lesson(title: "传感器动手实验", detail: "读取温度与光线", time: "8 月 16 日 14:00"), Lesson(title: "作品展示", detail: "讲清楚为谁解决了什么问题", time: "8 月 23 日 14:00")]
        )
    ]

    let projects: [FrontierProject] = [
        FrontierProject(id: "project-robot", title: "桌面机器人的情绪灯与动作", guide: "周岑", guideRole: "机器视觉工程师", category: "机器人", age: "10–14 岁", duration: "4 周", format: "线下一对一", city: "上海", schedule: "沟通后确定", status: "可申请", symbol: "move.3d", colors: [0x0C3040, 0x078D91], summary: "从结构、灯光到简单控制逻辑，完成一台会回应环境的桌面机器人。", highlights: ["真实工程拆解", "每周一次项目推进", "适合喜欢动手的孩子"]),
        FrontierProject(id: "project-ai", title: "用 AI 做一份未来城市提案", guide: "林昊", guideRole: "AI 产品专家", category: "AI 与大模型", age: "11–15 岁", duration: "单次 120 分钟", format: "在线一对一", city: "全国", schedule: "周末可约", status: "可申请", symbol: "building.2.crop.circle", colors: [0x31245B, 0x7A5CF0], summary: "围绕交通、环境或社区问题，学习如何让 AI 成为研究和表达的伙伴。", highlights: ["从真实问题出发", "完成可分享的提案", "强调信息判断与安全"]),
        FrontierProject(id: "project-drone", title: "无人机行业与飞行控制体验", guide: "顾燃", guideRole: "无人机系统设计师", category: "无人机", age: "9–14 岁", duration: "单次 150 分钟", format: "线下小型活动", city: "深圳", schedule: "8 月 23 日", status: "仅余 3 席", symbol: "location.north.line.fill", colors: [0x193A65, 0x4D91F7], summary: "在合规场地了解飞行控制、任务规划和行业应用，由监护人全程陪同。", highlights: ["安全规范先行", "小组飞行任务", "认识真实行业场景"]),
        FrontierProject(id: "project-career", title: "算法工程师的一天", guide: "许澄", guideRole: "推荐算法工程师", category: "科技职业启蒙", age: "13–17 岁", duration: "单次 90 分钟", format: "在线一对一", city: "全国", schedule: "工作日晚间", status: "可申请", symbol: "point.3.connected.trianglepath.dotted", colors: [0x402044, 0xC05279], summary: "通过真实但已脱敏的工作案例，理解算法工程师怎样定义问题、验证假设和协作。", highlights: ["不包装大厂光环", "真实工作方法", "适合方向探索"])
    ]

    let guides: [String: GuideProfile] = [
        "林昊": GuideProfile(name: "林昊", role: "AI 产品专家", city: "北京", bio: "持续参与生成式 AI 产品从 0 到 1 的设计与落地，擅长用日常问题帮助青少年理解模型、数据和产品判断。", avatarSymbol: "person.crop.circle.fill", tags: ["AI 产品", "项目式学习", "10–15 岁", "表达清晰"], verification: ["身份已核验", "职业经历已核验", "项目经历已核验", "平台面谈通过"], courses: 6, participants: 83, reviews: 36, rating: 4.9),
        "周岑": GuideProfile(name: "周岑", role: "机器视觉工程师", city: "上海", bio: "拥有机器人感知与工业视觉项目经验，喜欢把抽象算法变成孩子可以看到、触摸和调试的挑战。", avatarSymbol: "person.crop.circle.fill", tags: ["机器视觉", "机器人", "动手实践", "12–16 岁"], verification: ["身份已核验", "职业经历已核验", "服务方案已审核"], courses: 4, participants: 42, reviews: 19, rating: 4.8),
        "顾燃": GuideProfile(name: "顾燃", role: "无人机系统设计师", city: "深圳", bio: "长期参与无人机系统集成与行业应用，所有青少年体验从安全边界和监护人知情开始。", avatarSymbol: "person.crop.circle.fill", tags: ["无人机", "飞行控制", "户外实践", "安全规范"], verification: ["身份已核验", "职业经历已核验", "线下场地已核验"], courses: 3, participants: 51, reviews: 22, rating: 4.9)
    ]
}
