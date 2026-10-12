import UIKit

final class CourseFeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    private var collectionView: UICollectionView!
    private let segment = UISegmentedControl(items: ["推荐", "周期课"])
    private var displayedCourses = AppStore.shared.courses

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FSColor.ink
        buildCollectionView()
        buildHeader()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadState), name: .appStateDidChange, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func buildCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = FSColor.ink
        collectionView.showsVerticalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CourseFeedCell.self, forCellWithReuseIdentifier: CourseFeedCell.reuseIdentifier)
        view.addSubview(collectionView)
        collectionView.pinEdges(to: view)
    }

    private func buildHeader() {
        let material = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        material.layer.cornerRadius = 21
        material.layer.cornerCurve = .continuous
        material.clipsToBounds = true
        segment.selectedSegmentIndex = 0
        segment.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.94)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.78), .font: FSFont.caption(13)], for: .normal)
        segment.setTitleTextAttributes([.foregroundColor: FSColor.ink, .font: FSFont.caption(13)], for: .selected)
        segment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        material.contentView.addSubview(segment)
        segment.pinEdges(to: material.contentView, insets: UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3))

        let search = FSIconButton(symbol: "magnifyingglass", tint: .white, background: UIColor.white.withAlphaComponent(0.13))
        search.addAction(UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(CourseSearchViewController(), animated: true)
        }, for: .touchUpInside)

        let miniLogo = UIView()
        let star = UIImageView(image: UIImage(systemName: "star.fill"))
        star.tintColor = FSColor.coral
        let label = UILabel.fs("前沿星", font: FSFont.headline(17), color: .white)
        let logoStack = UIStackView(arrangedSubviews: [star, label])
        logoStack.spacing = 6
        miniLogo.addSubview(logoStack)
        logoStack.pinEdges(to: miniLogo)

        let row = UIStackView(arrangedSubviews: [miniLogo, UIView(), material, search])
        row.alignment = .center
        row.spacing = 10
        view.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 9),
            row.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            material.widthAnchor.constraint(equalToConstant: 142),
            material.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    @objc private func segmentChanged() {
        displayedCourses = segment.selectedSegmentIndex == 0 ? AppStore.shared.courses : AppStore.shared.courses.filter { $0.duration.contains("周") }
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }

    @objc private func reloadState() { collectionView.reloadData() }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { displayedCourses.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseFeedCell.reuseIdentifier, for: indexPath) as! CourseFeedCell
        let course = displayedCourses[indexPath.item]
        cell.configure(course: course, enrolled: AppStore.shared.enrolledCourseIDs.contains(course.id))
        cell.onDetail = { [weak self] in self?.openDetail(course) }
        cell.onEnroll = { [weak self] in self?.startEnrollment(course) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageHeight = max(scrollView.bounds.height, 1)
        let proposed = targetContentOffset.pointee.y / pageHeight
        let current = scrollView.contentOffset.y / pageHeight
        let page: CGFloat
        if abs(velocity.y) > 0.25 { page = velocity.y > 0 ? floor(current + 1) : ceil(current - 1) }
        else { page = round(proposed) }
        let maxPage = CGFloat(max(displayedCourses.count - 1, 0))
        targetContentOffset.pointee.y = min(max(page, 0), maxPage) * pageHeight
    }

    private func openDetail(_ course: Course) {
        navigationController?.pushViewController(CourseDetailViewController(course: course), animated: true)
    }

    private func startEnrollment(_ course: Course) {
        guard course.status != .full else { showToast("课程已满，可在详情页登记候补", symbol: "person.3"); return }
        if AppStore.shared.activeRole == .visitor || !AppStore.shared.isLoggedIn {
            AuthGate.require(role: .parent, from: self) { [weak self] in self?.confirmEnrollment(course) }
        } else {
            confirmEnrollment(course)
        }
    }

    private func confirmEnrollment(_ course: Course) {
        if AppStore.shared.enrolledCourseIDs.contains(course.id) { showToast("这门课程已经报名", symbol: "checkmark.circle"); return }
        let alert = UIAlertController(title: "确认报名这门课程？", message: "提交后，课程顾问将通过您已验证的手机号与您取得联系，为您确认课程安排与报名信息。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "暂不报名", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认报名", style: .default) { [weak self] _ in
            AppStore.shared.enroll(course)
            self?.showToast("报名成功，课程顾问将尽快与你联系")
        })
        present(alert, animated: true)
    }
}

