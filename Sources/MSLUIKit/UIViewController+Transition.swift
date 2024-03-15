import UIKit

/// When using Coordinators, you'll find that you may want to swap out one view controller for another. Instead of
/// this swap having no animation, this extension helps restore animation with the changing of views.
///
/// Example:
///
/// ```
/// self.rootViewController.present(
///    to: self.caseListViewController,
///    withOptions: .init(style: .swipe, direction: .right)
/// )
/// ```
public extension UIViewController {
    /// Defines the various options for animating between views
    struct AnimationOptions {
        let style: AnimationStyle
        let direction: AnimationDirection
        let duration: TimeInterval

        public init(
            style: AnimationStyle,
            direction: AnimationDirection = .left,
            duration: TimeInterval = 0.30
        ) {
            self.style = style
            self.direction = direction
            self.duration = duration
        }
    }

    private enum AnimationTransition {
        /// View is coming in
        case present

        /// View is going out
        case dismiss
    }

    /// Represents the type of animation that should occur for the specified UIViewController
    enum AnimationStyle {
        /// Attempts to mimic the iOS default `present` animation
        case replace

        /// Attempts to mimic the iOS default `push` animation
        case swipe
    }

    /// The direction the animation should occur
    enum AnimationDirection {
        case left
        case right
        case up
        case down
    }

    /// Animate a UIViewController onto the screen
    func present(
        to newScreen: UIViewController,
        withOptions options: AnimationOptions,
        completion: ((Bool) -> Void)? = nil
    ) {
        self.animate(
            transition: .present,
            options: options,
            to: newScreen,
            completion: completion
        )
    }

    /// Animate a UIViewController off the screen
    func dismiss(
        to newScreen: UIViewController,
        withOptions options: AnimationOptions,
        completion: ((Bool) -> Void)? = nil
    ) {
        self.animate(
            transition: .dismiss,
            options: options,
            to: newScreen,
            completion: completion
        )
    }
}

fileprivate extension UIViewController {
    private func animate(
        transition: AnimationTransition,
        options: AnimationOptions,
        to newScreen: UIViewController,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let currentScreen = self.children.first else {
            self.replaceContents(with: newScreen)
            return
        }

        guard currentScreen != newScreen else {
            return
        }

        switch options.style {
        case .replace:
            self.animateReplace(
                fromScreen: currentScreen,
                toScreen: newScreen,
                withDuration: options.duration
            )
        case .swipe:
            self.animateSwipe(
                fromScreen: currentScreen,
                toScreen: newScreen,
                transition: transition,
                direction: options.direction,
                withDuration: options.duration
            )
        }
    }

    private func animateReplace(
        fromScreen: UIViewController,
        toScreen: UIViewController,
        withDuration duration: TimeInterval
    ) {
        self.addChild(toScreen)
        self.view.addSubview(toScreen.view)
        toScreen.view.transform = .identity
        toScreen.view.frame = self.view.bounds
        toScreen.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toScreen.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.maxY)

        fromScreen.view.layer.cornerRadius = 0
        fromScreen.view.layer.masksToBounds = true

        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) { [weak fromScreen] in
                    var transform = CATransform3DIdentity
                    transform = CATransform3DScale(transform, 0.9, 0.9, 1.01)
                    fromScreen?.view.layer.transform = transform

                    fromScreen?.view.layer.cornerRadius = 6
                    fromScreen?.view.alpha = 0.5
                }

                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.75) { [weak toScreen] in
                    toScreen?.view.transform = CGAffineTransform.identity
                }
            },
            completion: { [weak self] _ in
                self?.remove(childViewController: fromScreen)
                toScreen.didMove(toParent: self)
                fromScreen.view.layer.cornerRadius = 0
                fromScreen.view.transform = CGAffineTransform.identity
                fromScreen.view.alpha = 1
            }
        )
    }

    // swiftlint:disable cyclomatic_complexity
    private func animateSwipe(
        fromScreen: UIViewController,
        toScreen: UIViewController,
        transition: AnimationTransition,
        direction: AnimationDirection,
        withDuration duration: TimeInterval
    ) {
        self.addChild(toScreen)

        self.view.addSubview(toScreen.view)
        toScreen.view.transform = .identity
        toScreen.view.frame = self.view.bounds
        toScreen.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let shadowRadius = CGFloat(10)
        self.addShadow(to: toScreen.view)

        if transition == .dismiss {
            self.view.bringSubviewToFront(fromScreen.view)

            switch direction {
            case .left:
                toScreen.view.transform = CGAffineTransform(
                    translationX: (self.view.frame.maxX / 4), y: 0
                )
            case .right:
                toScreen.view.transform = CGAffineTransform(
                    translationX: -(self.view.frame.maxX / 4), y: 0
                )
            default:
                break
            }
        } else {
            switch direction {
            case .left:
                toScreen.view.transform = CGAffineTransform(translationX: self.view.frame.maxX + shadowRadius, y: 0)
            case .right:
                toScreen.view.transform = CGAffineTransform(translationX: -(self.view.frame.maxX + shadowRadius), y: 0)
            case .down:
                toScreen.view.transform = CGAffineTransform(translationX: 0, y: -self.view.frame.maxY)
            case .up:
                toScreen.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.maxY)
            }
        }

        let keyFrameAnimation: UIView.AnimationOptions
        if transition == .dismiss {
            keyFrameAnimation = .curveEaseInOut
        } else {
            keyFrameAnimation = .curveEaseInOut
        }

        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: UIView.KeyframeAnimationOptions(rawValue: keyFrameAnimation.rawValue),
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) { [weak toScreen] in
                    toScreen?.view.transform = CGAffineTransform.identity

                    if transition == .dismiss {
                        switch direction {
                        case .left:
                            fromScreen.view.transform = CGAffineTransform(
                                translationX: -(self.view.frame.maxX + shadowRadius), y: 0
                            )
                        case .right:
                            fromScreen.view.transform = CGAffineTransform(
                                translationX: self.view.frame.maxX + shadowRadius, y: 0
                            )
                        case .down:
                            fromScreen.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.maxY)
                        case .up:
                            fromScreen.view.transform = CGAffineTransform(translationX: 0, y: -self.view.frame.maxY)
                        }
                    } else {
                        switch direction {
                        case .left:
                            fromScreen.view.transform = CGAffineTransform(
                                translationX: -(self.view.frame.maxX / 4), y: 0
                            )
                        case .right:
                            fromScreen.view.transform = CGAffineTransform(
                                translationX: self.view.frame.maxX / 4, y: 0
                            )
                        default:
                            break
                        }
                    }
                }
            },
            completion: { [weak self] _ in
                self?.remove(childViewController: fromScreen)
                toScreen.didMove(toParent: self)
            }
        )
    }
    // swiftlint:enable cyclomatic_complexity

    private func addShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10

        // Make more performant
        view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale

        // Make sure the shadow doesn't get clipped
        view.clipsToBounds = false
    }
}
