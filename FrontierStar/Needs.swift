import UIKit

final class NeedsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var needs: [ParentNeed] {
        switch AppStore.shared.activeRole {
        case .parent: return AppStore.shared.needs
        case .guide:
            return AppStore.shared.needs + [
                ParentNeed(id: "N20260728017", title: "为 10 岁零基础孩子寻找机器人体验", anonymousName: "上海家长 0718", age: "10 岁", city: "上海", interests: ["机器人", "机械结构", "动手制作"], foundation: "零基础，但喜欢拆装玩具", goal: "先完成一次真实项目体验，了解是否有持续兴趣", format: "线下小组", schedule: "周日上午", budget: "¥800–1,500", scope: "向已认证引路人展示", status: .matching, createdAt: "昨天 18:20"),
                ParentNeed(id: "N20260727009", title: "寻找科技职业与方向交流", anonymousName: "深圳家长 1406", age: "15 岁", city: "深圳", interests: ["算法", "产品设计", "AI"], foundation: "持续学习 Python，做过简单数据项目", goal: "了解不同科技职业的真实工作，辅助高中阶段方向判断", format: "在线一对一", schedule: "工作日晚间", budget: "愿意沟通", scope: "向已认证引路人展示", status: .matching, createdAt: "7 月 27 日")
            ]
        case .visitor: return []
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FSColor.canvas
        buildUI()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .appStateDidChange, object: nil)
    }
    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let isRootTab = navigationController?.viewControllers.first === self
        if isRootTab {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        } else {
            configureLightNavigation(title: AppStore.shared.activeRole == .guide ? "需求大厅" : "我的需求")
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
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
        tableView.register(NeedCell.self, forCellReuseIdentifier: NeedCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
        updateEmptyState()
    }

    private func makeHeader() -> UIView {
        let headerWidth = max(tableView.bounds.width, UIScreen.main.bounds.width)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: headerWidth, height: 195))
        let logo = FSLogoView()
        let role = AppStore.shared.activeRole
        let eyebrow = UILabel.fs(role == .guide ? "仅展示经家长授权的脱敏信息" : "人工匹配 · 过程可见", font: FSFont.caption(12), color: FSColor.accent)
        let title = UILabel.fs(role == .guide ? "需求大厅" : role == .visitor ? "说说孩子的好奇心" : "我的需求", font: FSFont.display(31))
        let subtitle = UILabel.fs(role == .guide ? "找到与你真实经验相匹配的家庭需求" : role == .visitor ? "告诉我们年龄、兴趣和目标，平台会寻找合适的引路人" : "从受理到推荐，每一步都有清晰进度", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 2)
        let stack = UIStackView(arrangedSubviews: [logo, eyebrow, title, subtitle])
        stack.axis = .vertical; stack.spacing = 9; stack.setCustomSpacing(22, after: logo)
        header.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: header.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -20)
        ])
        return header
    }

    private func updateEmptyState() {
        guard needs.isEmpty else { tableView.backgroundView = nil; return }
        let holder = UIView()
        let icon = UIImageView(image: UIImage(systemName: "sparkles.rectangle.stack"))
        icon.tintColor = FSColor.accent
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 58).isActive = true
        let title = UILabel.fs("还没有发布需求", font: FSFont.title(21)); title.textAlignment = .center
        let text = UILabel.fs("发布需求后，平台顾问会先了解孩子情况，再筛选 1–3 位合适的引路人。", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 0); text.textAlignment = .center
        let button = FSPrimaryButton(title: "发布孩子需求", symbol: "plus")
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            AuthGate.require(role: .parent, from: self) { self.navigationController?.pushViewController(DemandComposerViewController(), animated: true) }
        }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [icon, title, text, button]); stack.axis = .vertical; stack.spacing = 14
        holder.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: holder.leadingAnchor, constant: 35), stack.trailingAnchor.constraint(equalTo: holder.trailingAnchor, constant: -35), stack.topAnchor.constraint(equalTo: holder.topAnchor, constant: 34)])
        tableView.backgroundView = holder
    }

    @objc private func reload() {
        if tableView.bounds.width > 0 { tableView.tableHeaderView = makeHeader() }
        tableView.reloadData()
        updateEmptyState()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { needs.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 260 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NeedCell.reuseIdentifier, for: indexPath) as! NeedCell
        cell.configure(needs[indexPath.row], guideMode: AppStore.shared.activeRole == .guide)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(NeedDetailViewController(need: needs[indexPath.row], guideMode: AppStore.shared.activeRole == .guide), animated: true)
    }
}