final class CourseFeedCell: UICollectionViewCell {
    static let reuseIdentifier = "CourseFeedCell"
    var onDetail: (() -> Void)?
    var onEnroll: (() -> Void)?
    private var artwork: FSArtworkView?
    private let categoryLabel = UILabel.fs("", font: FSFont.caption(12), color: .white)
    private let statusLabel = UILabel.fs("", font: FSFont.caption(12), color: .white)
    private let titleLabel = UILabel.fs("", font: FSFont.display(35), color: .white, lines: 3)
    private let teacherLabel = UILabel.fs("", font: FSFont.headline(15), color: .white, lines: 1)
    private let metaStack = UIStackView()
    private let detailButton = FSSecondaryButton(title: "查看详情")
    private let enrollButton = FSPrimaryButton(title: "立即报名", symbol: "arrow.up.right")
    private let shadeView = UIView()
    private let shadeLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        shadeLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.08).cgColor, UIColor.black.withAlphaComponent(0.78).cgColor]
        shadeLayer.locations = [0.28, 0.53, 1]
        shadeView.layer.addSublayer(shadeLayer)
        contentView.addSubview(shadeView)
        shadeView.pinEdges(to: contentView)

        categoryLabel.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        categoryLabel.layer.cornerRadius = 14
        categoryLabel.layer.cornerCurve = .continuous
        categoryLabel.clipsToBounds = true
        categoryLabel.textAlignment = .center
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 14
        statusLabel.layer.cornerCurve = .continuous
        statusLabel.clipsToBounds = true
        let badges = UIStackView(arrangedSubviews: [categoryLabel, statusLabel, UIView()])
        badges.spacing = 8

        metaStack.axis = .vertical
        metaStack.spacing = 8
        let buttons = UIStackView(arrangedSubviews: [detailButton, enrollButton])
        buttons.spacing = 10
        buttons.distribution = .fillEqually
        detailButton.addAction(UIAction { [weak self] _ in self?.onDetail?() }, for: .touchUpInside)
        enrollButton.addAction(UIAction { [weak self] _ in self?.onEnroll?() }, for: .touchUpInside)
        let content = UIStackView(arrangedSubviews: [badges, titleLabel, teacherLabel, metaStack, buttons])
        content.axis = .vertical
        content.spacing = 13
        content.setCustomSpacing(9, after: badges)
        content.setCustomSpacing(8, after: teacherLabel)
        content.setCustomSpacing(18, after: metaStack)
        contentView.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -185),
            categoryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 102),
            categoryLabel.heightAnchor.constraint(equalToConstant: 29),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            statusLabel.heightAnchor.constraint(equalToConstant: 29)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadeLayer.frame = shadeView.bounds
        artwork?.frame = bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artwork?.removeFromSuperview()
        artwork = nil
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    func configure(course: Course, enrolled: Bool) {
        let art = FSArtworkView(symbol: course.artSymbol, colors: course.colors)
        contentView.insertSubview(art, at: 0)
        art.frame = bounds
        art.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        artwork = art
        contentView.sendSubviewToBack(art)
        categoryLabel.text = "  \(course.category)  "
        statusLabel.text = "  \(course.status.rawValue)  "
        statusLabel.backgroundColor = course.status == .available ? FSColor.success.withAlphaComponent(0.86) : FSColor.warning.withAlphaComponent(0.9)
        titleLabel.text = course.title
        teacherLabel.text = "主讲人  \(course.instructor) · \(course.instructorRole)"
        metaStack.addArrangedSubview(makeMetaRow(symbol: "calendar", text: course.duration))
        metaStack.addArrangedSubview(makeMetaRow(symbol: "clock", text: course.schedule))
        metaStack.addArrangedSubview(makeMetaRow(symbol: "person.2", text: "\(course.age) · \(course.format)"))
        enrollButton.configuration?.title = enrolled ? "已报名" : "立即报名"
        enrollButton.configuration?.image = UIImage(systemName: enrolled ? "checkmark" : "arrow.up.right")
        enrollButton.isEnabled = !enrolled
        enrollButton.configuration?.baseBackgroundColor = enrolled ? UIColor.white.withAlphaComponent(0.3) : .white
        enrollButton.configuration?.baseForegroundColor = enrolled ? .white : FSColor.ink
    }

    private func makeMetaRow(symbol: String, text: String) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = UIColor.white.withAlphaComponent(0.76)
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([icon.widthAnchor.constraint(equalToConstant: 17), icon.heightAnchor.constraint(equalToConstant: 17)])
        let label = UILabel.fs(text, font: FSFont.caption(13), color: UIColor.white.withAlphaComponent(0.9), lines: 1)
        let row = UIStackView(arrangedSubviews: [icon, label, UIView()])
        row.spacing = 8
        return row
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class CourseDetailViewController: UIViewController {
    private let course: Course
    private let enrollButton = FSPrimaryButton(title: "立即报名", symbol: "arrow.up.right")
    private let favorite = FSIconButton(symbol: "heart", tint: FSColor.ink, background: .white)

    init(course: Course) { self.course = course; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation()
        navigationItem.largeTitleDisplayMode = .never
        buildUI()
        refreshButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshButtons()
    }

    private func buildUI() {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 0
        scroll.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false

        let hero = FSArtworkView(symbol: course.artSymbol, colors: course.colors)
        hero.layer.cornerRadius = 28
        hero.layer.cornerCurve = .continuous
        hero.clipsToBounds = true
        hero.heightAnchor.constraint(equalToConstant: 310).isActive = true
        let heroWrap = UIView()
        heroWrap.addSubview(hero)
        hero.pinEdges(to: heroWrap, insets: UIEdgeInsets(top: 6, left: 16, bottom: 16, right: 16))
        content.addArrangedSubview(heroWrap)

        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 18
        body.layoutMargins = UIEdgeInsets(top: 8, left: 20, bottom: 34, right: 20)
        body.isLayoutMarginsRelativeArrangement = true
        content.addArrangedSubview(body)

        let tags = UIStackView(arrangedSubviews: [FSMetadataPill(symbol: "sparkles", text: course.category), FSMetadataPill(symbol: "person.2", text: course.age), UIView()])
        tags.spacing = 8
        let title = UILabel.fs(course.title.replacingOccurrences(of: "\n", with: " "), font: FSFont.display(31), lines: 0)
        let summary = UILabel.fs(course.summary, font: FSFont.body(16), color: FSColor.secondaryInk, lines: 0)
        body.addArrangedSubviews(tags, title, makeGuideRow(), summary)
        body.setCustomSpacing(11, after: tags)
        body.setCustomSpacing(22, after: summary)
        body.addArrangedSubview(makeInfoCard())
        body.addArrangedSubview(makeSection(title: "孩子会带走什么", items: course.outcomes, symbol: "checkmark.circle.fill"))
        body.addArrangedSubview(makeLessonSection())
        body.addArrangedSubview(makeNoteCard())

        let bottom = UIView()
        bottom.backgroundColor = UIColor.white.withAlphaComponent(0.97)
        bottom.addShadow(opacity: 0.08, radius: 14, y: -4)
        let actions = UIStackView(arrangedSubviews: [favorite, enrollButton])
        actions.spacing = 12
        actions.alignment = .center
        bottom.addSubview(actions)
        actions.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actions.topAnchor.constraint(equalTo: bottom.topAnchor, constant: 12),
            actions.leadingAnchor.constraint(equalTo: bottom.leadingAnchor, constant: 18),
            actions.trailingAnchor.constraint(equalTo: bottom.trailingAnchor, constant: -18),
            actions.bottomAnchor.constraint(equalTo: bottom.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
        favorite.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            AppStore.shared.toggleFavorite(self.course)
            self.refreshButtons()
            self.showToast(AppStore.shared.favoriteCourseIDs.contains(self.course.id) ? "已收藏" : "已取消收藏", symbol: "heart.fill")
        }, for: .touchUpInside)
        enrollButton.addAction(UIAction { [weak self] _ in self?.startEnrollment() }, for: .touchUpInside)
        view.addSubview(bottom)
        bottom.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottom.topAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor), content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor), content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor),
            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor), bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor), bottom.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeGuideRow() -> UIView {
        let button = UIButton(type: .system)
        button.accessibilityLabel = "查看主讲人 \(course.instructor) 的资料"
        button.accessibilityHint = course.instructorRole
        button.backgroundColor = .white
        button.layer.cornerRadius = 18
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = FSColor.line.cgColor
        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = FSColor.accent
        avatar.contentMode = .scaleAspectFit
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([avatar.widthAnchor.constraint(equalToConstant: 44), avatar.heightAnchor.constraint(equalToConstant: 44)])
        let name = UILabel.fs(course.instructor, font: FSFont.headline(16))
        let role = UILabel.fs("主讲人 · \(course.instructorRole)", font: FSFont.caption(12), color: FSColor.secondaryInk)
        let text = UIStackView(arrangedSubviews: [name, role])
        text.axis = .vertical
        text.spacing = 3
        let verified = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        verified.tintColor = FSColor.accent
        let row = UIStackView(arrangedSubviews: [avatar, text, UIView(), verified, UIImageView(image: UIImage(systemName: "chevron.right"))])
        row.spacing = 11
        row.alignment = .center
        button.addSubview(row)
        row.isUserInteractionEnabled = false
        row.pinEdges(to: button, insets: UIEdgeInsets(top: 12, left: 13, bottom: 12, right: 13))
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let profile = AppStore.shared.guides[self.course.instructor] ?? GuideProfile(name: self.course.instructor, role: self.course.instructorRole, city: "北京", bio: "专注于把真实行业经验转化为适合青少年理解和实践的科技体验。", avatarSymbol: "person.crop.circle.fill", tags: [self.course.category, "项目实践", self.course.age], verification: ["身份已核验", "服务方案已审核"], courses: 2, participants: 18, reviews: 8, rating: 4.8)
            self.navigationController?.pushViewController(GuideDetailViewController(profile: profile), animated: true)
        }, for: .touchUpInside)
        return button
    }

    private func makeInfoCard() -> UIView {
        let card = FSCardView(radius: 22)
        let rows = [("calendar", "课程周期", course.duration), ("clock", "上课时间", course.schedule), ("location", "课程形式", course.format), ("person.2", "适合年龄", course.age)]
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        rows.enumerated().forEach { index, row in
            let icon = UIImageView(image: UIImage(systemName: row.0))
            icon.tintColor = FSColor.accent
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([icon.widthAnchor.constraint(equalToConstant: 20), icon.heightAnchor.constraint(equalToConstant: 20)])
            let label = UILabel.fs(row.1, font: FSFont.caption(12), color: FSColor.tertiaryInk)
            let value = UILabel.fs(row.2, font: FSFont.caption(14), color: FSColor.ink, lines: 2)
            value.textAlignment = .right
            let line = UIStackView(arrangedSubviews: [icon, label, UIView(), value])
            line.spacing = 10
            line.alignment = .center
            line.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
            line.isLayoutMarginsRelativeArrangement = true
            stack.addArrangedSubview(line)
            if index < rows.count - 1 {
                let divider = UIView(); divider.backgroundColor = FSColor.line; divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(divider)
            }
        }
        card.addSubview(stack)
        stack.pinEdges(to: card)
        return card
    }

    private func makeSection(title: String, items: [String], symbol: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(UILabel.fs(title, font: FSFont.title(22)))
        items.forEach { item in
            let icon = UIImageView(image: UIImage(systemName: symbol))
            icon.tintColor = FSColor.success
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([icon.widthAnchor.constraint(equalToConstant: 20), icon.heightAnchor.constraint(equalToConstant: 20)])
            let label = UILabel.fs(item, font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0)
            let row = UIStackView(arrangedSubviews: [icon, label])
            row.alignment = .top
            row.spacing = 10
            stack.addArrangedSubview(row)
        }
        return stack
    }

    private func makeLessonSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(UILabel.fs("课程安排", font: FSFont.title(22)))
        course.lessons.enumerated().forEach { index, lesson in
            let number = UILabel.fs("\(index + 1)", font: FSFont.headline(13), color: .white)
            number.textAlignment = .center
            number.backgroundColor = FSColor.accent
            number.layer.cornerRadius = 15
            number.clipsToBounds = true
            number.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([number.widthAnchor.constraint(equalToConstant: 30), number.heightAnchor.constraint(equalToConstant: 30)])
            let title = UILabel.fs(lesson.title, font: FSFont.headline(15))
            let detail = UILabel.fs(lesson.detail, font: FSFont.caption(13), color: FSColor.secondaryInk, lines: 0)
            let time = UILabel.fs(lesson.time, font: FSFont.caption(12), color: FSColor.accent)
            let text = UIStackView(arrangedSubviews: [title, detail, time])
            text.axis = .vertical
            text.spacing = 4
            let row = UIStackView(arrangedSubviews: [number, text])
            row.spacing = 12
            row.alignment = .top
            stack.addArrangedSubview(row)
        }
        return stack
    }

    private func makeNoteCard() -> UIView {
        let card = FSCardView(background: FSColor.mint, radius: 20)
        let icon = UIImageView(image: UIImage(systemName: "person.crop.circle.badge.checkmark"))
        icon.tintColor = FSColor.success
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 25).isActive = true
        let text = UILabel.fs("报名是意向提交，不代表缴费或最终名额已确认。课程顾问会核对孩子情况与安排后再与你确认。", font: FSFont.caption(13), color: UIColor(hex: 0x326553), lines: 0)
        let row = UIStackView(arrangedSubviews: [icon, text])
        row.spacing = 11
        row.alignment = .top
        card.addSubview(row)
        row.pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }

    private func refreshButtons() {
        let enrolled = AppStore.shared.enrolledCourseIDs.contains(course.id)
        enrollButton.configuration?.title = enrolled ? "已报名" : "立即报名"
        enrollButton.configuration?.image = UIImage(systemName: enrolled ? "checkmark" : "arrow.up.right")
        enrollButton.isEnabled = !enrolled
        favorite.configuration?.image = UIImage(systemName: AppStore.shared.favoriteCourseIDs.contains(course.id) ? "heart.fill" : "heart")
    }

    private func startEnrollment() {
        if AppStore.shared.activeRole == .visitor || !AppStore.shared.isLoggedIn {
            AuthGate.require(role: .parent, from: self) { [weak self] in self?.confirmEnrollment() }
        } else { confirmEnrollment() }
    }

    private func confirmEnrollment() {
        guard !AppStore.shared.enrolledCourseIDs.contains(course.id) else { return }
        let alert = UIAlertController(title: "确认报名这门课程？", message: "提交后，课程顾问将通过您已验证的手机号与你取得联系，为你确认课程安排与报名信息。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "暂不报名", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认报名", style: .default) { [weak self] _ in
            guard let self else { return }
            AppStore.shared.enroll(self.course)
            self.refreshButtons()
            self.showToast("报名成功，课程顾问将尽快与你联系")
        })
        present(alert, animated: true)
    }
}

final class CourseSearchViewController: UITableViewController, UISearchResultsUpdating {
    private var results = AppStore.shared.courses
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation(title: "搜索课程")
        navigationController?.setNavigationBarHidden(false, animated: false)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "课程、方向、引路人或城市"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        tableView.backgroundColor = FSColor.canvas
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "result")
    }

    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        results = text.isEmpty ? AppStore.shared.courses : AppStore.shared.courses.filter {
            [$0.title, $0.instructor, $0.category, $0.format].joined().localizedCaseInsensitiveContains(text)
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { results.count }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 88 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "result", for: indexPath)
        let course = results[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = course.title.replacingOccurrences(of: "\n", with: " ")
        config.secondaryText = "\(course.category) · \(course.age) · \(course.format)"
        config.image = UIImage(systemName: course.artSymbol)
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
        navigationController?.pushViewController(CourseDetailViewController(course: results[indexPath.row]), animated: true)
    }
}
