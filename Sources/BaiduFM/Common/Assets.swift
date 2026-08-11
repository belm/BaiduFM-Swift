#if canImport(UIKit)
import UIKit

enum Asset {
    static func image(named name: String) -> UIImage? {
        UIImage(named: name, in: .module, compatibleWith: nil)
    }
}

#endif
