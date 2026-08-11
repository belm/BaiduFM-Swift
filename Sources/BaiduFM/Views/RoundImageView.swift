#if canImport(UIKit)
import UIKit

final class RoundImageView: UIImageView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    private func configure() {
        clipsToBounds = true
        contentMode = .scaleAspectFill
        backgroundColor = .secondarySystemBackground
    }

    func setPlaybackActive(_ isActive: Bool) {
        layer.removeAllAnimations()

        let targetTransform = isActive
            ? CGAffineTransform.identity
            : CGAffineTransform(scaleX: 0.97, y: 0.97)
        guard !UIAccessibility.isReduceMotionEnabled else {
            transform = targetTransform
            return
        }

        UIView.animate(
            withDuration: 0.36,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.2,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: { [weak self] in
                self?.transform = targetTransform
            }
        )
    }
}

#endif
