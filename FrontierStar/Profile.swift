import UIKit

final class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var menu: [[(String, String, String)]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FSColor.canvas
        tableView.backgroundColor = FSColor.canvas
        tableView.separatorColor = FSColor.line
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "menu")
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadContent), name: .appStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadContent), name: .roleDidChange, object: nil)
        reloadContent()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reloadContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard tableView.bounds.width > 0 else { return }
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = makeHeader()
        } else if let header = tableView.tableHeaderView, abs(header.frame.width - tableView.bounds.width) > 0.5 {
            var frame = header.frame
            frame.size.width = tableView.bounds.width
            header.frame = frame
            tableView.tableHeaderView = header
        }
    }

    @objc private func reloadContent() {
        let role = AppStore.shared.activeRole
        let unreadMessages = max(3 - AppStore.shared.readMessageIDs.count, 0)
        if role == .guide {
            menu = [
                [("rectangle.stack", "我发布的项目", "审核状态与申请"), ("calendar", "服务与预约", "申请与服务安排"), ("bell", "消息中心", "\(unreadMessages) 条待处理")],
                [("person.text.rectangle", "公开主页预览", "家长看到的资料"), ("slider.horizontal.3", "引路人资料", "修改需重新审核"), ("arrow.triangle.2.circlepath", "切换身份", "当前：前沿引路人")],
                [("questionmark.circle", "帮助与客服", "服务规范与支持"), ("lock.shield", "协议与隐私", "信息与权限管理"), ("gearshape", "账号设置", "通知与注销")]
            ]
        } else if role == .parent {
            menu = [
                [("rectangle.stack.badge.person.crop", "已报名课程", "\(AppStore.shared.enrolledCourseIDs.count) 门课程"), ("text.bubble", "我的需求", "\(AppStore.shared.needs.count) 条需求"), ("calendar", "我的预约", "查看服务安排")],
                [("heart", "我的收藏", "课程与引路人"), ("bell", "消息中心", "\(unreadMessages) 条未读"), ("star", "我的评价", "完成服务后可评价")],
                [("arrow.triangle.2.circlepath", "切换身份", "当前：家长"), ("questionmark.circle", "帮助与客服", "课程顾问在线支持"), ("lock.shield", "协议与隐私", "儿童信息与权限"), ("gearshape", "账号设置", "通知与注销")]
            ]
        } else {
            menu = [
                [("heart", "本地收藏", "登录后可跨设备同步"), ("person.badge.plus", "申请成为引路人", "分享真实行业经验")],
                [("arrow.triangle.2.circlepath", "选择身份并登录", "家长 / 前沿引路人"), ("questionmark.circle", "客服与关于我们", "了解前沿星"), ("lock.shield", "协议与隐私", "隐私政策与儿童规则")]
            ]
        }
        guard isViewLoaded else { return }
        if tableView.bounds.width > 0 { tableView.tableHeaderView = makeHeader() }
        tableView.reloadData()
    }

    private func makeHeader() -> UIView {
        let role = AppStore.shared.activeRole
        let loggedIn = AppStore.shared.isLoggedIn
        let height: CGFloat = role == .guide ? 300 : 270
        let headerWidth = max(tableView.bounds.width, UIScreen.main.bounds.width)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: headerWidth, height: height))
        let logo = FSLogoView()
        let card = FSCardView(background: role == .guide ? FSColor.ink : .white, radius: 27)
        card.addShadow(opacity: 0.055, radius: 18, y: 6)
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openProfileSummary)))
        card.isAccessibilityElement = true
        card.accessibilityTraits = .button
        card.accessibilityLabel = role == .guide ? "查看公开主页与认证资料" : "查看账号与服务概览"
        let avatar = UIImageView(image: UIImage(systemName: role == .guide ? "sparkles" : role == .parent ? "figure.and.child.holdinghands" : "person.crop.circle"))
        avatar.tintColor = role == .guide ? UIColor(hex: 0xB1A6FF) : FSColor.accent
        avatar.backgroundColor = role == .guide ? UIColor.white.withAlphaComponent(0.12) : FSColor.palePurple
        avatar.layer.cornerRadius = 29
        avatar.layer.cornerCurve = .continuous
        avatar.contentMode = .center
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([avatar.widthAnchor.constraint(equalToConstant: 58), avatar.heightAnchor.constraint(equalToConstant: 58)])
        let titleText: String
        let subtitleText: String
        if role == .guide { titleText = "林昊 · 前沿引路人"; subtitleText = "平台已认证 · 北京 · 接受新需求" }
        else if role == .parent { titleText = loggedIn ? "林女士，上午好" : "登录后继续你的探索"; subtitleText = loggedIn ? "手机号已验证 · 北京" : "查看报名、需求与匹配进度" }
        else { titleText = "正在以游客身份浏览"; subtitleText = "公开内容无需登录" }
        let title = UILabel.fs(titleText, font: FSFont.title(22), color: role == .guide ? .white : FSColor.ink)
        let subtitle = UILabel.fs(subtitleText, font: FSFont.caption(12), color: role == .guide ? UIColor.white.withAlphaComponent(0.65) : FSColor.secondaryInk)
        let labels = UIStackView(arrangedSubviews: [title, subtitle]); labels.axis = .vertical; labels.spacing = 5
        let top = UIStackView(arrangedSubviews: [avatar, labels, UIView(), UIImageView(image: UIImage(systemName: "chevron.right"))]); top.spacing = 13; top.alignment = .center
        let content = UIStackView(arrangedSubviews: [top]); content.axis = .vertical; content.spacing = 18
        if role == .guide {
            let stats = UIStackView(); stats.distribution = .fillEqually
            [("\(AppStore.shared.needs.count)", "可匹配需求"), ("\(AppStore.shared.appliedProjectIDs.count)", "待确认预约"), ("\(AppStore.shared.submittedProjects.count)", "我发布的项目")].forEach { value, label in
                let v = UILabel.fs(value, font: FSFont.title(21), color: .white); v.textAlignment = .center
                let l = UILabel.fs(label, font: FSFont.caption(10), color: UIColor.white.withAlphaComponent(0.58)); l.textAlignment = .center
                let column = UIStackView(arrangedSubviews: [v, l]); column.axis = .vertical; column.spacing = 3; stats.addArrangedSubview(column)
            }
            content.addArrangedSubview(stats)
            let status = UILabel.fs("  ✓ 资料审核通过 · 公开主页已上线  ", font: FSFont.caption(11), color: UIColor(hex: 0xC8F1E1)); status.backgroundColor = UIColor.white.withAlphaComponent(0.1); status.layer.cornerRadius = 13; status.clipsToBounds = true; status.textAlignment = .center; status.heightAnchor.constraint(equalToConstant: 30).isActive = true
            content.addArrangedSubview(status)
        } else if !loggedIn {
            let login = FSPrimaryButton(title: "登录 / 注册", symbol: "arrow.right")
            login.addAction(UIAction { [weak self] _ in guard let self else { return }; AuthGate.require(role: .parent, from: self) { FSApp.showMain() } }, for: .touchUpInside)
            content.addArrangedSubview(login)
        } else {
            let summary = UIStackView(); summary.distribution = .fillEqually
            [("\(AppStore.shared.enrolledCourseIDs.count)", "已报名"), ("\(AppStore.shared.needs.count)", "需求"), ("\(AppStore.shared.favoriteCourseIDs.count)", "收藏")].forEach { value, label in
                let v = UILabel.fs(value, font: FSFont.title(21)); v.textAlignment = .center
                let l = UILabel.fs(label, font: FSFont.caption(10), color: FSColor.secondaryInk); l.textAlignment = .center
                let column = UIStackView(arrangedSubviews: [v, l]); column.axis = .vertical; column.spacing = 3; summary.addArrangedSubview(column)
            }
            content.addArrangedSubview(summary)
        }
        card.addSubview(content); content.pinEdges(to: card, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        header.addSubview(logo); header.addSubview(card)
        logo.translatesAutoresizingMaskIntoConstraints = false; card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logo.topAnchor.constraint(equalTo: header.safeAreaLayoutGuide.topAnchor, constant: 11), logo.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20), logo.heightAnchor.constraint(equalToConstant: 26),
            card.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 19), card.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16), card.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16), card.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -10)
        ])
        return header
    }

    func numberOfSections(in tableView: UITableView) -> Int { menu.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { menu[section].count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menu", for: indexPath)
        let item = menu[indexPath.section][indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.image = UIImage(systemName: item.0)
        config.imageProperties.tintColor = FSColor.accent
        config.text = item.1
        config.secondaryText = item.2
        config.textProperties.font = FSFont.headline(15)
        config.secondaryTextProperties.font = FSFont.caption(11)
        config.secondaryTextProperties.color = FSColor.tertiaryInk
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .white
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let title = menu[indexPath.section][indexPath.row].1
        switch title {
        case "已报名课程": navigationController?.pushViewController(EnrolledCoursesViewController(), animated: true)
        case "我的需求":
            navigationController?.pushViewController(NeedsViewController(), animated: true)
        case "我的收藏", "本地收藏": navigationController?.pushViewController(FavoritesViewController(), animated: true)
        case "消息中心": navigationController?.pushViewController(MessagesViewController(), animated: true)
        case "我的预约", "服务与预约": navigationController?.pushViewController(AppointmentsViewController(), animated: true)
        case "我的评价": navigationController?.pushViewController(ReviewsViewController(), animated: true)
        case "切换身份", "选择身份并登录": showRoleSwitch()
        case "我发布的项目": navigationController?.pushViewController(MyProjectsViewController(), animated: true)
        case "公开主页预览":
            navigationController?.pushViewController(GuideDetailViewController(profile: AppStore.shared.currentGuideProfile), animated: true)
        case "引路人资料": navigationController?.pushViewController(GuideProfileEditorViewController(), animated: true)
        case "帮助与客服", "客服与关于我们": navigationController?.pushViewController(SupportCenterViewController(), animated: true)
        case "协议与隐私": navigationController?.pushViewController(PrivacyCenterViewController(), animated: true)
        case "申请成为引路人":
            AuthGate.require(role: .guide, from: self) { [weak self] in self?.navigationController?.pushViewController(GuideApplicationViewController(), animated: true) }
        case "账号设置": navigationController?.pushViewController(AccountSettingsViewController(), animated: true)
        default: navigationController?.pushViewController(InformationViewController(title: title), animated: true)
        }
    }

    @objc private func openProfileSummary() {
        if AppStore.shared.activeRole == .guide {
            navigationController?.pushViewController(GuideDetailViewController(profile: AppStore.shared.currentGuideProfile), animated: true)
        } else {
            navigationController?.pushViewController(ProfileSummaryViewController(), animated: true)
        }
    }

    private func showRoleSwitch() {
        let sheet = UIAlertController(title: "切换使用身份", message: "同一个成年人账号可以同时拥有家长与引路人资格", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "家长", style: .default) { [weak self] _ in self?.switchRole(.parent) })
        sheet.addAction(UIAlertAction(title: "前沿引路人", style: .default) { [weak self] _ in self?.switchRole(.guide) })
        sheet.addAction(UIAlertAction(title: "游客浏览", style: .default) { _ in AppStore.shared.choose(role: .visitor); FSApp.showMain() })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    private func switchRole(_ role: UserRole) {
        if AppStore.shared.isLoggedIn { AppStore.shared.choose(role: role); FSApp.showMain() }
        else { AuthGate.require(role: role, from: self) { FSApp.showMain() } }
    }
}

final class EnrolledCoursesViewController: UITableViewController {
    private var courses: [Course] { AppStore.shared.courses.filter { AppStore.shared.enrolledCourseIDs.contains($0.id) } }
    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(title: "已报名课程"); navigationController?.setNavigationBarHidden(false, animated: false)
        tableView.backgroundColor = FSColor.canvas; tableView.separatorStyle = .none; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "course")
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { courses.count }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 105 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "course", for: indexPath); let course = courses[indexPath.row]
        var config = cell.defaultContentConfiguration(); config.text = course.title.replacingOccurrences(of: "\n", with: " "); config.secondaryText = "待课程顾问联系 · \(course.schedule)"; config.image = UIImage(systemName: course.artSymbol); config.imageProperties.tintColor = FSColor.accent; config.textProperties.font = FSFont.headline(15); config.secondaryTextProperties.font = FSFont.caption(12); config.secondaryTextProperties.color = FSColor.success
        cell.contentConfiguration = config; cell.backgroundColor = .clear; cell.accessoryType = .disclosureIndicator; return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { navigationController?.pushViewController(CourseDetailViewController(course: courses[indexPath.row]), animated: true) }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if courses.isEmpty {
            tableView.setFSEmptyState(FSEmptyStateView(symbol: "rectangle.stack", title: "还没有报名课程", message: "从课程流找到适合孩子年龄和兴趣的方向。", actionTitle: "去看课程") { [weak self] in self?.selectMainTab(identifier: "courses", fallbackIndex: 0) })
        } else { tableView.setFSEmptyState(nil) }
    }
}

