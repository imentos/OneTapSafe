import SwiftUI

struct OB11PaywallView: View {
    @ObservedObject var vm: OnboardingViewModel
    var onComplete: () -> Void
    var body: some View { Text("Paywall") }
}
