import UIKit

enum FSColor {
    static let ink = UIColor(hex: 0x161821)
    static let secondaryInk = UIColor(hex: 0x646874)
    static let tertiaryInk = UIColor(hex: 0x9195A1)
    static let canvas = UIColor(hex: 0xF5F5F2)
    static let card = UIColor.white
    static let line = UIColor(hex: 0xE6E5E0)
    static let accent = UIColor(hex: 0x5A50DD)
    static let accentDark = UIColor(hex: 0x3E37A9)
    static let coral = UIColor(hex: 0xF27772)
    static let mint = UIColor(hex: 0xDFF3EA)
    static let palePurple = UIColor(hex: 0xECE9FF)
    static let warning = UIColor(hex: 0xE79A3B)
    static let success = UIColor(hex: 0x2D8B69)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

enum FSFont {
    static func display(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    static func title(_ size: CGFloat = 24) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    static func headline(_ size: CGFloat = 17) -> UIFont { .systemFont(ofSize: size, weight: .semibold) }
    static func body(_ size: CGFloat = 16) -> UIFont { .systemFont(ofSize: size, weight: .regular) }
    static func caption(_ size: CGFloat = 13) -> UIFont { .systemFont(ofSize: size, weight: .medium) }
}

extension UIView {
    func pinEdges(to view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func addShadow(color: UIColor = .black, opacity: Float = 0.08, radius: CGFloat = 20, y: CGFloat = 8) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = CGSize(width: 0, height: y)
    }
}

extension UIStackView {
    func addArrangedSubviews(_ views: UIView...) { views.forEach(addArrangedSubview) }
}

extension UILabel {
    static func fs(_ text: String = "", font: UIFont, color: UIColor = FSColor.ink, lines: Int = 0) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        return label
    }
}

extension UIViewController {
    func configureLightNavigation(title: String? = nil) {
        self.title = title
        view.backgroundColor = FSColor.canvas
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = FSColor.canvas.withAlphaComponent(0.97)
        appearance.titleTextAttributes = [.foregroundColor: FSColor.ink, .font: FSFont.headline()]
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    func showToast(_ message: String, symbol: String = "checkmark") {
        FSToast.show(message, symbol: symbol, in: view.window ?? view)
    }

    func selectMainTab(identifier: String, fallbackIndex: Int) {
        guard let tabs = tabBarController else { return }
        navigationController?.popToRootViewController(animated: false)
        if #available(iOS 18.0, *), let tab = tabs.tab(forIdentifier: identifier) {
            tabs.selectedTab = tab
        } else {
            tabs.selectedIndex = fallbackIndex
        }
    }
}

private extension UIButton {
    func installFSInteractionFeedback() {
        addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            UIView.animate(withDuration: 0.12) {
                self?.transform = CGAffineTransform(scaleX: 0.975, y: 0.975)
                self?.alpha = 0.86
            }
        }, for: .touchDown)
        addAction(UIAction { [weak self] _ in
            UIView.animate(withDuration: 0.18) {
                self?.transform = .identity
                self?.alpha = 1
            }
        }, for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }
}

final class FSLogoView: UIView {
    private let mark = UIImageView(image: UIImage(systemName: "star.fill"))
    private let title = UILabel.fs("前沿星", font: FSFont.title(20))

    override init(frame: CGRect) {
        super.init(frame: frame)
        mark.tintColor = FSColor.coral
        mark.contentMode = .scaleAspectFit
        let stack = UIStackView(arrangedSubviews: [mark, title])
        stack.spacing = 8
        stack.alignment = .center
        addSubview(stack)
        stack.pinEdges(to: self)
        mark.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([mark.widthAnchor.constraint(equalToConstant: 21), mark.heightAnchor.constraint(equalToConstant: 21)])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSCardView: UIView {
    init(background: UIColor = FSColor.card, radius: CGFloat = 22) {
        super.init(frame: .zero)
        backgroundColor = background
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        clipsToBounds = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSEmptyStateView: UIView {
    private let accessibilityAction: () -> Void

    init(symbol: String, title: String, message: String, actionTitle: String, action: @escaping () -> Void) {
        accessibilityAction = action
        super.init(frame: .zero)
        let icon = UIImageView(image: UIImage(systemName: symbol)); icon.tintColor = FSColor.accent; icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false; icon.heightAnchor.constraint(equalToConstant: 58).isActive = true
        let titleLabel = UILabel.fs(title, font: FSFont.title(21)); titleLabel.textAlignment = .center
        let messageLabel = UILabel.fs(message, font: FSFont.body(14), color: FSColor.secondaryInk, lines: 0); messageLabel.textAlignment = .center
        let button = FSPrimaryButton(title: actionTitle, symbol: "arrow.right")
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, messageLabel, button]); stack.axis = .vertical; stack.spacing = 14
        addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -35)
        ])
        // UITableView background views may otherwise collapse their children into
        // one accessibility group, which makes the recovery action undiscoverable.
        // UITableView's backgroundView is flattened by UIKit into one element.
        // Make that element actionable so VoiceOver users can still recover.
        isAccessibilityElement = true
        accessibilityLabel = "\(title)。\(message)"
        accessibilityHint = actionTitle
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func accessibilityActivate() -> Bool {
        accessibilityAction()
        return true
    }
}