final class FavoritesViewController: UITableViewController {
    private var courses: [Course] { AppStore.shared.courses.filter { AppStore.shared.favoriteCourseIDs.contains($0.id) } }
    override func viewDidLoad() { super.viewDidLoad(); configureLightNavigation(title: "我的收藏"); navigationController?.setNavigationBarHidden(false, animated: false); tableView.backgroundColor = FSColor.canvas; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "favorite") }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { courses.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let cell = tableView.dequeueReusableCell(withIdentifier: "favorite", for: indexPath); var config = cell.defaultContentConfiguration(); let course = courses[indexPath.row]; config.text = course.title.replacingOccurrences(of: "\n", with: " "); config.secondaryText = "\(course.category) · \(course.age)"; config.image = UIImage(systemName: "heart.fill"); config.imageProperties.tintColor = FSColor.coral; cell.contentConfiguration = config; cell.backgroundColor = .clear; cell.accessoryType = .disclosureIndicator; return cell }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { navigationController?.pushViewController(CourseDetailViewController(course: courses[indexPath.row]), animated: true) }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); if courses.isEmpty { tableView.setFSEmptyState(FSEmptyStateView(symbol: "heart", title: "还没有收藏内容", message: "收藏感兴趣的课程，之后可以快速比较。", actionTitle: "发现课程") { [weak self] in self?.selectMainTab(identifier: "courses", fallbackIndex: 0) }) } else { tableView.setFSEmptyState(nil) } }
}

