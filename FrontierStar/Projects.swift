import UIKit

final class ProjectsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var selectedCategory = "全部"
    private var visibleProjects: [FrontierProject] { AppStore.shared.discoverableProjects.filter { selectedCategory == "全部" || $0.category == selectedCategory } }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FSColor.canvas
        buildUI()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .appStateDidChange, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reload()
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

    private func buildUI() {
        tableView.backgroundColor = FSColor.canvas
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProjectCell.self, forCellReuseIdentifier: ProjectCell.reuseIdentifier)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 18, right: 0)
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
    }

    private func makeHeader() -> UIView {
        let headerWidth = max(tableView.bounds.width, UIScreen.main.bounds.width)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: headerWidth, height: 275))
        let logo = FSLogoView()
        let title = UILabel.fs("和真正做前沿的人\n一起完成一个项目", font: FSFont.display(30), lines: 2)
        let subtitle = UILabel.fs("平台审核后上线 · 提交意向后人工确认", font: FSFont.caption(13), color: FSColor.secondaryInk)
        let search = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "magnifyingglass")
        config.title = "搜索项目、方向或引路人"
        config.imagePadding = 9
        config.baseBackgroundColor = .white
        config.baseForegroundColor = FSColor.secondaryInk
        config.cornerStyle = .capsule
        search.configuration = config
        search.contentHorizontalAlignment = .leading
        search.heightAnchor.constraint(equalToConstant: 45).isActive = true
        search.addAction(UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(ProjectSearchViewController(), animated: true)
        }, for: .touchUpInside)
        let text = UIStackView(arrangedSubviews: [logo, title, subtitle, search])
        text.axis = .vertical
        text.spacing = 10
        text.setCustomSpacing(19, after: logo)
        header.addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: header.safeAreaLayoutGuide.topAnchor, constant: 12),
            text.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            text.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -20)
        ])

        let categories = ["全部", "AI 与大模型", "机器人", "无人机", "科技职业启蒙"]
        let chips = UIStackView()
        chips.axis = .horizontal
        chips.spacing = 8
        categories.forEach { category in
            let button = FSChoiceButton(title: category)
            button.choiceSelected = category == selectedCategory
            button.addAction(UIAction { [weak self, weak button] _ in
                self?.selectedCategory = category
                chips.arrangedSubviews.compactMap { $0 as? FSChoiceButton }.forEach { $0.choiceSelected = $0 === button }
                self?.tableView.reloadData()
            }, for: .touchUpInside)
            chips.addArrangedSubview(button)
        }
        let chipScroll = UIScrollView()
        chipScroll.showsHorizontalScrollIndicator = false
        chipScroll.addSubview(chips)
        chips.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chips.topAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.topAnchor), chips.bottomAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.bottomAnchor),
            chips.leadingAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.leadingAnchor, constant: 20), chips.trailingAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.trailingAnchor, constant: -20),
            chips.heightAnchor.constraint(equalTo: chipScroll.frameLayoutGuide.heightAnchor)
        ])
        header.addSubview(chipScroll)
        chipScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chipScroll.leadingAnchor.constraint(equalTo: header.leadingAnchor), chipScroll.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            chipScroll.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -3), chipScroll.heightAnchor.constraint(equalToConstant: 43)
        ])
        return header
    }

    @objc private func reload() { tableView.reloadData() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { visibleProjects.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 248 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProjectCell.reuseIdentifier, for: indexPath) as! ProjectCell
        cell.configure(visibleProjects[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(ProjectDetailViewController(project: visibleProjects[indexPath.row]), animated: true)
    }
}

final class ProjectSearchViewController: UITableViewController, UISearchResultsUpdating {
    private var results = AppStore.shared.discoverableProjects
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: "搜索项目")
        navigationController?.setNavigationBarHidden(false, animated: false)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "项目、方向、城市或引路人"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        tableView.backgroundColor = FSColor.canvas
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "project-result")
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let projects = AppStore.shared.discoverableProjects
        results = query.isEmpty ? projects : projects.filter {
            [$0.title, $0.guide, $0.guideRole, $0.category, $0.city, $0.format]
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(query)
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { results.count }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 92 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let project = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "project-result", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = project.title
        config.secondaryText = "\(project.category) · \(project.city) · \(project.guide)"
        config.image = UIImage(systemName: project.symbol)
        config.imageProperties.tintColor = FSColor.accent
        config.textProperties.font = FSFont.headline(15)
        config.secondaryTextProperties.font = FSFont.caption(12)
        config.secondaryTextProperties.color = FSColor.secondaryInk
        cell.contentConfiguration = config
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(ProjectDetailViewController(project: results[indexPath.row]), animated: true)
    }
}

