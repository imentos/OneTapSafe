//
//  AddContactView.swift
//  OneTapSafe
//

import SwiftUI

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataStore = DataStore.shared
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var notificationMethod: NotificationMethod = .sms
    
    var isValid: Bool {
        !name.isEmpty && !phoneNumber.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Information") {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email (Optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Notification Method") {
                    Picker("Method", selection: $notificationMethod) {
                        ForEach(NotificationMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Text("This contact will be notified if you miss your daily check-in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addContact()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func addContact() {
        let contact = TrustedContact(
            name: name,
            phoneNumber: phoneNumber,
            email: email.isEmpty ? nil : email,
            notificationMethod: notificationMethod
        )
        dataStore.addContact(contact)
        dismiss()
    }
}

#Preview {
    AddContactView()
}