private struct MessageItem {
    let id: String
    let title: String
    let body: String
    let symbol: String
    let time: String
}

final class MessagesViewController: UITableViewController {
    private let messages = [
        MessageItem(id: "guide-recommendation", title: "引路人推荐", body: "已为你的 AI 项目需求找到 2 位候选引路人", symbol: "sparkles", time: "刚刚"),
        MessageItem(id: "course-registration", title: "报名已收到", body: "AI 大模型创造力实验室已写入报名记录", symbol: "checkmark.circle", time: "今天"),
        MessageItem(id: "advisor-reminder", title: "服务提醒", body: "课程顾问将在 24 小时内与你联系", symbol: "bell", time: "今天")
    ]
    override func viewDidLoad() { super.viewDidLoad(); configureLightNavigation(title: "消息中心"); navigationController?.setNavigationBarHidden(false, animated: false); tableView.backgroundColor = FSColor.canvas; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "message") }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 86 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let cell = tableView.dequeueReusableCell(withIdentifier: "message", for: indexPath); let item = messages[indexPath.row]; let unread = !AppStore.shared.readMessageIDs.contains(item.id); var config = cell.defaultContentConfiguration(); config.text = (unread ? "●  " : "") + item.title; config.secondaryText = item.body + " · " + item.time; config.image = UIImage(systemName: item.symbol); config.imageProperties.tintColor = FSColor.accent; config.textProperties.font = FSFont.headline(15); config.secondaryTextProperties.font = FSFont.caption(12); config.secondaryTextProperties.color = FSColor.secondaryInk; cell.contentConfiguration = config; cell.backgroundColor = .clear; cell.accessoryType = .disclosureIndicator; return cell }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = messages[indexPath.row]
        AppStore.shared.markMessageRead(item.id)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        navigationController?.pushViewController(MessageDetailViewController(title: item.title, body: item.body, symbol: item.symbol, time: item.time), animated: true)
    }
}