final class ProjectCell: UITableViewCell {
    static let reuseIdentifier = "ProjectCell"
    private let card = FSCardView(radius: 24)
    private var artwork: FSArtworkView?
    private let titleLabel = UILabel.fs("", font: FSFont.title(20), lines: 2)
    private let guideLabel = UILabel.fs("", font: FSFont.caption(13), color: FSColor.secondaryInk)
    private let detailLabel = UILabel.fs("", font: FSFont.caption(12), color: FSColor.secondaryInk, lines: 2)
    private let statusLabel = UILabel.fs("", font: FSFont.caption(11), color: FSColor.success)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(card)
        card.pinEdges(to: contentView, insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        card.layer.borderColor = FSColor.line.cgColor
        card.layer.borderWidth = 1
        card.addShadow(opacity: 0.04, radius: 12, y: 4)

        let artHolder = UIView()
        artHolder.layer.cornerRadius = 19
        artHolder.layer.cornerCurve = .continuous
        artHolder.clipsToBounds = true
        let category = UILabel.fs("精选项目", font: FSFont.caption(10), color: FSColor.accent)
        category.backgroundColor = FSColor.palePurple
        category.textAlignment = .center
        category.layer.cornerRadius = 11
        category.clipsToBounds = true
        category.heightAnchor.constraint(equalToConstant: 23).isActive = true
        category.widthAnchor.constraint(equalToConstant: 70).isActive = true
        statusLabel.backgroundColor = FSColor.mint
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 11
        statusLabel.clipsToBounds = true
        statusLabel.heightAnchor.constraint(equalToConstant: 23).isActive = true
        statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        let badges = UIStackView(arrangedSubviews: [category, statusLabel, UIView()])
        badges.spacing = 7
        let arrow = UIImageView(image: UIImage(systemName: "arrow.up.right"))
        arrow.tintColor = FSColor.tertiaryInk
        let bottom = UIStackView(arrangedSubviews: [detailLabel, UIView(), arrow])
        bottom.alignment = .center
        let text = UIStackView(arrangedSubviews: [badges, titleLabel, guideLabel, UIView(), bottom])
        text.axis = .vertical
        text.spacing = 8
        let row = UIStackView(arrangedSubviews: [artHolder, text])
        row.spacing = 15
        card.addSubview(row)
        row.pinEdges(to: card, insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        artHolder.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.34).isActive = true
        artHolder.tag = 99
    }

    override func prepareForReuse() { super.prepareForReuse(); artwork?.removeFromSuperview(); artwork = nil }

