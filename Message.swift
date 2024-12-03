
import Foundation

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let sender: SenderType
    let timestamp: Date

    enum SenderType {
        case user
        case ai
    }
}