final class MyProjectsViewController: UITableViewController {
    private var projects: [FrontierProject] { AppStore.shared.submittedProjects }
    override func viewDidLoad() { super.viewDidLoad(); configureLightNavigation(title: "我发布的项目"); navigationController?.setNavigationBarHidden(false, animated: false); tableView.backgroundColor = FSColor.canvas; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "project") }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { projects.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let cell = tableView.dequeueReusableCell(withIdentifier: "project", for: indexPath); let project = projects[indexPath.row]; var config = cell.defaultContentConfiguration(); config.text = project.title; config.secondaryText = "\(project.status) · \(project.category)"; config.image = UIImage(systemName: project.symbol); config.imageProperties.tintColor = FSColor.accent; cell.contentConfiguration = config; cell.accessoryType = .disclosureIndicator; return cell }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(ProjectDetailViewController(project: projects[indexPath.row]), animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        if projects.isEmpty {
            tableView.setFSEmptyState(FSEmptyStateView(symbol: "square.and.pencil", title: "还没有发布项目", message: "先写清楚你真正能提供的经验和适合的孩子。", actionTitle: "创建项目") { [weak self] in
                self?.navigationController?.pushViewController(ProjectComposerViewController(), animated: true)
            })
        } else {
            tableView.setFSEmptyState(nil)
        }
    }
}

private enum AppointmentDestination {
    case course(Course)
    case project(FrontierProject)
}

final class AppointmentsViewController: UITableViewController {
    private var items: [(String, String, String, AppointmentDestination)] {
        let courses = AppStore.shared.courses.filter { AppStore.shared.enrolledCourseIDs.contains($0.id) }.map {
            ($0.title.replacingOccurrences(of: "\n", with: " "), "报名已收到 · \($0.schedule)", "calendar.badge.checkmark", AppointmentDestination.course($0))
        }
        let projects = AppStore.shared.projects.filter { AppStore.shared.appliedProjectIDs.contains($0.id) }.map {
            ($0.title, "申请已提交 · \($0.schedule)", "paperplane.fill", AppointmentDestination.project($0))
        }
        return courses + projects
    }

    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(title: "服务与预约"); navigationController?.setNavigationBarHidden(false, animated: false)
        tableView.backgroundColor = FSColor.canvas; tableView.separatorStyle = .none; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "appointment")
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData(); updateEmptyState() }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 92 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]; let cell = tableView.dequeueReusableCell(withIdentifier: "appointment", for: indexPath)
        var config = cell.defaultContentConfiguration(); config.text = item.0; config.secondaryText = item.1; config.image = UIImage(systemName: item.2); config.imageProperties.tintColor = FSColor.accent; config.textProperties.font = FSFont.headline(15); config.secondaryTextProperties.font = FSFont.caption(12); config.secondaryTextProperties.color = FSColor.success
        cell.contentConfiguration = config; cell.backgroundColor = .clear; cell.accessoryType = .disclosureIndicator; return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch items[indexPath.row].3 {
        case let .course(course): navigationController?.pushViewController(CourseDetailViewController(course: course), animated: true)
        case let .project(project): navigationController?.pushViewController(ProjectDetailViewController(project: project), animated: true)
        }
    }
    private func updateEmptyState() {
        if items.isEmpty {
            tableView.setFSEmptyState(FSEmptyStateView(symbol: "calendar", title: "还没有服务安排", message: "报名课程或申请项目后，确认进度会集中显示在这里。", actionTitle: "发现项目") { [weak self] in self?.selectMainTab(identifier: "projects", fallbackIndex: 1) })
        } else { tableView.setFSEmptyState(nil) }
    }
}

final class ReviewsViewController: UITableViewController {
    private var courses: [Course] { AppStore.shared.courses.filter { AppStore.shared.enrolledCourseIDs.contains($0.id) } }
    override func viewDidLoad() { super.viewDidLoad(); configureLightNavigation(title: "我的评价"); navigationController?.setNavigationBarHidden(false, animated: false); tableView.backgroundColor = FSColor.canvas; tableView.separatorStyle = .none; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "review") }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData(); updateEmptyState() }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { courses.count }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 90 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let course = courses[indexPath.row]; let reviewed = AppStore.shared.reviewedCourseIDs.contains(course.id); let cell = tableView.dequeueReusableCell(withIdentifier: "review", for: indexPath)
        var config = cell.defaultContentConfiguration(); config.text = course.title.replacingOccurrences(of: "\n", with: " "); config.secondaryText = reviewed ? "已评价 · 点击查看或修改" : "待评价 · 分享真实体验"; config.image = UIImage(systemName: reviewed ? "star.fill" : "star"); config.imageProperties.tintColor = reviewed ? FSColor.warning : FSColor.accent; cell.contentConfiguration = config; cell.backgroundColor = .clear; cell.accessoryType = .disclosureIndicator; return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true); navigationController?.pushViewController(ReviewComposerViewController(course: courses[indexPath.row]), animated: true) }
    private func updateEmptyState() {
        if courses.isEmpty { tableView.setFSEmptyState(FSEmptyStateView(symbol: "star", title: "还没有可评价服务", message: "完成课程报名与服务后，可以在这里留下真实体验。", actionTitle: "去看课程") { [weak self] in self?.selectMainTab(identifier: "courses", fallbackIndex: 0) }) } else { tableView.setFSEmptyState(nil) }
    }
}