final class NeedCell: UITableViewCell {
    static let reuseIdentifier = "NeedCell"
    private let card = FSCardView(radius: 23)
    private let titleLabel = UILabel.fs("", font: FSFont.title(19), lines: 2)
    private let metaLabel = UILabel.fs("", font: FSFont.caption(12), color: FSColor.secondaryInk, lines: 2)
    private let goalLabel = UILabel.fs("", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 2)
    private let tags = UIStackView()
    private let stateLabel = UILabel.fs("", font: FSFont.caption(11), color: FSColor.accentDark)
    private let identityLabel = UILabel.fs("", font: FSFont.caption(12), color: FSColor.secondaryInk)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear; selectionStyle = .none
        contentView.addSubview(card); card.pinEdges(to: contentView, insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        card.layer.borderWidth = 1; card.layer.borderColor = FSColor.line.cgColor; card.addShadow(opacity: 0.035, radius: 12, y: 4)
        let shield = UIImageView(image: UIImage(systemName: "lock.shield.fill")); shield.tintColor = FSColor.success
        let identity = UIStackView(arrangedSubviews: [shield, identityLabel, UIView(), stateLabel]); identity.spacing = 7; identity.alignment = .center
        stateLabel.backgroundColor = FSColor.palePurple; stateLabel.layer.cornerRadius = 11; stateLabel.clipsToBounds = true; stateLabel.textAlignment = .center; stateLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        tags.axis = .horizontal; tags.spacing = 7
        let arrow = UIImageView(image: UIImage(systemName: "arrow.right")); arrow.tintColor = FSColor.tertiaryInk
        let footer = UIStackView(arrangedSubviews: [metaLabel, UIView(), arrow]); footer.alignment = .center
        let stack = UIStackView(arrangedSubviews: [identity, titleLabel, tags, goalLabel, UIView(), footer]); stack.axis = .vertical; stack.spacing = 11
        card.addSubview(stack); stack.pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 17, bottom: 16, right: 17))
    }

    override func prepareForReuse() { super.prepareForReuse(); tags.arrangedSubviews.forEach { $0.removeFromSuperview() } }
    func configure(_ need: ParentNeed, guideMode: Bool) {
        identityLabel.text = guideMode ? need.anonymousName : "需求编号 · \(need.id)"
        titleLabel.text = need.title
        goalLabel.text = need.goal
        metaLabel.text = "\(need.city) · \(need.format) · \(need.schedule)"
        stateLabel.text = "  \(need.status.rawValue)  "
        need.interests.prefix(3).forEach { tag in
            let label = UILabel.fs("  \(tag)  ", font: FSFont.caption(11), color: FSColor.accentDark)
            label.backgroundColor = FSColor.palePurple; label.layer.cornerRadius = 11; label.clipsToBounds = true; label.heightAnchor.constraint(equalToConstant: 24).isActive = true
            tags.addArrangedSubview(label)
        }
        tags.addArrangedSubview(UIView())
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class NeedDetailViewController: UIViewController {
    private let need: ParentNeed
    private let guideMode: Bool
    init(need: ParentNeed, guideMode: Bool) { self.need = need; self.guideMode = guideMode; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: guideMode ? "脱敏需求" : "需求详情")
        navigationController?.setNavigationBarHidden(false, animated: false)
        buildUI()
    }

    private func buildUI() {
        let (_, stack) = makeScrollStack(in: self, bottom: 34)
        let status = FSCardView(background: guideMode ? FSColor.mint : FSColor.palePurple, radius: 22)
        let icon = UIImageView(image: UIImage(systemName: guideMode ? "lock.shield.fill" : "point.3.filled.connected.trianglepath.dotted")); icon.tintColor = guideMode ? FSColor.success : FSColor.accent
        icon.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([icon.widthAnchor.constraint(equalToConstant: 35), icon.heightAnchor.constraint(equalToConstant: 35)])
        let title = UILabel.fs(guideMode ? "已脱敏，仅限匹配用途" : need.status.rawValue, font: FSFont.title(20))
        let text = UILabel.fs(guideMode ? "联系方式、学校与详细地址均不可见" : "平台顾问正在跟进，状态变化会通过消息通知你", font: FSFont.caption(12), color: FSColor.secondaryInk, lines: 0)
        let labels = UIStackView(arrangedSubviews: [title, text]); labels.axis = .vertical; labels.spacing = 4
        let row = UIStackView(arrangedSubviews: [icon, labels]); row.spacing = 12; row.alignment = .center
        status.addSubview(row); row.pinEdges(to: status, insets: UIEdgeInsets(top: 17, left: 17, bottom: 17, right: 17))
        stack.addArrangedSubview(status)
        stack.addArrangedSubview(UILabel.fs(need.title, font: FSFont.display(29), lines: 0))
        stack.addArrangedSubview(makeInfoCard())
        stack.addArrangedSubview(section(title: "孩子的兴趣与基础", body: "兴趣：\(need.interests.joined(separator: "、"))\n基础：\(need.foundation)"))
        stack.addArrangedSubview(section(title: "家长期望", body: need.goal))

        if guideMode {
            let notice = UILabel.fs("你当前只能看到需求大厅级别的信息。表达意愿后，平台会先征得家长单独授权，再决定是否提供更多必要信息。", font: FSFont.caption(13), color: FSColor.secondaryInk, lines: 0)
            notice.backgroundColor = UIColor(hex: 0xEEEDE8); notice.layer.cornerRadius = 16; notice.clipsToBounds = true
            let wrapper = UIView(); wrapper.addSubview(notice); notice.pinEdges(to: wrapper, insets: UIEdgeInsets(top: 14, left: 15, bottom: 14, right: 15))
            stack.addArrangedSubview(wrapper)
            let interested = FSPrimaryButton(title: "愿意进一步了解", symbol: "hand.raised.fill")
            let expressed = AppStore.shared.interestedNeedIDs.contains(need.id)
            interested.configuration?.title = expressed ? "意向已提交" : "愿意进一步了解"
            interested.configuration?.image = UIImage(systemName: expressed ? "checkmark" : "hand.raised.fill")
            interested.isEnabled = !expressed
            interested.addAction(UIAction { [weak self, weak interested] _ in
                guard let self else { return }
                AppStore.shared.expressInterest(in: self.need)
                interested?.configuration?.title = "意向已提交"
                interested?.configuration?.image = UIImage(systemName: "checkmark")
                interested?.isEnabled = false
                self.showToast("意向已提交，平台将先联系家长", symbol: "checkmark.seal.fill")
            }, for: .touchUpInside)
            stack.addArrangedSubview(interested)
        } else {
            stack.addArrangedSubview(makeTimeline())
            if need.status == .recommended { stack.addArrangedSubview(makeRecommendation()) }
            let contact = FSPrimaryButton(title: "联系平台顾问", symbol: "headphones")
            contact.addAction(UIAction { [weak self] _ in self?.showToast("课程顾问会在方便联系时段回电", symbol: "phone.fill") }, for: .touchUpInside)
            stack.addArrangedSubview(contact)
        }
    }

    private func makeInfoCard() -> UIView {
        let card = FSCardView(radius: 20)
        let rows = [("孩子年龄", need.age), ("所在城市", need.city), ("服务方式", need.format), ("期望时间", need.schedule), ("预算说明", need.budget), ("公开范围", need.scope)]
        let list = UIStackView(); list.axis = .vertical; list.spacing = 12
        rows.forEach { key, value in
            let keyLabel = UILabel.fs(key, font: FSFont.caption(12), color: FSColor.tertiaryInk)
            let valueLabel = UILabel.fs(value, font: FSFont.headline(14), lines: 0); valueLabel.textAlignment = .right
            list.addArrangedSubview(UIStackView(arrangedSubviews: [keyLabel, UIView(), valueLabel]))
        }
        card.addSubview(list); list.pinEdges(to: card, insets: UIEdgeInsets(top: 17, left: 17, bottom: 17, right: 17))
        return card
    }

    private func section(title: String, body: String) -> UIView {
        let stack = UIStackView(arrangedSubviews: [UILabel.fs(title, font: FSFont.title(21)), UILabel.fs(body, font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0)])
        stack.axis = .vertical; stack.spacing = 9; return stack
    }

    private func makeTimeline() -> UIView {
        let list = UIStackView(); list.axis = .vertical; list.spacing = 13
        list.addArrangedSubview(UILabel.fs("匹配进度", font: FSFont.title(21)))
        let stages = [("checkmark", "需求已受理", true), ("checkmark", "需求已脱敏审核", true), ("person.2", "已筛选 2 位候选引路人", need.status == .recommended), ("calendar", "确认预约", false)]
        stages.forEach { symbol, title, complete in
            let dot = UIImageView(image: UIImage(systemName: complete ? "checkmark.circle.fill" : symbol)); dot.tintColor = complete ? FSColor.success : FSColor.tertiaryInk
            dot.translatesAutoresizingMaskIntoConstraints = false; dot.widthAnchor.constraint(equalToConstant: 22).isActive = true
            let label = UILabel.fs(title, font: FSFont.body(14), color: complete ? FSColor.ink : FSColor.secondaryInk)
            list.addArrangedSubview(UIStackView(arrangedSubviews: [dot, label]))
        }
        return list
    }

    private func makeRecommendation() -> UIView {
        let card = FSCardView(background: FSColor.ink, radius: 23)
        let eyebrow = UILabel.fs("推荐方案 1 / 2", font: FSFont.caption(11), color: UIColor.white.withAlphaComponent(0.62))
        let title = UILabel.fs("林昊 · AI 产品专家", font: FSFont.title(20), color: .white)
        let reason = UILabel.fs("推荐理由：有真实 AI 产品经历，擅长把抽象概念转化为 10–15 岁可以完成的小项目。", font: FSFont.body(14), color: UIColor.white.withAlphaComponent(0.74), lines: 0)
        let action = FSSecondaryButton(title: "查看推荐方案", symbol: "arrow.right")
        action.addAction(UIAction { [weak self] _ in
            guard let self, let profile = AppStore.shared.guides["林昊"] else { return }
            self.navigationController?.pushViewController(GuideDetailViewController(profile: profile), animated: true)
        }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [eyebrow, title, reason, action]); stack.axis = .vertical; stack.spacing = 11
        card.addSubview(stack); stack.pinEdges(to: card, insets: UIEdgeInsets(top: 19, left: 18, bottom: 18, right: 18))
        return card
    }
}