extension UITableView {
    /// Interactive empty states belong in the table hierarchy. UIKit flattens
    /// `backgroundView` into a non-actionable "empty list" accessibility node.
    func setFSEmptyState(_ emptyState: FSEmptyStateView?) {
        backgroundView = nil
        guard let emptyState else {
            if tableHeaderView is FSEmptyStateView { tableHeaderView = nil }
            accessibilityElements = nil
            return
        }
        let availableHeight = max(bounds.height - adjustedContentInset.top - adjustedContentInset.bottom, 420)
        emptyState.frame = CGRect(x: 0, y: 0, width: bounds.width, height: availableHeight)
        tableHeaderView = emptyState
        accessibilityElements = [emptyState]
    }
}

final class FSPrimaryButton: UIButton {
    init(title: String, symbol: String? = nil) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = symbol.flatMap { UIImage(systemName: $0) }
        config.imagePadding = 8
        config.baseBackgroundColor = FSColor.ink
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = FSFont.headline(16)
            return attributes
        }
        configuration = config
        heightAnchor.constraint(equalToConstant: 54).isActive = true
        installFSInteractionFeedback()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSSecondaryButton: UIButton {
    init(title: String, symbol: String? = nil) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = symbol.flatMap { UIImage(systemName: $0) }
        config.imagePadding = 8
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.14)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.background.strokeColor = UIColor.white.withAlphaComponent(0.22)
        config.background.strokeWidth = 1
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = FSFont.headline(16)
            return attributes
        }
        configuration = config
        heightAnchor.constraint(equalToConstant: 54).isActive = true
        installFSInteractionFeedback()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSIconButton: UIButton {
    init(symbol: String, tint: UIColor = FSColor.ink, background: UIColor = FSColor.card) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: symbol)
        config.baseForegroundColor = tint
        config.baseBackgroundColor = background
        config.cornerStyle = .capsule
        configuration = config
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: 44), heightAnchor.constraint(equalToConstant: 44)])
        installFSInteractionFeedback()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSTagListView: UIStackView {
    init(tags: [String], tint: UIColor = FSColor.palePurple, textColor: UIColor = FSColor.accentDark) {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 8
        var index = 0
        while index < tags.count {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            for offset in 0..<2 {
                if index + offset < tags.count {
                    let label = UILabel.fs(tags[index + offset], font: FSFont.caption(), color: textColor, lines: 1)
                    label.textAlignment = .center
                    label.backgroundColor = tint
                    label.layer.cornerRadius = 15
                    label.layer.cornerCurve = .continuous
                    label.clipsToBounds = true
                    label.heightAnchor.constraint(equalToConstant: 32).isActive = true
                    row.addArrangedSubview(label)
                } else {
                    row.addArrangedSubview(UIView())
                }
            }
            addArrangedSubview(row)
            index += 2
        }
    }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSMetadataPill: UIView {
    init(symbol: String, text: String, light: Bool = false) {
        super.init(frame: .zero)
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = light ? .white : FSColor.accent
        icon.contentMode = .scaleAspectFit
        let label = UILabel.fs(text, font: FSFont.caption(12), color: light ? .white : FSColor.secondaryInk, lines: 1)
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.spacing = 6
        stack.alignment = .center
        addSubview(stack)
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 8, left: 11, bottom: 8, right: 11))
        backgroundColor = light ? UIColor.white.withAlphaComponent(0.14) : FSColor.canvas
        layer.cornerRadius = 15
        layer.cornerCurve = .continuous
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([icon.widthAnchor.constraint(equalToConstant: 14), icon.heightAnchor.constraint(equalToConstant: 14)])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSArtworkView: UIView {
    private let gradient = CAGradientLayer()
    private let glow = CAGradientLayer()
    private let orbit = CAShapeLayer()
    private let orbitTwo = CAShapeLayer()
    private let symbolView = UIImageView()
    private let gridLayer = CAShapeLayer()

    init(symbol: String, colors: [UInt32]) {
        super.init(frame: .zero)
        clipsToBounds = true
        gradient.colors = colors.map { UIColor(hex: $0).cgColor }
        gradient.startPoint = CGPoint(x: 0.05, y: 0.05)
        gradient.endPoint = CGPoint(x: 0.95, y: 1)
        layer.addSublayer(gradient)

        glow.type = .radial
        glow.colors = [UIColor.white.withAlphaComponent(0.26).cgColor, UIColor.clear.cgColor]
        glow.locations = [0, 1]
        layer.addSublayer(glow)

        [orbit, orbitTwo].forEach {
            $0.fillColor = UIColor.clear.cgColor
            $0.strokeColor = UIColor.white.withAlphaComponent(0.26).cgColor
            $0.lineWidth = 1
            $0.lineDashPattern = [5, 8]
            layer.addSublayer($0)
        }

        gridLayer.strokeColor = UIColor.white.withAlphaComponent(0.07).cgColor
        gridLayer.lineWidth = 0.7
        layer.addSublayer(gridLayer)

        let config = UIImage.SymbolConfiguration(pointSize: 70, weight: .ultraLight)
        symbolView.image = UIImage(systemName: symbol, withConfiguration: config)
        symbolView.tintColor = UIColor.white.withAlphaComponent(0.86)
        symbolView.contentMode = .scaleAspectFit
        symbolView.layer.shadowColor = UIColor.black.cgColor
        symbolView.layer.shadowOpacity = 0.18
        symbolView.layer.shadowRadius = 22
        addSubview(symbolView)
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            symbolView.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            symbolView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.34),
            symbolView.heightAnchor.constraint(equalTo: symbolView.widthAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        glow.frame = CGRect(x: bounds.width * 0.16, y: bounds.height * 0.04, width: bounds.width * 0.92, height: bounds.width * 0.92)
        orbit.path = UIBezierPath(ovalIn: CGRect(x: bounds.midX - bounds.width * 0.34, y: bounds.midY - bounds.width * 0.42, width: bounds.width * 0.68, height: bounds.width * 0.68)).cgPath
        orbitTwo.path = UIBezierPath(ovalIn: CGRect(x: bounds.midX - bounds.width * 0.47, y: bounds.midY - bounds.width * 0.55, width: bounds.width * 0.94, height: bounds.width * 0.94)).cgPath
        let path = UIBezierPath()
        stride(from: CGFloat(0), through: bounds.width, by: 34).forEach { x in path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: bounds.height)) }
        stride(from: CGFloat(0), through: bounds.height, by: 34).forEach { y in path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: bounds.width, y: y)) }
        gridLayer.path = path.cgPath
        gridLayer.frame = bounds
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSToast {
    static func show(_ message: String, symbol: String, in host: UIView) {
        let toast = UIView()
        toast.backgroundColor = FSColor.ink.withAlphaComponent(0.94)
        toast.layer.cornerRadius = 24
        toast.layer.cornerCurve = .continuous
        toast.addShadow(opacity: 0.18, radius: 18, y: 7)
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = .white
        let label = UILabel.fs(message, font: FSFont.caption(14), color: .white, lines: 2)
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.spacing = 9
        stack.alignment = .center
        toast.addSubview(stack)
        stack.pinEdges(to: toast, insets: UIEdgeInsets(top: 13, left: 18, bottom: 13, right: 18))
        host.addSubview(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: host.safeAreaLayoutGuide.bottomAnchor, constant: -94),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 24),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -24)
        ])
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 12).scaledBy(x: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.25) { toast.alpha = 1; toast.transform = .identity }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            UIView.animate(withDuration: 0.25, animations: { toast.alpha = 0; toast.transform = CGAffineTransform(translationX: 0, y: 8) }) { _ in toast.removeFromSuperview() }
        }
    }
}

