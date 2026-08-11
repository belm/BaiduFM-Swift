#if canImport(UIKit)
import UIKit

enum ExperienceTheme {
    static let accent = UIColor(red: 0.42, green: 0.32, blue: 0.98, alpha: 1)
    static let favorite = UIColor.systemPink
    static let artworkCornerRadius: CGFloat = 28
    static let cardCornerRadius: CGFloat = 24
    static let horizontalMargin: CGFloat = 24
    static let minimumTouchTarget: CGFloat = 44

    static func configureGlobalAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithDefaultBackground()
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.preferredFont(forTextStyle: .headline),
        ]
        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = accent

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        [
            tabAppearance.stackedLayoutAppearance,
            tabAppearance.inlineLayoutAppearance,
            tabAppearance.compactInlineLayoutAppearance,
        ].forEach { itemAppearance in
            itemAppearance.selected.iconColor = accent
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: accent]
        }
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
    }

    static func styleList(_ tableView: UITableView) {
        tableView.rowHeight = 72
        tableView.estimatedRowHeight = 72
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorColor = .separator.withAlphaComponent(0.55)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 0, right: 20)
        tableView.keyboardDismissMode = .interactive
    }

    static func styleListCell(_ cell: UITableViewCell) {
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.tintColor = accent
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.layer.cornerRadius = 9
        cell.imageView?.clipsToBounds = true
    }

    static func makeSymbolConfiguration(pointSize: CGFloat, weight: UIImage.SymbolWeight = .semibold) -> UIImage.SymbolConfiguration {
        UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
    }
}

enum ExperienceFeedback {
    static func transport() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

enum ExperienceMotion {
    static func reveal(cell: UITableViewCell) {
        let isAlreadyAnimating = !(cell.layer.animationKeys()?.isEmpty ?? true)
        guard !UIAccessibility.isReduceMotionEnabled, !isAlreadyAnimating else { return }
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 8)
        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseOut]
        ) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}

final class ExperienceEmptyStateView: UIView {
    private let imageView = UIImageView()
    private let label = UILabel()

    init(message: String, systemImage: String) {
        super.init(frame: .zero)
        configure(message: message, systemImage: systemImage)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure(message: L10n.noData, systemImage: "music.note.list")
    }

    private func configure(message: String, systemImage: String) {
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        imageView.image = UIImage(systemName: systemImage)
        imageView.tintColor = .tertiaryLabel
        imageView.preferredSymbolConfiguration = ExperienceTheme.makeSymbolConfiguration(pointSize: 44, weight: .regular)

        label.text = message
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0

        isAccessibilityElement = true
        accessibilityLabel = message

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            imageView.widthAnchor.constraint(equalToConstant: 54),
            imageView.heightAnchor.constraint(equalToConstant: 54),
        ])
    }
}
#endif