final class ReviewComposerViewController: UIViewController {
    private let course: Course
    private var rating = 5
    private let comment = FSFormField(title: "评价内容", placeholder: "哪些体验让孩子真正有收获？")
    init(course: Course) { self.course = course; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(title: "课程评价"); navigationController?.setNavigationBarHidden(false, animated: false)
        if let review = AppStore.shared.review(courseID: course.id) { rating = review.rating; comment.textField.text = review.comment }
        let (_, stack) = makeScrollStack(in: self)
        stack.addArrangedSubviews(UILabel.fs(course.title.replacingOccurrences(of: "\n", with: " "), font: FSFont.display(27), lines: 0), UILabel.fs("你的评价会帮助其他家庭做出更适合的选择。", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 0))
        let ratings = UIStackView(); ratings.spacing = 8; ratings.distribution = .fillEqually
        var buttons: [FSChoiceButton] = []
        (1...5).forEach { value in
            let button = FSChoiceButton(title: "\(value)", symbol: "star.fill"); button.choiceSelected = value == rating; buttons.append(button)
            button.addAction(UIAction { [weak self] _ in self?.rating = value; buttons.forEach { $0.choiceSelected = $0 === button } }, for: .touchUpInside); ratings.addArrangedSubview(button)
        }
        stack.addArrangedSubviews(UILabel.fs("整体评分", font: FSFont.headline(15)), ratings, comment)
        let submit = FSPrimaryButton(title: AppStore.shared.reviewedCourseIDs.contains(course.id) ? "更新评价" : "提交评价", symbol: "paperplane.fill")
        submit.addAction(UIAction { [weak self] _ in self?.submit() }, for: .touchUpInside); stack.addArrangedSubview(submit)
    }
    private func submit() {
        let text = comment.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text.count >= 6 else { showToast("请至少写下 6 个字的真实体验", symbol: "exclamationmark"); return }
        AppStore.shared.submitReview(courseID: course.id, rating: rating, comment: text)
        showToast("评价已保存，感谢真实分享", symbol: "star.fill")
    }
}

final class GuideProfileEditorViewController: UIViewController {
    private let roleField = FSFormField(title: "公开职业身份", placeholder: "如：AI 产品专家")
    private let cityField = FSFormField(title: "所在城市", placeholder: "如：北京")
    private let bioField = FSFormField(title: "专业经历简介", placeholder: "说明你真正做过什么")
    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(title: "引路人资料"); navigationController?.setNavigationBarHidden(false, animated: false)
        let profile = AppStore.shared.currentGuideProfile; roleField.textField.text = profile.role; cityField.textField.text = profile.city; bioField.textField.text = profile.bio
        let (_, stack) = makeScrollStack(in: self)
        stack.addArrangedSubviews(UILabel.fs("编辑公开资料", font: FSFont.display(29)), UILabel.fs("职业身份和专业简介修改后会重新进入平台审核。", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 0), roleField, cityField, bioField)
        let save = FSPrimaryButton(title: "保存并提交复审", symbol: "checkmark"); save.addAction(UIAction { [weak self] _ in self?.save() }, for: .touchUpInside); stack.addArrangedSubview(save)
    }
    private func save() {
        let role = roleField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""; let city = cityField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""; let bio = bioField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard role.count >= 2, !city.isEmpty, bio.count >= 12 else { showToast("请完整填写职业、城市和至少 12 字的经历简介", symbol: "exclamationmark"); return }
        AppStore.shared.setProfileText(role, key: "role"); AppStore.shared.setProfileText(city, key: "city"); AppStore.shared.setProfileText(bio, key: "bio"); showToast("资料已保存并进入复审", symbol: "checkmark.seal.fill")
    }
}

final class SupportCenterViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(title: "帮助与客服"); navigationController?.setNavigationBarHidden(false, animated: false)
        let (_, stack) = makeScrollStack(in: self)
        stack.addArrangedSubviews(UILabel.fs("需要什么帮助？", font: FSFont.display(29)), UILabel.fs("课程顾问服务时间：工作日 09:00–20:00", font: FSFont.body(14), color: FSColor.secondaryInk))
        [("报名后会发生什么？", "报名是意向提交。课程顾问会核对孩子情况、时间与名额，再确认后续安排。"), ("如何保护孩子信息？", "孩子不设独立账号；需求只展示家长授权的脱敏摘要。"), ("怎样成为引路人？", "平台会核验身份、职业与项目经历，并通过面谈确认青少年沟通能力。")].forEach { title, body in
            let button = UIButton(type: .system); button.backgroundColor = .white; button.layer.cornerRadius = 17; button.contentHorizontalAlignment = .leading; button.setTitle("  \(title)", for: .normal); button.setTitleColor(FSColor.ink, for: .normal); button.titleLabel?.font = FSFont.headline(15); button.heightAnchor.constraint(equalToConstant: 54).isActive = true
            button.addAction(UIAction { [weak self] _ in self?.navigationController?.pushViewController(SupportArticleViewController(title: title, body: body), animated: true) }, for: .touchUpInside); stack.addArrangedSubview(button)
        }
        let contact = FSPrimaryButton(title: "联系课程顾问", symbol: "headphones"); contact.addAction(UIAction { [weak self] _ in self?.showToast("已登记顾问回电，预计工作时间 30 分钟内响应", symbol: "phone.fill") }, for: .touchUpInside); stack.addArrangedSubview(contact)
    }
}