final class FSChoiceButton: UIButton {
    var choiceSelected = false { didSet { updateAppearance() } }

    init(title: String, symbol: String? = nil) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = symbol.flatMap { UIImage(systemName: $0) }
        config.imagePadding = 7
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var attrs = attrs; attrs.font = FSFont.caption(13); return attrs
        }
        configuration = config
        updateAppearance()
        installFSInteractionFeedback()
    }

    private func updateAppearance() {
        configuration?.baseBackgroundColor = choiceSelected ? FSColor.ink : FSColor.card
        configuration?.baseForegroundColor = choiceSelected ? .white : FSColor.secondaryInk
        configuration?.background.strokeColor = choiceSelected ? FSColor.ink : FSColor.line
        configuration?.background.strokeWidth = 1
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FSFormField: UIView {
    let textField = UITextField()

    init(title: String, placeholder: String, keyboard: UIKeyboardType = .default) {
        super.init(frame: .zero)
        let label = UILabel.fs(title, font: FSFont.caption(13), color: FSColor.secondaryInk, lines: 1)
        textField.placeholder = placeholder
        textField.font = FSFont.body()
        textField.textColor = FSColor.ink
        textField.keyboardType = keyboard
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 16
        textField.layer.cornerCurve = .continuous
        textField.layer.borderColor = FSColor.line.cgColor
        textField.layer.borderWidth = 1
        let left = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 52))
        textField.leftView = left
        textField.leftViewMode = .always
        let stack = UIStackView(arrangedSubviews: [label, textField])
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.pinEdges(to: self)
        textField.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

func makeScrollStack(in controller: UIViewController, bottom: CGFloat = 30) -> (UIScrollView, UIStackView) {
    let scroll = UIScrollView()
    scroll.alwaysBounceVertical = true
    scroll.keyboardDismissMode = .interactive
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 18
    controller.view.addSubview(scroll)
    scroll.pinEdges(to: controller.view)
    scroll.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 18),
        stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
        stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
        stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -bottom)
    ])
    return (scroll, stack)
}
