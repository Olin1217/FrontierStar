import UIKit

final class IdentityViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FSColor.canvas
        buildUI()
    }

    private func buildUI() {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.pinEdges(to: view)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28)
        ])

        let logo = FSLogoView()
        logo.heightAnchor.constraint(equalToConstant: 26).isActive = true
        let eyebrow = UILabel.fs("连接真实前沿 · 点亮未来能力", font: FSFont.caption(13), color: FSColor.accent)
        let title = UILabel.fs("让孩子遇见\n真正懂前沿的人", font: FSFont.display(38), color: FSColor.ink, lines: 2)
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.82
        let intro = UILabel.fs("由平台精选行业技术人员、科研人员与项目实践者，帮助家庭更安心地认识 AI、机器人和未来科技。", font: FSFont.body(16), color: FSColor.secondaryInk, lines: 0)
        intro.setContentHuggingPriority(.required, for: .vertical)

        let header = UIStackView(arrangedSubviews: [logo, eyebrow, title, intro])
        header.axis = .vertical
        header.spacing = 12
        header.setCustomSpacing(25, after: logo)
        header.setCustomSpacing(9, after: eyebrow)
        stack.addArrangedSubview(header)
        stack.setCustomSpacing(32, after: header)

        let prompt = UILabel.fs("选择你来前沿星的方式", font: FSFont.headline(17))
        stack.addArrangedSubview(prompt)

        stack.addArrangedSubview(makeRoleCard(.parent, badge: "为孩子发现好课程", tint: FSColor.palePurple))
        stack.addArrangedSubview(makeRoleCard(.guide, badge: "把专业经验带给孩子", tint: FSColor.mint))

        let visitor = UIButton(type: .system)
        var visitorConfig = UIButton.Configuration.plain()
        visitorConfig.title = "游客随便逛逛"
        visitorConfig.subtitle = "无需登录，先看看课程与项目"
        visitorConfig.image = UIImage(systemName: "arrow.right")
        visitorConfig.imagePlacement = .trailing
        visitorConfig.imagePadding = 10
        visitorConfig.baseForegroundColor = FSColor.secondaryInk
        visitorConfig.contentInsets = NSDirectionalEdgeInsets(top: 11, leading: 8, bottom: 11, trailing: 8)
        visitor.configuration = visitorConfig
        visitor.contentHorizontalAlignment = .leading
        visitor.addAction(UIAction { _ in
            AppStore.shared.choose(role: .visitor)
            FSApp.showMain()
        }, for: .touchUpInside)
        stack.addArrangedSubview(visitor)

        let trust = makeTrustStrip()
        stack.addArrangedSubview(trust)
        stack.setCustomSpacing(26, after: visitor)

        let legal = UIButton(type: .system)
        legal.setTitle("继续即表示你已阅读并同意《用户协议》《隐私政策》与《儿童个人信息处理规则》", for: .normal)
        legal.setTitleColor(FSColor.accent, for: .normal)
        legal.titleLabel?.font = FSFont.caption(11)
        legal.titleLabel?.numberOfLines = 0
        legal.titleLabel?.textAlignment = .center
        legal.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let page = InformationViewController(title: "协议与隐私")
            let navigation = UINavigationController(rootViewController: page)
            page.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak page] _ in page?.dismiss(animated: true) })
            navigation.modalPresentationStyle = .pageSheet
            self.present(navigation, animated: true)
        }, for: .touchUpInside)
        stack.addArrangedSubview(legal)
    }

    private func makeRoleCard(_ role: UserRole, badge: String, tint: UIColor) -> UIView {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 24
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = FSColor.line.cgColor
        button.addShadow(opacity: 0.045, radius: 14, y: 5)

        let iconBox = UIView()
        iconBox.backgroundColor = tint
        iconBox.layer.cornerRadius = 20
        iconBox.layer.cornerCurve = .continuous
        let icon = UIImageView(image: UIImage(systemName: role.symbol))
        icon.tintColor = role == .guide ? FSColor.success : FSColor.accentDark
        icon.contentMode = .scaleAspectFit
        iconBox.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor), icon.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 27), icon.heightAnchor.constraint(equalToConstant: 27),
            iconBox.widthAnchor.constraint(equalToConstant: 56), iconBox.heightAnchor.constraint(equalToConstant: 56)
        ])

        let title = UILabel.fs(role == .parent ? "我是家长" : "我是前沿引路人", font: FSFont.headline(18))
        let subtitle = UILabel.fs(role.subtitle, font: FSFont.caption(13), color: FSColor.secondaryInk, lines: 2)
        let badgeLabel = UILabel.fs(badge, font: FSFont.caption(11), color: role == .guide ? FSColor.success : FSColor.accentDark)
        badgeLabel.backgroundColor = tint
        badgeLabel.layer.cornerRadius = 11
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.heightAnchor.constraint(equalToConstant: 23).isActive = true
        badgeLabel.widthAnchor.constraint(equalToConstant: role == .guide ? 151 : 132).isActive = true
        let text = UIStackView(arrangedSubviews: [title, subtitle, badgeLabel])
        text.axis = .vertical
        text.spacing = 5
        text.alignment = .leading
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = FSColor.tertiaryInk
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [iconBox, text, chevron])
        row.spacing = 15
        row.alignment = .center
        button.addSubview(row)
        row.isUserInteractionEnabled = false
        row.pinEdges(to: button, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 104).isActive = true
        button.addAction(UIAction { _ in
            AppStore.shared.choose(role: role)
            self.presentLogin(for: role)
        }, for: .touchUpInside)
        return button
    }

    private func makeTrustStrip() -> UIView {
        let view = FSCardView(background: UIColor(hex: 0xEEEDE8), radius: 18)
        let items = [("checkmark.shield", "身份核验"), ("person.2", "人工匹配"), ("lock", "隐私脱敏")]
        let stack = UIStackView()
        stack.distribution = .fillEqually
        items.forEach { symbol, text in
            let icon = UIImageView(image: UIImage(systemName: symbol))
            icon.tintColor = FSColor.secondaryInk
            icon.contentMode = .scaleAspectFit
            icon.heightAnchor.constraint(equalToConstant: 17).isActive = true
            let label = UILabel.fs(text, font: FSFont.caption(11), color: FSColor.secondaryInk)
            label.textAlignment = .center
            let column = UIStackView(arrangedSubviews: [icon, label])
            column.axis = .vertical
            column.spacing = 7
            stack.addArrangedSubview(column)
        }
        view.addSubview(stack)
        stack.pinEdges(to: view, insets: UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10))
        return view
    }

    private func presentLogin(for role: UserRole) {
        let login = LoginViewController(role: role) {
            FSApp.showMain()
        }
        let navigation = UINavigationController(rootViewController: login)
        navigation.modalPresentationStyle = .pageSheet
        if let sheet = navigation.sheetPresentationController { sheet.detents = [.large()]; sheet.prefersGrabberVisible = true }
        present(navigation, animated: true)
    }
}