final class SupportArticleViewController: UIViewController {
    private let articleTitle: String; private let body: String
    init(title: String, body: String) { articleTitle = title; self.body = body; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() { super.viewDidLoad(); configureLightNavigation(title: "帮助详情"); navigationController?.setNavigationBarHidden(false, animated: false); let (_, stack) = makeScrollStack(in: self); stack.addArrangedSubviews(UILabel.fs(articleTitle, font: FSFont.display(28), lines: 0), UILabel.fs(body, font: FSFont.body(16), color: FSColor.secondaryInk, lines: 0)) }
}

final class PrivacyCenterViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(title: "协议与隐私"); navigationController?.setNavigationBarHidden(false, animated: false)
        let (_, stack) = makeScrollStack(in: self)
        stack.addArrangedSubviews(UILabel.fs("信息透明，边界清晰", font: FSFont.display(29)), UILabel.fs("集中查看平台规则，以及当前账号可管理的授权。", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 0))
        ["用户协议", "隐私政策", "儿童个人信息处理规则"].forEach { title in
            let button = FSPrimaryButton(title: title, symbol: "doc.text"); button.addAction(UIAction { [weak self] _ in self?.navigationController?.pushViewController(InformationViewController(title: title), animated: true) }, for: .touchUpInside); stack.addArrangedSubview(button)
        }
        let permissions = FSPrimaryButton(title: "管理信息与服务授权", symbol: "lock.shield"); permissions.addAction(UIAction { [weak self] _ in self?.navigationController?.pushViewController(SettingDetailViewController(setting: "权限管理"), animated: true) }, for: .touchUpInside); stack.addArrangedSubview(permissions)
    }
}

final class InformationViewController: UIViewController {
    private let pageTitle: String
    init(title: String) { pageTitle = title; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(title: pageTitle); navigationController?.setNavigationBarHidden(false, animated: false)
        let (_, stack) = makeScrollStack(in: self)
        let icon = UIImageView(image: UIImage(systemName: pageTitle.contains("隐私") ? "lock.shield.fill" : "questionmark.circle.fill")); icon.tintColor = FSColor.accent; icon.contentMode = .scaleAspectFit; icon.heightAnchor.constraint(equalToConstant: 62).isActive = true
        let title = UILabel.fs(pageTitle, font: FSFont.display(29)); title.textAlignment = .center
        let body: String
        switch pageTitle {
        case "用户协议":
            body = "前沿星提供课程信息展示、需求匹配与服务协调。报名或申请表示提交服务意向，不代表名额确认或自动产生费用。\n\n用户应提供真实、必要的信息，不得利用平台绕过监护人、课程顾问或安全规则与未成年人私下联系。\n\n具体课程、费用、退款与履约安排，以双方最终确认的服务信息为准。"
        case "儿童个人信息处理规则":
            body = "孩子不设独立账号。平台不主动收集孩子真实姓名、精确出生日期、学校、照片或详细住址。\n\n家长发布需求时，只需提供年龄段、城市、兴趣、基础和目标。需求大厅展示的是脱敏摘要，仅供通过认证的引路人判断专业匹配。\n\n进入具体服务前，新增信息将再次向监护人说明用途与范围。"
        default:
            body = "前沿星只收集完成课程报名、人工匹配与履约所必需的信息。联系方式始终由课程顾问居中管理，不会直接公开给需求大厅中的引路人。\n\n你可以在权限管理中查看和调整可撤回授权；注销申请会先检查未完成课程、预约、退款与争议，再依法删除或匿名化可处理的数据。"
        }
        let text = UILabel.fs(body, font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0)
        stack.addArrangedSubviews(icon, title, text)
    }
}

final class AccountSettingsViewController: UITableViewController {
    private let rows = ["服务通知", "手机号与登录方式", "权限管理", "注销账号", "退出登录"]
    override func viewDidLoad() { super.viewDidLoad(); configureLightNavigation(title: "账号设置"); navigationController?.setNavigationBarHidden(false, animated: false); tableView.backgroundColor = FSColor.canvas; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "setting") }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let cell = tableView.dequeueReusableCell(withIdentifier: "setting", for: indexPath); var config = cell.defaultContentConfiguration(); config.text = rows[indexPath.row]; config.textProperties.color = indexPath.row >= 3 ? FSColor.coral : FSColor.ink; cell.contentConfiguration = config; cell.backgroundColor = .clear; cell.accessoryType = .disclosureIndicator; return cell }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = rows[indexPath.row]
        if item == "退出登录" {
            let alert = UIAlertController(title: "退出登录？", message: "本地敏感登录信息将被清理，游客收藏仍会保留。", preferredStyle: .alert); alert.addAction(UIAlertAction(title: "取消", style: .cancel)); alert.addAction(UIAlertAction(title: "退出", style: .destructive) { _ in AppStore.shared.logout(); FSApp.showIdentity() }); present(alert, animated: true)
        } else if item == "注销账号" {
            let alert = UIAlertController(title: "申请注销账号", message: "注销前需确认没有未完成课程、预约或退款。提交申请后，课程顾问会协助完成身份核验与数据处理。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "暂不注销", style: .cancel))
            alert.addAction(UIAlertAction(title: "了解注销流程", style: .destructive) { [weak self] _ in
                self?.navigationController?.pushViewController(SettingDetailViewController(setting: item), animated: true)
            })
            present(alert, animated: true)
        } else {
            navigationController?.pushViewController(SettingDetailViewController(setting: item), animated: true)
        }
    }
}

