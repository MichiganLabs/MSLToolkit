import Foundation

public protocol DefaultValueProvider {
    init()
}

public protocol KeyPathListable: DefaultValueProvider {
    static var allKeyPaths: [String: AnyKeyPath] { get }
    static var allProperties: [String] { get }
//    static var reflectionCache: Mirror { get }
}

extension KeyPathListable {
    private static var _membersToKeyPaths: [String: AnyKeyPath]? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.membersToKeyPaths) as? [String: AnyKeyPath]
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.membersToKeyPaths,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private subscript(checkedMirrorDescendant key: String) -> Any? {
        return Mirror(reflecting: self).descendant(key)
    }

    static var allKeyPaths: [String: AnyKeyPath] {
        if _membersToKeyPaths == nil {
            var keyPaths = [String: PartialKeyPath<Self>]()

            let mirror = Mirror(reflecting: Self())

            for case let (key?, _) in mirror.children {
                keyPaths[key] = \Self.[checkedMirrorDescendant: key] as PartialKeyPath
            }

            _membersToKeyPaths = keyPaths
        }

        return _membersToKeyPaths ?? [:]
    }

    private static var _allProperties: [String]? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.allProperties) as? [String]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.allProperties, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static var allProperties: [String] {
        if _allProperties == nil {
            _allProperties = [String]()

            let mirror = Mirror(reflecting: Self())

            for case let (key?, _) in mirror.children {
                _allProperties!.append(key)
            }
        }

        return _allProperties!
    }

    private var _reflectionCache: Mirror? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.reflectionCache) as? Mirror
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.reflectionCache,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    mutating func reflectionCache() -> Mirror {
        if let cache = _reflectionCache {
            return cache
        } else {
            let mirror = Mirror(reflecting: self)
            self._reflectionCache = mirror

            return mirror
        }
    }
}

private enum AssociatedKeys {
    static var membersToKeyPaths: UInt8 = 0
    static var allProperties: UInt8 = 0
    static var reflectionCache: UInt8 = 0
}

// public protocol KeyPathListable {
//    var allKeyPaths: [String: PartialKeyPath<Self>] { get }
// }
//
// extension KeyPathListable {
//
//    private subscript(checkedMirrorDescendant key: String) -> Any {
//        return Mirror(reflecting: self).descendant(key)!
//    }
//
//    var allKeyPaths: [String: PartialKeyPath<Self>] {
//        var membersTokeyPaths = [String: PartialKeyPath<Self>]()
//        let mirror = Mirror(reflecting: self)
//        for case (let key?, _) in mirror.children {
//            membersTokeyPaths[key] = \Self.[checkedMirrorDescendant: key] as PartialKeyPath
//        }
//        return membersTokeyPaths
//    }
//
// }