enum AuthGate {
    static func require(role: UserRole, from controller: UIViewController, completion: @escaping () -> Void) {
        if AppStore.shared.isLoggedIn {
            AppStore.shared.choose(role: role)
            completion()
            return
        }
        let login = LoginViewController(role: role) { completion() }
        let navigation = UINavigationController(rootViewController: login)
        navigation.modalPresentationStyle = .pageSheet
        if let sheet = navigation.sheetPresentationController { sheet.detents = [.large()]; sheet.prefersGrabberVisible = true }
        controller.present(navigation, animated: true)
    }
}

final class LoginViewController: UIViewController {
    private let role: UserRole
    private let completion: () -> Void
    private let phoneField = FSFormField(title: "手机号", placeholder: "请输入 11 位手机号", keyboard: .phonePad)
    private let codeField = FSFormField(title: "验证码", placeholder: "请输入短信验证码", keyboard: .numberPad)
    private let sendButton = UIButton(type: .system)
    private var timer: Timer?
    private var seconds = 0

    init(role: UserRole, completion: @escaping () -> Void) {
        self.role = role
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightNavigation()
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
        buildUI()
    }

    deinit { timer?.invalidate() }

    private func buildUI() {
        let (_, stack) = makeScrollStack(in: self, bottom: 40)
        let icon = UIImageView(image: UIImage(systemName: role.symbol))
        icon.tintColor = FSColor.accent
        icon.contentMode = .scaleAspectFit
        icon.backgroundColor = FSColor.palePurple
        icon.layer.cornerRadius = 30
        icon.layer.cornerCurve = .continuous
        let iconHolder = UIView()
        iconHolder.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: iconHolder.leadingAnchor),
            icon.topAnchor.constraint(equalTo: iconHolder.topAnchor),
            icon.bottomAnchor.constraint(equalTo: iconHolder.bottomAnchor),
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 60)
        ])
        let title = UILabel.fs(role == .parent ? "登录后，为孩子找到合适方向" : "登录后，分享你的前沿经验", font: FSFont.title(29), lines: 0)
        let subtitle = UILabel.fs("手机号将用于课程顾问确认报名与服务安排，平台不会向引路人公开完整号码。", font: FSFont.body(15), color: FSColor.secondaryInk, lines: 0)
        stack.addArrangedSubviews(iconHolder, title, subtitle)
        stack.setCustomSpacing(30, after: subtitle)
        stack.addArrangedSubviews(phoneField, codeField)

        sendButton.setTitle("获取验证码", for: .normal)
        sendButton.titleLabel?.font = FSFont.caption(13)
        sendButton.addAction(UIAction { [weak self] _ in self?.sendCode() }, for: .touchUpInside)
        codeField.textField.rightView = sendButton
        codeField.textField.rightViewMode = .always
        sendButton.frame = CGRect(x: 0, y: 0, width: 104, height: 44)

        let login = FSPrimaryButton(title: "登录并继续", symbol: "arrow.right")
        login.addAction(UIAction { [weak self] _ in self?.validateAndLogin() }, for: .touchUpInside)
        stack.addArrangedSubview(login)

        let dividerLabel = UILabel.fs("或使用其他方式", font: FSFont.caption(12), color: FSColor.tertiaryInk)
        dividerLabel.textAlignment = .center
        stack.addArrangedSubview(dividerLabel)

        let wechat = providerButton(title: "微信登录", symbol: "message.fill", color: UIColor(hex: 0x1AAD19))
        wechat.addAction(UIAction { [weak self] _ in self?.providerLogin() }, for: .touchUpInside)
        let apple = providerButton(title: "通过 Apple 登录", symbol: "apple.logo", color: FSColor.ink)
        apple.addAction(UIAction { [weak self] _ in self?.providerLogin() }, for: .touchUpInside)
        stack.addArrangedSubviews(wechat, apple)

        let note = UILabel.fs("第三方登录可先浏览；报名、发布需求或预约前仍需验证真实手机号。继续即同意《用户协议》与《隐私政策》。", font: FSFont.caption(11), color: FSColor.tertiaryInk, lines: 0)
        note.textAlignment = .center
        stack.addArrangedSubview(note)
    }

    private func providerButton(title: String, symbol: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePadding = 9
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in var attrs = attrs; attrs.font = FSFont.headline(15); return attrs }
        button.configuration = config
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return button
    }

    private func sendCode() {
        let phone = phoneField.textField.text ?? ""
        guard phone.count == 11, phone.allSatisfy({ $0.isNumber }) else {
            showToast("请输入正确的 11 位手机号", symbol: "exclamationmark")
            return
        }
        seconds = 60
        sendButton.isEnabled = false
        sendButton.setTitle("60 秒", for: .normal)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.seconds -= 1
            self.sendButton.setTitle(self.seconds > 0 ? "\(self.seconds) 秒" : "重新获取", for: .normal)
            if self.seconds <= 0 { timer.invalidate(); self.sendButton.isEnabled = true }
        }
        showToast("验证码已发送", symbol: "paperplane.fill")
    }

    private func validateAndLogin() {
        let phone = phoneField.textField.text ?? ""
        let code = codeField.textField.text ?? ""
        guard phone.count == 11, phone.allSatisfy({ $0.isNumber }) else { showToast("请输入正确的手机号", symbol: "exclamationmark"); return }
        guard (4...6).contains(code.count), code.allSatisfy({ $0.isNumber }) else { showToast("请输入短信验证码", symbol: "exclamationmark"); return }
        finish(phone: phone)
    }

    private func providerLogin() {
        AppStore.shared.choose(role: role)
        AppStore.shared.login()
        dismiss(animated: true) { self.completion() }
    }

    private func finish(phone: String) {
        AppStore.shared.choose(role: role)
        AppStore.shared.login(phone: phone)
        dismiss(animated: true) { self.completion() }
    }
}
