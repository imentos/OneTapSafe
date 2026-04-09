import SwiftUI

struct OB1WelcomeView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View { Text("Welcome") }
}