final class GuideApplicationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(title: "申请前沿引路人"); navigationController?.setNavigationBarHidden(false, animated: false)
        let (_, stack) = makeScrollStack(in: self)
        stack.addArrangedSubviews(UILabel.fs("把真实专业经验\n带到孩子面前", font: FSFont.display(30), lines: 2), UILabel.fs("平台将核验身份、职业与项目经历，并通过面谈确认是否适合青少年沟通。提交不等于直接上线。", font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0))
        ["基础身份", "专业经历", "擅长方向", "可提供服务", "指导经验", "证明资料", "协议与提交"].enumerated().forEach { index, title in
            let number = UILabel.fs("\(index + 1)", font: FSFont.caption(12), color: .white); number.textAlignment = .center; number.backgroundColor = FSColor.accent; number.layer.cornerRadius = 14; number.clipsToBounds = true; number.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([number.widthAnchor.constraint(equalToConstant: 28), number.heightAnchor.constraint(equalToConstant: 28)])
            let row = UIStackView(arrangedSubviews: [number, UILabel.fs(title, font: FSFont.headline(15)), UIView(), UIImageView(image: UIImage(systemName: "chevron.right"))]); row.alignment = .center; row.spacing = 11; row.isUserInteractionEnabled = false
            let button = UIButton(type: .system); button.backgroundColor = .white; button.layer.cornerRadius = 17; button.layer.cornerCurve = .continuous
            button.accessibilityLabel = "填写第 \(index + 1) 步：\(title)"
            button.addSubview(row); row.pinEdges(to: button, insets: UIEdgeInsets(top: 13, left: 14, bottom: 13, right: 14))
            button.addAction(UIAction { [weak self] _ in
                self?.navigationController?.pushViewController(GuideApplicationStepViewController(step: index + 1, title: title), animated: true)
            }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        let button = FSPrimaryButton(title: "保存并开始申请", symbol: "arrow.right")
        button.addAction(UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(GuideApplicationStepViewController(step: 1, title: "基础身份"), animated: true)
        }, for: .touchUpInside)
        stack.addArrangedSubview(button)
    }
}

final class ProfileSummaryViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: "账号概览")
        navigationController?.setNavigationBarHidden(false, animated: false)
        let (_, stack) = makeScrollStack(in: self)
        let role = AppStore.shared.activeRole
        let icon = UIImageView(image: UIImage(systemName: role.symbol))
        icon.tintColor = FSColor.accent
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 66).isActive = true
        let title = UILabel.fs(role == .visitor ? "游客账号" : role == .parent ? "家长账号" : "引路人账号", font: FSFont.display(29))
        title.textAlignment = .center
        let phone = AppStore.shared.verifiedPhone.map { String($0.prefix(3)) + "****" + String($0.suffix(4)) } ?? "尚未验证手机号"
        let summary = FSCardView(radius: 21)
        let rows = [
            ("当前身份", role.title),
            ("登录状态", AppStore.shared.isLoggedIn ? "已登录" : "未登录"),
            ("联系方式", phone),
            ("已报名", "\(AppStore.shared.enrolledCourseIDs.count) 门"),
            ("我的需求", "\(AppStore.shared.needs.count) 条")
        ]
        let list = UIStackView(); list.axis = .vertical; list.spacing = 14
        rows.forEach { key, value in
            let valueLabel = UILabel.fs(value, font: FSFont.headline(14)); valueLabel.textAlignment = .right
            list.addArrangedSubview(UIStackView(arrangedSubviews: [UILabel.fs(key, font: FSFont.caption(12), color: FSColor.tertiaryInk), UIView(), valueLabel]))
        }
        summary.addSubview(list); list.pinEdges(to: summary, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        stack.addArrangedSubviews(icon, title, summary)

        if AppStore.shared.isLoggedIn {
            let settings = FSPrimaryButton(title: "管理账号设置", symbol: "gearshape")
            settings.addAction(UIAction { [weak self] _ in self?.navigationController?.pushViewController(AccountSettingsViewController(), animated: true) }, for: .touchUpInside)
            stack.addArrangedSubview(settings)
        } else {
            let login = FSPrimaryButton(title: "登录并同步数据", symbol: "arrow.right")
            login.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                AuthGate.require(role: .parent, from: self) { [weak self] in self?.navigationController?.popViewController(animated: true) }
            }, for: .touchUpInside)
            stack.addArrangedSubview(login)
        }
    }
}

final class MessageDetailViewController: UIViewController {
    private let messageTitle: String
    private let body: String
    private let symbol: String
    private let time: String

    init(title: String, body: String, symbol: String, time: String) {
        messageTitle = title; self.body = body; self.symbol = symbol; self.time = time
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: "消息详情")
        navigationController?.setNavigationBarHidden(false, animated: false)
        let (_, stack) = makeScrollStack(in: self)
        let icon = UIImageView(image: UIImage(systemName: symbol)); icon.tintColor = FSColor.accent; icon.contentMode = .scaleAspectFit; icon.heightAnchor.constraint(equalToConstant: 62).isActive = true
        let title = UILabel.fs(messageTitle, font: FSFont.display(29)); title.textAlignment = .center
        let date = UILabel.fs(time, font: FSFont.caption(12), color: FSColor.tertiaryInk); date.textAlignment = .center
        let card = FSCardView(radius: 21)
        let text = UILabel.fs(body, font: FSFont.body(16), color: FSColor.secondaryInk, lines: 0)
        card.addSubview(text); text.pinEdges(to: card, insets: UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18))
        let action = FSPrimaryButton(title: messageTitle.contains("推荐") ? "查看我的需求" : "查看相关服务", symbol: "arrow.right")
        action.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if self.messageTitle.contains("推荐"), let need = AppStore.shared.needs.first {
                self.navigationController?.pushViewController(NeedDetailViewController(need: need, guideMode: false), animated: true)
            } else {
                self.navigationController?.pushViewController(EnrolledCoursesViewController(), animated: true)
            }
        }, for: .touchUpInside)
        stack.addArrangedSubviews(icon, title, date, card, action)
    }
}

