import SwiftUI

extension ActivityScoreTone {
    var color: Color {
        switch self {
        case .favorable: .green
        case .neutral: .orange
        case .unfavorable: .red
        }
    }
}
