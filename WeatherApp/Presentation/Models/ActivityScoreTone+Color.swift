import SwiftUI

extension ActivityScoreTone {
    var color: Color {
        switch self {
        case .favorable: Color("ScoreGreen")
        case .neutral: Color("ScoreOrange")
        case .unfavorable: Color("ScoreRed")
        }
    }
}
