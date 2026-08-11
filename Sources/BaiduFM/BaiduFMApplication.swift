#if canImport(UIKit)
import UIKit

/// Provides the application shell with a stable entry point into the BaiduFM package.
public enum BaiduFMApplication {
    /// Creates the root view controller stored in the package resource bundle.
    @MainActor
    public static func makeRootViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .module)
        guard let rootViewController = storyboard.instantiateInitialViewController() else {
            return makeConfigurationErrorViewController()
        }
        return rootViewController
    }

    private static func makeConfigurationErrorViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = L10n.applicationConfigurationFailed

        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: viewController.view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: viewController.view.layoutMarginsGuide.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
        ])
        return viewController
    }
}
#endif
