//
//  AddContactView.swift
//  OneTapSafe
//

import SwiftUI

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var notificationMethod: NotificationMethod = .email
    @State private var showPaywall = false
    @State private var showLimitAlert = false
    
    var isValid: Bool {
        !name.isEmpty && !email.isEmpty
    }
    
    var canAddContact: Bool {
        subscriptionManager.canAddContact(currentCount: dataStore.trustedContacts.count)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Contact limit warning for free users
                if !canAddContact {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.badge.gearshape.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.green.gradient)
                            
                            Text("Contact Limit Reached")
                                .font(.headline)
                            
                            Text("Free users can add 1 emergency contact. Upgrade to Pro for unlimited contacts and premium features.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { showPaywall = true }) {
                                Text("Upgrade to Pro")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Section("Contact Information") {
                    TextField("Name", text: $name)
                        .disabled(!canAddContact)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disabled(!canAddContact)
                    TextField("Phone Number (Optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .disabled(!canAddContact)
                }
                
                Section("Notification Method") {
                    Picker("Method", selection: $notificationMethod) {
                        ForEach(NotificationMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!canAddContact)
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
                    .disabled(!isValid || !canAddContact)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    private func addContact() {
        let contact = TrustedContact(
            name: name,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            email: email,
            notificationMethod: notificationMethod
        )
        dataStore.addContact(contact)
        dismiss()
    }
}

#Preview {
    AddContactView()
}