private struct DemandDraft {
    var age = "12"
    var city = "北京"
    var interests: Set<String> = ["AI 与大模型"]
    var foundation = "接触过"
    var goal = "完成一个项目"
    var format = "线下小组"
    var schedule = "周末下午"
    var budget = "¥2,000–4,000"
    var contact = "家长"
    var scope = "仅平台匹配"
}

final class DemandComposerViewController: UIViewController {
    private var stage = 0
    private var draft = DemandDraft()
    private let specifiedGuide: String?
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var ageField: FSFormField?
    private var cityField: FSFormField?
    private var contactField: FSFormField?

    init(specifiedGuide: String? = nil) { self.specifiedGuide = specifiedGuide; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: "发布需求")
        navigationController?.setNavigationBarHidden(false, animated: false)
        scroll.keyboardDismissMode = .interactive
        stack.axis = .vertical; stack.spacing = 18
        view.addSubview(scroll); scroll.pinEdges(to: view)
        scroll.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 18), stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20)
        ])
        renderStage()
    }

    private func renderStage() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = FSColor.accent; progress.trackTintColor = FSColor.line; progress.setProgress(Float(stage + 1) / 3, animated: true)
        let step = UILabel.fs("第 \(stage + 1) 步，共 3 步", font: FSFont.caption(12), color: FSColor.accent)
        stack.addArrangedSubviews(step, progress)
        stack.setCustomSpacing(20, after: progress)
        if stage == 0 { renderChildStage() }
        else if stage == 1 { renderGoalStage() }
        else { renderContactStage() }
        let next = FSPrimaryButton(title: stage == 2 ? "提交需求" : "下一步", symbol: stage == 2 ? "paperplane.fill" : "arrow.right")
        next.addAction(UIAction { [weak self] _ in self?.advance() }, for: .touchUpInside)
        stack.addArrangedSubview(next)
        if stage > 0 {
            let previous = UIButton(type: .system); previous.setTitle("返回上一步", for: .normal); previous.setTitleColor(FSColor.secondaryInk, for: .normal); previous.titleLabel?.font = FSFont.headline(14)
            previous.addAction(UIAction { [weak self] _ in self?.goBack() }, for: .touchUpInside)
            stack.addArrangedSubview(previous)
        }
        scroll.setContentOffset(.zero, animated: false)
    }

    private func renderChildStage() {
        stack.addArrangedSubview(UILabel.fs("先了解孩子现在的情况", font: FSFont.display(29), lines: 0))
        stack.addArrangedSubview(UILabel.fs("不收集真实姓名、学校和详细住址", font: FSFont.body(14), color: FSColor.secondaryInk))
        let age = FSFormField(title: "孩子年龄", placeholder: "周岁", keyboard: .numberPad); age.textField.text = draft.age; ageField = age
        let city = FSFormField(title: "所在城市", placeholder: "如：北京"); city.textField.text = draft.city; cityField = city
        stack.addArrangedSubviews(age, city)
        stack.addArrangedSubview(choiceGroup(title: "感兴趣的方向（可多选）", options: ["AI 与大模型", "机器人", "无人机", "编程与算法", "智能硬件"], selected: draft.interests) { [weak self] value in self?.draft.interests = value })
        stack.addArrangedSubview(singleChoiceGroup(title: "目前基础", options: ["零基础", "接触过", "做过简单项目", "持续学习中"], selected: draft.foundation) { [weak self] value in self?.draft.foundation = value })
    }

    private func renderGoalStage() {
        stack.addArrangedSubview(UILabel.fs("希望这次体验带来什么？", font: FSFont.display(29), lines: 0))
        if let specifiedGuide {
            let note = UILabel.fs("已指定咨询引路人：\(specifiedGuide)", font: FSFont.caption(13), color: FSColor.accent)
            note.backgroundColor = FSColor.palePurple; note.layer.cornerRadius = 14; note.clipsToBounds = true; note.textAlignment = .center; note.heightAnchor.constraint(equalToConstant: 40).isActive = true
            stack.addArrangedSubview(note)
        }
        stack.addArrangedSubview(singleChoiceGroup(title: "主要目标", options: ["兴趣启蒙", "体验前沿科技", "完成一个项目", "判断发展方向", "寻找长期引路人"], selected: draft.goal) { [weak self] in self?.draft.goal = $0 })
        stack.addArrangedSubview(singleChoiceGroup(title: "偏好方式", options: ["在线一对一", "线下一对一", "线下小组"], selected: draft.format) { [weak self] in self?.draft.format = $0 })
        stack.addArrangedSubview(singleChoiceGroup(title: "可安排时间", options: ["工作日晚间", "周末上午", "周末下午", "寒暑假"], selected: draft.schedule) { [weak self] in self?.draft.schedule = $0 })
        stack.addArrangedSubview(singleChoiceGroup(title: "预算区间（选填）", options: ["愿意沟通", "¥800–1,500", "¥2,000–4,000", "¥4,000 以上"], selected: draft.budget) { [weak self] in self?.draft.budget = $0 })
    }

    private func renderContactStage() {
        stack.addArrangedSubview(UILabel.fs("确认联系与隐私范围", font: FSFont.display(29), lines: 0))
        stack.addArrangedSubview(UILabel.fs("联系方式只供平台顾问完成匹配与履约，不会出现在需求大厅。", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 0))
        let contact = FSFormField(title: "家长称呼", placeholder: "如：林女士"); contact.textField.text = draft.contact; contactField = contact
        stack.addArrangedSubview(contact)
        let phoneCard = FSCardView(radius: 18)
        let phone = AppStore.shared.verifiedPhone.map { String($0.prefix(3)) + "****" + String($0.suffix(4)) } ?? "第三方登录用户 · 提交前需绑定手机号"
        let phoneRow = UIStackView(arrangedSubviews: [UIImageView(image: UIImage(systemName: "phone.fill")), UILabel.fs(phone, font: FSFont.body(14)), UIView(), UIImageView(image: UIImage(systemName: "checkmark.shield.fill"))]); phoneRow.spacing = 9
        phoneCard.addSubview(phoneRow); phoneRow.pinEdges(to: phoneCard, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)); stack.addArrangedSubview(phoneCard)
        stack.addArrangedSubview(singleChoiceGroup(title: "需求公开范围", options: ["仅平台匹配", "向已认证引路人展示"], selected: draft.scope) { [weak self] in self?.draft.scope = $0 })
        let privacy = FSCardView(background: FSColor.mint, radius: 18)
        let text = UILabel.fs("✓ 已同意平台为完成匹配向候选引路人提供脱敏需求摘要。孩子真实姓名、学校、照片和详细地址不会被收集或公开。", font: FSFont.caption(12), color: UIColor(hex: 0x315F50), lines: 0)
        privacy.addSubview(text); text.pinEdges(to: privacy, insets: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)); stack.addArrangedSubview(privacy)
    }

    private func choiceGroup(title: String, options: [String], selected: Set<String>, onChange: @escaping (Set<String>) -> Void) -> UIView {
        let titleLabel = UILabel.fs(title, font: FSFont.headline(15))
        let grid = UIStackView(); grid.axis = .vertical; grid.spacing = 9
        var current = selected
        stride(from: 0, to: options.count, by: 2).forEach { start in
            let row = UIStackView(); row.spacing = 9; row.distribution = .fillEqually
            for index in start..<min(start + 2, options.count) {
                let option = options[index]; let button = FSChoiceButton(title: option); button.choiceSelected = current.contains(option)
                button.addAction(UIAction { _ in button.choiceSelected.toggle(); if button.choiceSelected { current.insert(option) } else { current.remove(option) }; onChange(current) }, for: .touchUpInside)
                row.addArrangedSubview(button)
            }
            if row.arrangedSubviews.count == 1 { row.addArrangedSubview(UIView()) }
            grid.addArrangedSubview(row)
        }
        let section = UIStackView(arrangedSubviews: [titleLabel, grid]); section.axis = .vertical; section.spacing = 10; return section
    }

    private func singleChoiceGroup(title: String, options: [String], selected: String, onChange: @escaping (String) -> Void) -> UIView {
        let titleLabel = UILabel.fs(title, font: FSFont.headline(15))
        let grid = UIStackView(); grid.axis = .vertical; grid.spacing = 9
        var buttons: [FSChoiceButton] = []
        stride(from: 0, to: options.count, by: 2).forEach { start in
            let row = UIStackView(); row.spacing = 9; row.distribution = .fillEqually
            for index in start..<min(start + 2, options.count) {
                let option = options[index]; let button = FSChoiceButton(title: option); button.choiceSelected = option == selected; buttons.append(button)
                button.addAction(UIAction { _ in buttons.forEach { $0.choiceSelected = $0 === button }; onChange(option) }, for: .touchUpInside)
                row.addArrangedSubview(button)
            }
            if row.arrangedSubviews.count == 1 { row.addArrangedSubview(UIView()) }
            grid.addArrangedSubview(row)
        }
        let section = UIStackView(arrangedSubviews: [titleLabel, grid]); section.axis = .vertical; section.spacing = 10; return section
    }

    private func advance() {
        view.endEditing(true)
        if stage == 0 {
            draft.age = ageField?.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            draft.city = cityField?.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !draft.age.isEmpty, !draft.city.isEmpty, !draft.interests.isEmpty else { showToast("请完成孩子年龄、城市和兴趣方向", symbol: "exclamationmark"); return }
        }
        if stage == 2 {
            draft.contact = contactField?.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "家长"
            submit(); return
        }
        stage += 1; renderStage()
    }

    private func goBack() { view.endEditing(true); stage -= 1; renderStage() }

    private func submit() {
        let mainInterest = draft.interests.sorted().first ?? "前沿科技"
        let need = ParentNeed(id: "N\(Int(Date().timeIntervalSince1970))", title: "为 \(draft.age) 岁孩子寻找\(mainInterest)引路人", anonymousName: "\(draft.city)家长 \(Int.random(in: 1000...9999))", age: "\(draft.age) 岁", city: draft.city, interests: draft.interests.sorted(), foundation: draft.foundation, goal: draft.goal, format: draft.format, schedule: draft.schedule, budget: draft.budget, scope: draft.scope, status: .pending, createdAt: "刚刚")
        AppStore.shared.addNeed(need)
        navigationController?.pushViewController(NeedSubmittedViewController(need: need), animated: true)
    }
}

