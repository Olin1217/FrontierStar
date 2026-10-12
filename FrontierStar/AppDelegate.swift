import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if #available(iOS 13.0, *), Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") != nil {
            return true
        }
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        FSApp.window = window
        FSApp.configureAppearance()
        window.rootViewController = FSApp.initialViewController()
        window.makeKeyAndVisible()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

enum FSApp {
    static weak var window: UIWindow?

    static func configureAppearance() {
        UINavigationBar.appearance().tintColor = FSColor.ink
        UIBarButtonItem.appearance().setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 15, weight: .semibold)], for: .normal)
    }

    static func initialViewController() -> UIViewController {
        AppStore.shared.hasSelectedRole ? MainTabBarController() : IdentityViewController()
    }

    static func showIdentity(animated: Bool = true) {
        setRoot(IdentityViewController(), animated: animated)
    }

    static func showMain(animated: Bool = true) {
        setRoot(MainTabBarController(), animated: animated)
    }

    static func setRoot(_ viewController: UIViewController, animated: Bool) {
        guard let window else { return }
        if animated {
            UIView.transition(with: window, duration: 0.34, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
                window.rootViewController = viewController
            }
        } else {
            window.rootViewController = viewController
        }
    }

    static var topViewController: UIViewController? {
        func top(from controller: UIViewController?) -> UIViewController? {
            if let presented = controller?.presentedViewController { return top(from: presented) }
            if let navigation = controller as? UINavigationController { return top(from: navigation.visibleViewController) }
            if let tabs = controller as? UITabBarController { return top(from: tabs.selectedViewController) }
            return controller
        }
        return top(from: window?.rootViewController)
    }
}
