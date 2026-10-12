import UIKit

/// 使用 Apple 原生 `UITabBarController` 管理底部导航。
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    private let publishController = UIViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureSystemTabBar()
        setupControllers()
    }

    private func configureSystemTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.24)

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = FSColor.ink
        tabBar.unselectedItemTintColor = .secondaryLabel
        tabBar.isTranslucent = true
    }

    private func setupControllers() {
        let course = makeNavigationController(
            root: CourseFeedViewController(),
            title: "课程",
            symbol: "rectangle.stack",
            selectedSymbol: "rectangle.stack.fill"
        )
        let projects = makeNavigationController(
            root: ProjectsViewController(),
            title: "项目",
            symbol: "square.grid.2x2",
            selectedSymbol: "square.grid.2x2.fill"
        )
        let profile = makeNavigationController(
            root: ProfileViewController(),
            title: "我的",
            symbol: "person.crop.circle",
            selectedSymbol: "person.crop.circle.fill"
        )

        publishController.view.backgroundColor = FSColor.canvas
        publishController.tabBarItem = UITabBarItem(
            title: "+",
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle.fill")
        )
        publishController.tabBarItem.accessibilityLabel = "发布"
        publishController.tabBarItem.accessibilityHint = "根据当前身份发布需求或可传授课程"

        if #available(iOS 18.0, *) {
            let courseTab = UITab(
                title: "课程",
                image: UIImage(systemName: "rectangle.stack.fill"),
                identifier: "courses"
            ) { _ in course }
            let projectTab = UITab(
                title: "项目",
                image: UIImage(systemName: "square.grid.2x2.fill"),
                identifier: "projects"
            ) { _ in projects }
            let profileTab = UITab(
                title: "我的",
                image: UIImage(systemName: "person.crop.circle.fill"),
                identifier: "profile"
            ) { _ in profile }
            // `UISearchTab` 是 Apple 为参考图中“尾部独立圆形 Tab”提供的原生类型。
            // 这里保留它的系统布局行为，只把可写的标题、SF Symbol 和动作换成发布入口。
            let publishTab = UISearchTab { [publishController] _ in publishController }
            publishTab.title = "+"
            publishTab.image = UIImage(systemName: "plus")
            publishTab.accessibilityIdentifier = "publish"
            publishTab.preferredPlacement = .pinned
            if #available(iOS 26.0, *) {
                publishTab.automaticallyActivatesSearch = false
            }
            tabs = [courseTab, projectTab, profileTab, publishTab]
            selectedTab = courseTab
        } else {
            viewControllers = [course, projects, profile, publishController]
            selectedIndex = 0
        }
    }

    private func makeNavigationController(
        root: UIViewController,
        title: String,
        symbol: String,
        selectedSymbol: String
    ) -> UINavigationController {
        let navigation = UINavigationController(rootViewController: root)
        navigation.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: symbol),
            selectedImage: UIImage(systemName: selectedSymbol)
        )

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        navigation.navigationBar.standardAppearance = appearance
        navigation.navigationBar.scrollEdgeAppearance = appearance
        return navigation
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard viewController === publishController else { return true }
        handlePublish()
        return false
    }

    @available(iOS 18.0, *)
    func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        guard tab.accessibilityIdentifier == "publish" else { return true }
        handlePublish()
        return false
    }

    private func handlePublish() {
        switch AppStore.shared.activeRole {
        case .parent:
            startParentPublish()
        case .guide:
            startGuidePublish()
        case .visitor:
            let sheet = UIAlertController(
                title: "你想发布什么？",
                message: "发布前需要选择身份并完成登录",
                preferredStyle: .actionSheet
            )
            sheet.addAction(UIAlertAction(title: "发布孩子需求", style: .default) { [weak self] _ in
                self?.startParentPublish()
            })
            sheet.addAction(UIAlertAction(title: "发布可传授课程", style: .default) { [weak self] _ in
                self?.startGuidePublish()
            })
            sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(sheet, animated: true)
        }
    }

    private func startParentPublish() {
        guard let navigation = currentNavigationController else { return }
        AuthGate.require(role: .parent, from: self) {
            navigation.pushViewController(DemandComposerViewController(), animated: true)
        }
    }

    private func startGuidePublish() {
        guard let navigation = currentNavigationController else { return }
        AuthGate.require(role: .guide, from: self) {
            navigation.pushViewController(ProjectComposerViewController(), animated: true)
        }
    }

    private var currentNavigationController: UINavigationController? {
        if #available(iOS 18.0, *) {
            return selectedTab?.viewController as? UINavigationController
        }
        return selectedViewController as? UINavigationController
    }
}