final class NeedSubmittedViewController: UIViewController {
    private let need: ParentNeed
    init(need: ParentNeed) { self.need = need; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); configureLightNavigation(); navigationItem.hidesBackButton = true
        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")); icon.tintColor = FSColor.success; icon.contentMode = .scaleAspectFit; icon.heightAnchor.constraint(equalToConstant: 76).isActive = true
        let title = UILabel.fs("需求已收到", font: FSFont.display(31)); title.textAlignment = .center
        let text = UILabel.fs("平台顾问将先了解孩子情况，再为你筛选合适的引路人。预计 24 小时内首次反馈。", font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0); text.textAlignment = .center
        let id = UILabel.fs("需求编号  \(need.id)", font: FSFont.caption(13), color: FSColor.accent); id.textAlignment = .center
        let detail = FSPrimaryButton(title: "查看需求进度", symbol: "arrow.right")
        detail.addAction(UIAction { [weak self] _ in guard let self else { return }; self.navigationController?.pushViewController(NeedDetailViewController(need: self.need, guideMode: false), animated: true) }, for: .touchUpInside)
        let home = UIButton(type: .system); home.setTitle("返回首页", for: .normal); home.titleLabel?.font = FSFont.headline(15); home.addAction(UIAction { _ in FSApp.showMain() }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [icon, title, text, id, detail, home]); stack.axis = .vertical; stack.spacing = 17
        view.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30), stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28), stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28)])
    }
}

