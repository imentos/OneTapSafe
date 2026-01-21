//
//  EditContactView.swift
//  OneTapSafe
//

import SwiftUI

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataStore = DataStore.shared
    
    let contact: TrustedContact
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var email: String
    @State private var notificationMethod: NotificationMethod
    
    init(contact: TrustedContact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phoneNumber = State(initialValue: contact.phoneNumber)
        _email = State(initialValue: contact.email ?? "")
        _notificationMethod = State(initialValue: contact.notificationMethod)
    }
    
    var isValid: Bool {
        !name.isEmpty && !phoneNumber.isEmpty
    }
    
    var body: some View {
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
        }
        .navigationTitle("Edit Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveContact()
                }
                .disabled(!isValid)
            }
        }
    }
    
    private func saveContact() {
        let updatedContact = TrustedContact(
            id: contact.id,
            name: name,
            phoneNumber: phoneNumber,
            email: email.isEmpty ? nil : email,
            notificationMethod: notificationMethod
        )
        dataStore.updateContact(updatedContact)
        dismiss()
    }
}