    func configure(_ project: FrontierProject) {
        guard let holder = card.viewWithTag(99) else { return }
        let art = FSArtworkView(symbol: project.symbol, colors: project.colors)
        holder.addSubview(art)
        art.pinEdges(to: holder)
        artwork = art
        titleLabel.text = project.title
        guideLabel.text = "\(project.guide) · \(project.guideRole)"
        detailLabel.text = "\(project.duration) · \(project.format)\n\(project.age) · \(project.city)"
        statusLabel.text = "  \(project.status)  "
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class ProjectDetailViewController: UIViewController {
    private let project: FrontierProject
    private let applyButton = FSPrimaryButton(title: "申请参加", symbol: "arrow.up.right")
    init(project: FrontierProject) { self.project = project; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: "项目详情")
        navigationController?.setNavigationBarHidden(false, animated: false)
        buildUI()
        refreshApplicationState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshApplicationState()
    }

    private func buildUI() {
        let scroll = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let hero = FSArtworkView(symbol: project.symbol, colors: project.colors)
        hero.layer.cornerRadius = 26
        hero.layer.cornerCurve = .continuous
        hero.clipsToBounds = true
        hero.heightAnchor.constraint(equalToConstant: 280).isActive = true
        let tags = UIStackView(arrangedSubviews: [FSMetadataPill(symbol: "sparkles", text: project.category), FSMetadataPill(symbol: "person.2", text: project.age), UIView()])
        tags.spacing = 8
        let title = UILabel.fs(project.title, font: FSFont.display(30), lines: 0)
        let guide = makeGuideCard()
        let summary = UILabel.fs(project.summary, font: FSFont.body(16), color: FSColor.secondaryInk, lines: 0)
        let details = makeDetailCard()
        let highlights = makeHighlights()
        let safety = FSCardView(background: UIColor(hex: 0xFFF0E2), radius: 18)
        let safetyText = UILabel.fs("线下项目由平台确认具体地点、监护人陪同要求与安全事项。提交申请不会直接产生费用。", font: FSFont.caption(13), color: UIColor(hex: 0x8A5623), lines: 0)
        safety.addSubview(safetyText)
        safetyText.pinEdges(to: safety, insets: UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16))
        applyButton.addAction(UIAction { [weak self] _ in self?.apply() }, for: .touchUpInside)
        let consult = UIButton(type: .system)
        consult.setTitle("咨询是否适合", for: .normal)
        consult.titleLabel?.font = FSFont.headline(15)
        consult.setTitleColor(FSColor.accent, for: .normal)
        consult.addAction(UIAction { [weak self] _ in self?.consult() }, for: .touchUpInside)
        stack.addArrangedSubviews(hero, tags, title, guide, summary, details, highlights, safety, applyButton, consult)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor), scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8), stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    private func makeGuideCard() -> UIView {
        let button = UIButton(type: .system)
        button.accessibilityLabel = "查看引路人 \(project.guide) 的资料"
        button.accessibilityHint = project.guideRole
        button.backgroundColor = .white
        button.layer.cornerRadius = 19
        button.layer.cornerCurve = .continuous
        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = FSColor.accent
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([avatar.widthAnchor.constraint(equalToConstant: 46), avatar.heightAnchor.constraint(equalToConstant: 46)])
        let name = UILabel.fs(project.guide, font: FSFont.headline(16))
        let role = UILabel.fs("引路人 · \(project.guideRole)", font: FSFont.caption(12), color: FSColor.secondaryInk)
        let text = UIStackView(arrangedSubviews: [name, role]); text.axis = .vertical; text.spacing = 3
        let verified = UIImageView(image: UIImage(systemName: "checkmark.seal.fill")); verified.tintColor = FSColor.accent
        let row = UIStackView(arrangedSubviews: [avatar, text, UIView(), verified, UIImageView(image: UIImage(systemName: "chevron.right"))])
        row.spacing = 10; row.alignment = .center; row.isUserInteractionEnabled = false
        button.addSubview(row); row.pinEdges(to: button, insets: UIEdgeInsets(top: 12, left: 13, bottom: 12, right: 13))
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let profile = AppStore.shared.guides[self.project.guide] ?? GuideProfile(name: self.project.guide, role: self.project.guideRole, city: self.project.city, bio: "专注把真实项目经验转化为青少年可以理解和实践的前沿科技体验。", avatarSymbol: "person.crop.circle.fill", tags: [self.project.category, "项目实践", self.project.age], verification: ["身份已核验", "服务方案已审核"], courses: 2, participants: 16, reviews: 7, rating: 4.8)
            self.navigationController?.pushViewController(GuideDetailViewController(profile: profile), animated: true)
        }, for: .touchUpInside)
        return button
    }

    private func makeDetailCard() -> UIView {
        let card = FSCardView(radius: 20)
        let rows = [("周期", project.duration), ("方式", project.format), ("城市", project.city), ("时间", project.schedule), ("状态", project.status)]
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 12
        rows.forEach { key, value in
            let keyLabel = UILabel.fs(key, font: FSFont.caption(12), color: FSColor.tertiaryInk)
            let valueLabel = UILabel.fs(value, font: FSFont.headline(14), lines: 0); valueLabel.textAlignment = .right
            stack.addArrangedSubview(UIStackView(arrangedSubviews: [keyLabel, UIView(), valueLabel]))
        }
        card.addSubview(stack); stack.pinEdges(to: card, insets: UIEdgeInsets(top: 17, left: 17, bottom: 17, right: 17))
        return card
    }

    private func makeHighlights() -> UIView {
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 11
        stack.addArrangedSubview(UILabel.fs("体验重点", font: FSFont.title(22)))
        project.highlights.forEach { item in
            let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")); icon.tintColor = FSColor.success
            icon.translatesAutoresizingMaskIntoConstraints = false; icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
            stack.addArrangedSubview(UIStackView(arrangedSubviews: [icon, UILabel.fs(item, font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0)]))
        }
        return stack
    }

    private func apply() {
        let action: () -> Void = { [weak self] in
            guard let self else { return }
            AppStore.shared.apply(to: self.project)
            self.refreshApplicationState()
            self.showToast("申请已提交，可在“我的预约”查看进度", symbol: "paperplane.fill")
        }
        if AppStore.shared.activeRole == .visitor || !AppStore.shared.isLoggedIn { AuthGate.require(role: .parent, from: self, completion: action) }
        else { action() }
    }

    private func refreshApplicationState() {
        let applied = AppStore.shared.appliedProjectIDs.contains(project.id)
        applyButton.configuration?.title = applied ? "已提交申请" : "申请参加"
        applyButton.configuration?.image = UIImage(systemName: applied ? "checkmark" : "arrow.up.right")
        applyButton.isEnabled = !applied
    }

    private func consult() {
        let action: () -> Void = { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(
                DemandComposerViewController(specifiedGuide: self.project.guide),
                animated: true
            )
        }
        if AppStore.shared.activeRole == .visitor || !AppStore.shared.isLoggedIn {
            AuthGate.require(role: .parent, from: self, completion: action)
        } else {
            action()
        }
    }
}