final class ProjectComposerViewController: UIViewController {
    private let name = FSFormField(title: "项目名称", placeholder: "清晰描述孩子会做什么")
    private let intro = FSFormField(title: "一句话简介", placeholder: "用一句话说明体验价值")
    private let city = FSFormField(title: "城市 / 服务范围", placeholder: "如：北京 / 全国在线")
    private var category = "AI 与大模型"
    private var age = "10–14 岁"
    private var format = "在线一对一"

    override func viewDidLoad() {
        super.viewDidLoad()
        let draft = AppStore.shared.projectDraft()
        name.textField.text = draft["name"]
        intro.textField.text = draft["intro"]
        city.textField.text = draft["city"]
        category = draft["category"] ?? category
        age = draft["age"] ?? age
        format = draft["format"] ?? format
        configureLightNavigation(title: "发布可传授课程"); navigationController?.setNavigationBarHidden(false, animated: false); buildUI()
    }

    private func buildUI() {
        let (_, stack) = makeScrollStack(in: self, bottom: 35)
        let status = UILabel.fs("已认证引路人 · 提交后进入平台审核", font: FSFont.caption(12), color: FSColor.success); status.backgroundColor = FSColor.mint; status.layer.cornerRadius = 14; status.clipsToBounds = true; status.textAlignment = .center; status.heightAnchor.constraint(equalToConstant: 38).isActive = true
        stack.addArrangedSubviews(status, UILabel.fs("分享你真正擅长的\n前沿知识", font: FSFont.display(30), lines: 2), UILabel.fs("先写清楚目标、方式和适合谁。运营会帮助你完善课程包装，不会提交即上线。", font: FSFont.body(14), color: FSColor.secondaryInk, lines: 0), name, intro)
        stack.addArrangedSubview(makeSingleChoice(title: "科技方向", options: ["AI 与大模型", "机器人", "无人机", "智能硬件"], selected: category) { [weak self] in self?.category = $0 })
        stack.addArrangedSubview(makeSingleChoice(title: "适合年龄", options: ["6–9 岁", "10–14 岁", "13–17 岁"], selected: age) { [weak self] in self?.age = $0 })
        stack.addArrangedSubview(makeSingleChoice(title: "服务方式", options: ["在线一对一", "线下一对一", "线下小型活动"], selected: format) { [weak self] in self?.format = $0 })
        stack.addArrangedSubview(city)
        let submit = FSPrimaryButton(title: "提交审核", symbol: "paperplane.fill"); submit.addAction(UIAction { [weak self] _ in self?.submit() }, for: .touchUpInside)
        let draftButton = UIButton(type: .system); draftButton.setTitle("保存草稿", for: .normal); draftButton.titleLabel?.font = FSFont.headline(15); draftButton.setTitleColor(FSColor.secondaryInk, for: .normal); draftButton.addAction(UIAction { [weak self] _ in self?.saveDraft() }, for: .touchUpInside)
        stack.addArrangedSubviews(submit, draftButton)
    }