final class SettingDetailViewController: UIViewController {
    private let setting: String
    init(setting: String) { self.setting = setting; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: setting)
        navigationController?.setNavigationBarHidden(false, animated: false)
        let (_, stack) = makeScrollStack(in: self)
        let descriptions: [String: String] = [
            "服务通知": "管理课程、预约、需求匹配与平台服务通知。重要的履约或安全提醒不会被营销设置覆盖。",
            "手机号与登录方式": "手机号用于身份核验、报名确认与服务联系。更换手机号需要重新完成短信验证。",
            "权限管理": "查看平台如何使用必要信息，并管理可撤回的需求展示与服务授权。",
            "注销账号": "注销前会检查未完成课程、预约、退款和争议。完成后将按法律要求删除或匿名化可处理的数据。"
        ]
        let icon = UIImageView(image: UIImage(systemName: setting == "注销账号" ? "person.crop.circle.badge.minus" : "slider.horizontal.3")); icon.tintColor = setting == "注销账号" ? FSColor.coral : FSColor.accent; icon.contentMode = .scaleAspectFit; icon.heightAnchor.constraint(equalToConstant: 60).isActive = true
        stack.addArrangedSubviews(icon, UILabel.fs(descriptions[setting] ?? "管理此项设置。", font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0))

        if setting == "服务通知" {
            ["课程与预约提醒", "需求匹配进度", "产品与活动推荐"].forEach {
                stack.addArrangedSubview(toggleRow(title: $0, defaultEnabled: $0 != "产品与活动推荐"))
            }
        } else if setting == "权限管理" {
            ["向已认证引路人展示脱敏需求", "允许课程顾问服务回访"].forEach {
                stack.addArrangedSubview(toggleRow(title: $0, defaultEnabled: true))
            }
        } else {
            let button = FSPrimaryButton(title: setting == "注销账号" ? "联系顾问确认注销条件" : "验证新的手机号", symbol: "arrow.right")
            button.addAction(UIAction { [weak self] _ in self?.showToast(self?.setting == "注销账号" ? "已登记顾问协助请求" : "验证流程已准备", symbol: "checkmark.circle.fill") }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }

    private func toggleRow(title: String, defaultEnabled: Bool) -> UIView {
        let control = UISwitch(); control.isOn = AppStore.shared.setting(title, default: defaultEnabled); control.onTintColor = FSColor.accent
        control.addAction(UIAction { [weak self, weak control] _ in
            let value = control?.isOn == true
            AppStore.shared.setSetting(value, key: title)
            self?.showToast(value ? "已开启\(title)" : "已关闭\(title)", symbol: "checkmark")
        }, for: .valueChanged)
        let row = UIStackView(arrangedSubviews: [UILabel.fs(title, font: FSFont.headline(15)), UIView(), control]); row.alignment = .center
        let card = FSCardView(radius: 17); card.addSubview(row); row.pinEdges(to: card, insets: UIEdgeInsets(top: 14, left: 15, bottom: 14, right: 15))
        return card
    }
}

final class GuideApplicationStepViewController: UIViewController {
    private let step: Int
    private let stepTitle: String
    private lazy var mainField = FSFormField(title: fieldDefinition.0, placeholder: fieldDefinition.1)
    private lazy var noteField = FSFormField(title: fieldDefinition.2, placeholder: fieldDefinition.3)
    init(step: Int, title: String) { self.step = step; stepTitle = title; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: stepTitle)
        navigationController?.setNavigationBarHidden(false, animated: false)
        let saved = AppStore.shared.guideApplicationStep(step)
        mainField.textField.text = saved["main"]
        noteField.textField.text = saved["note"]
        let (_, stack) = makeScrollStack(in: self)
        stack.addArrangedSubviews(
            UILabel.fs("第 \(step) 步 · \(stepTitle)", font: FSFont.display(29)),
            UILabel.fs("请填写真实、可核验的信息。保存本步骤不会直接提交审核。", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 0),
            mainField,
            noteField
        )
        let save = FSPrimaryButton(title: step == 7 ? "保存并预览申请" : "保存本步骤", symbol: "checkmark")
        save.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.view.endEditing(true)
            let main = self.mainField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !main.isEmpty else {
                self.showToast("请先填写\(self.stepTitle)的主要信息", symbol: "exclamationmark")
                return
            }
            let note = self.noteField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            AppStore.shared.saveGuideApplicationStep(self.step, main: main, note: note)
            self.showToast("\(self.stepTitle)已保存", symbol: "tray.and.arrow.down.fill")
        }, for: .touchUpInside)
        stack.addArrangedSubview(save)
    }

    private var fieldDefinition: (String, String, String, String) {
        switch step {
        case 1: return ("真实姓名与所在城市", "如：林昊 · 北京", "当前职业身份", "如：AI 产品经理")
        case 2: return ("最具代表性的专业经历", "说明你的职责与真实产出", "从业年限与项目补充", "选填")
        case 3: return ("最擅长分享的科技方向", "如：生成式 AI 产品", "不适合分享的边界", "选填")
        case 4: return ("可提供的服务", "课程 / 项目指导 / 职业交流", "可服务城市与时间", "选填")
        case 5: return ("与青少年沟通或指导经历", "请说明对象、方式与结果", "监护人协作经验", "选填")
        case 6: return ("可核验的证明资料", "职业、项目或资格证明说明", "资料核验备注", "请勿填写证件号码")
        default: return ("申请承诺", "确认信息真实并遵守未成年人保护规则", "提交前补充说明", "选填")
        }
    }
}
