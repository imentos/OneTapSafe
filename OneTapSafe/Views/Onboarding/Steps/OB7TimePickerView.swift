//
//  OB7TimePickerView.swift
//  OneTapSafe
//

import SwiftUI

struct OB7TimePickerView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let presets: [(label: String, note: String, hour: Int, minute: Int)] = [
        ("7:00 AM", "Early riser",    7,  0),
        ("9:00 AM", "After breakfast", 9,  0),
        ("11:00 AM", "Mid-morning",   11,  0),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("When should they\ncheck in?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Pick a time that fits their morning routine.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            // Preset chips
            HStack(spacing: 12) {
                ForEach(presets, id: \.label) { preset in
                    PresetChip(
                        label: preset.label,
                        note: preset.note,
                        isSelected: isPresetSelected(preset)
                    ) {
                        vm.reminderTime = Calendar.current.date(
                            from: DateComponents(hour: preset.hour, minute: preset.minute)
                        ) ?? vm.reminderTime
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            // Time picker wheel
            DatePicker(
                "Check-in time",
                selection: $vm.reminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Text("They'll have 8 hours to tap before contacts are notified.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: { vm.advance() }) {
                Text("Set this time ->")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func isPresetSelected(_ preset: (label: String, note: String, hour: Int, minute: Int)) -> Bool {
        let cal = Calendar.current
        let h = cal.component(.hour, from: vm.reminderTime)
        let m = cal.component(.minute, from: vm.reminderTime)
        return h == preset.hour && m == preset.minute
    }
}

private struct PresetChip: View {
    let label: String
    let note: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())
                Text(note)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .green.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.green : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemBackground))
                    )
            )
            .foregroundColor(isSelected ? .green : .primary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    OB7TimePickerView(vm: OnboardingViewModel())
}