    private func makeSingleChoice(title: String, options: [String], selected: String, onChange: @escaping (String) -> Void) -> UIView {
        let label = UILabel.fs(title, font: FSFont.headline(15)); let list = UIStackView(); list.axis = .vertical; list.spacing = 8
        var buttons: [FSChoiceButton] = []
        options.forEach { option in
            let button = FSChoiceButton(title: option); button.choiceSelected = option == selected; buttons.append(button)
            button.addAction(UIAction { _ in buttons.forEach { $0.choiceSelected = $0 === button }; onChange(option) }, for: .touchUpInside); list.addArrangedSubview(button)
        }
        let stack = UIStackView(arrangedSubviews: [label, list]); stack.axis = .vertical; stack.spacing = 9; return stack
    }

    private func submit() {
        view.endEditing(true)
        guard let title = name.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), title.count >= 4,
              let summary = intro.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), summary.count >= 6,
              let cityText = city.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !cityText.isEmpty else {
            showToast("请完整填写项目名称、简介与服务范围", symbol: "exclamationmark"); return
        }
        let project = FrontierProject(id: "P\(Int(Date().timeIntervalSince1970))", title: title, guide: "我的公开主页", guideRole: "已认证引路人", category: category, age: age, duration: "沟通后制定", format: format, city: cityText, schedule: "沟通后确定", status: "待审核", symbol: category == "机器人" ? "move.3d" : "sparkles", colors: [0x24204D, 0x6857D9], summary: summary, highlights: ["真实行业经验", "适龄表达", "项目式体验"])
        AppStore.shared.addProject(project)
        AppStore.shared.clearProjectDraft()
        let alert = UIAlertController(title: "已提交审核", message: "平台会检查专业匹配、信息完整度与安全说明。审核结果将通过消息中心通知。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default) { [weak self] _ in self?.navigationController?.popViewController(animated: true) })
        present(alert, animated: true)
    }

    private func saveDraft() {
        view.endEditing(true)
        AppStore.shared.saveProjectDraft([
            "name": name.textField.text ?? "", "intro": intro.textField.text ?? "", "city": city.textField.text ?? "",
            "category": category, "age": age, "format": format
        ])
        showToast("草稿已保存在本机，下次会自动恢复", symbol: "tray.and.arrow.down.fill")
    }
}