final class GuideDetailViewController: UIViewController {
    private let profile: GuideProfile
    init(profile: GuideProfile) { self.profile = profile; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: "引路人")
        navigationController?.setNavigationBarHidden(false, animated: false)
        buildUI()
    }

    private func buildUI() {
        let (_, stack) = makeScrollStack(in: self, bottom: 34)
        let hero = FSCardView(background: FSColor.ink, radius: 28)
        let avatar = UIImageView(image: UIImage(systemName: profile.avatarSymbol))
        avatar.tintColor = UIColor(hex: 0xA99DFF)
        avatar.contentMode = .scaleAspectFit
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([avatar.widthAnchor.constraint(equalToConstant: 76), avatar.heightAnchor.constraint(equalToConstant: 76)])
        let verified = UILabel.fs("  ✓ 平台已认证  ", font: FSFont.caption(11), color: .white)
        verified.backgroundColor = FSColor.success
        verified.layer.cornerRadius = 12; verified.clipsToBounds = true; verified.textAlignment = .center; verified.heightAnchor.constraint(equalToConstant: 25).isActive = true
        let name = UILabel.fs(profile.name, font: FSFont.display(31), color: .white)
        let role = UILabel.fs("\(profile.role) · \(profile.city)", font: FSFont.body(15), color: UIColor.white.withAlphaComponent(0.72))
        let identity = UIStackView(arrangedSubviews: [name, role, verified]); identity.axis = .vertical; identity.spacing = 6; identity.alignment = .leading
        let top = UIStackView(arrangedSubviews: [avatar, identity]); top.spacing = 15; top.alignment = .center
        let stats = UIStackView(); stats.distribution = .fillEqually
        [("\(profile.courses)", "已开设课程"), ("\(profile.participants)", "完成参与"), (String(format: "%.1f", profile.rating), "真实评分")].forEach { number, label in
            let n = UILabel.fs(number, font: FSFont.title(23), color: .white); n.textAlignment = .center
            let l = UILabel.fs(label, font: FSFont.caption(10), color: UIColor.white.withAlphaComponent(0.6)); l.textAlignment = .center
            let column = UIStackView(arrangedSubviews: [n, l]); column.axis = .vertical; column.spacing = 3
            stats.addArrangedSubview(column)
        }
        let heroStack = UIStackView(arrangedSubviews: [top, stats]); heroStack.axis = .vertical; heroStack.spacing = 23
        hero.addSubview(heroStack); heroStack.pinEdges(to: hero, insets: UIEdgeInsets(top: 22, left: 20, bottom: 22, right: 20))
        stack.addArrangedSubview(hero)

        stack.addArrangedSubview(section(title: "他真正做过什么", body: profile.bio))
        let tagSection = UIStackView(arrangedSubviews: [UILabel.fs("擅长与适合", font: FSFont.title(22)), FSTagListView(tags: profile.tags)])
        tagSection.axis = .vertical; tagSection.spacing = 12
        stack.addArrangedSubview(tagSection)

        let verifyCard = FSCardView(radius: 21)
        let verifyStack = UIStackView(); verifyStack.axis = .vertical; verifyStack.spacing = 12
        verifyStack.addArrangedSubview(UILabel.fs("平台核验", font: FSFont.title(20)))
        profile.verification.forEach { item in
            let icon = UIImageView(image: UIImage(systemName: "checkmark.seal.fill")); icon.tintColor = FSColor.success; icon.translatesAutoresizingMaskIntoConstraints = false; icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
            verifyStack.addArrangedSubview(UIStackView(arrangedSubviews: [icon, UILabel.fs(item, font: FSFont.body(14), color: FSColor.secondaryInk)]))
        }
        verifyCard.addSubview(verifyStack); verifyStack.pinEdges(to: verifyCard, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        stack.addArrangedSubview(verifyCard)

        let courseTitle = UILabel.fs("他的课程", font: FSFont.title(22))
        stack.addArrangedSubview(courseTitle)
        let courses = AppStore.shared.courses.filter { $0.instructor == profile.name }
        if courses.isEmpty {
            stack.addArrangedSubview(UILabel.fs("已审核课程正在准备上架", font: FSFont.body(14), color: FSColor.secondaryInk))
        } else {
            courses.prefix(3).forEach { course in
                let button = UIButton(type: .system)
                button.accessibilityLabel = "查看课程 \(course.title.replacingOccurrences(of: "\n", with: " "))"
                button.backgroundColor = .white; button.layer.cornerRadius = 17; button.layer.cornerCurve = .continuous
                let label = UILabel.fs(course.title.replacingOccurrences(of: "\n", with: " "), font: FSFont.headline(15), lines: 2)
                let meta = UILabel.fs("\(course.duration) · \(course.age)", font: FSFont.caption(12), color: FSColor.secondaryInk)
                let text = UIStackView(arrangedSubviews: [label, meta]); text.axis = .vertical; text.spacing = 4
                let row = UIStackView(arrangedSubviews: [text, UIView(), UIImageView(image: UIImage(systemName: "chevron.right"))]); row.isUserInteractionEnabled = false
                button.addSubview(row); row.pinEdges(to: button, insets: UIEdgeInsets(top: 14, left: 15, bottom: 14, right: 15))
                button.addAction(UIAction { [weak self] _ in self?.navigationController?.pushViewController(CourseDetailViewController(course: course), animated: true) }, for: .touchUpInside)
                stack.addArrangedSubview(button)
            }
        }

        let reviewCard = FSCardView(background: FSColor.mint, radius: 20)
        let review = UILabel.fs("“讲得很清楚，孩子回家还在继续调整自己的作品。我们更喜欢这种先体验、再决定是否深入的方式。”\n\n— 完成服务的家长 · 匿名评价", font: FSFont.body(14), color: UIColor(hex: 0x315F50), lines: 0)
        reviewCard.addSubview(review); review.pinEdges(to: reviewCard, insets: UIEdgeInsets(top: 17, left: 17, bottom: 17, right: 17))
        stack.addArrangedSubview(reviewCard)

        let consult = FSPrimaryButton(title: "咨询是否适合孩子", symbol: "text.bubble")
        consult.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let action: () -> Void = {
                self.navigationController?.pushViewController(DemandComposerViewController(specifiedGuide: self.profile.name), animated: true)
            }
            if AppStore.shared.activeRole == .visitor || !AppStore.shared.isLoggedIn { AuthGate.require(role: .parent, from: self, completion: action) } else { action() }
        }, for: .touchUpInside)
        stack.addArrangedSubview(consult)
        let disclaimer = UILabel.fs("引路人以个人身份分享，不代表其任职或曾任职单位提供官方背书。", font: FSFont.caption(11), color: FSColor.tertiaryInk, lines: 0)
        disclaimer.textAlignment = .center
        stack.addArrangedSubview(disclaimer)
    }

    private func section(title: String, body: String) -> UIView {
        let stack = UIStackView(arrangedSubviews: [UILabel.fs(title, font: FSFont.title(22)), UILabel.fs(body, font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0)])
        stack.axis = .vertical; stack.spacing = 10
        return stack
    }
}
