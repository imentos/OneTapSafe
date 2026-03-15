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
    @State private var showConsentInfo = false
    @State private var generatedCode = ""
    @State private var showNamePrompt = false
    @State private var tempUserName = ""
    
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
                    // Phone Number - Coming in Pro version
                    // TextField("Phone Number (Optional)", text: $phoneNumber)
                    //     .keyboardType(.phonePad)
                    //     .disabled(!canAddContact)
                }
                
                // Notification Method - Hidden for now (only Email supported)
                // Section("Notification Method") {
                //     Picker("Method", selection: $notificationMethod) {
                //         ForEach(NotificationMethod.allCases, id: \.self) { method in
                //             Text(method.rawValue).tag(method)
                //         }
                //     }
                //     .pickerStyle(.segmented)
                //     .disabled(!canAddContact)
                // }
                
                Section {
                    Text("This contact will be notified via email if you miss your daily check-in or trigger an emergency alert")
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
                        checkUserNameAndAddContact()
                    }
                    .disabled(!isValid || !canAddContact)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Consent Request Sent", isPresented: $showConsentInfo) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("A verification code (\(generatedCode)) has been sent to \(email). Ask your contact to share this code with you, then verify them in the Contacts tab to enable notifications.")
            }
            .alert("Enter Your Name", isPresented: $showNamePrompt) {
                TextField("Your name", text: $tempUserName)
                Button("Cancel", role: .cancel) {
                    tempUserName = ""
                }
                Button("Save & Continue") {
                    if !tempUserName.trimmingCharacters(in: .whitespaces).isEmpty {
                        dataStore.updateUserName(tempUserName.trimmingCharacters(in: .whitespaces))
                        addContact()
                    }
                    tempUserName = ""
                }
            } message: {
                Text("Your name will appear in emergency alerts sent to your contacts. This helps them know who needs help.")
            }
        }
    }
    
    private func checkUserNameAndAddContact() {
        if !dataStore.isUserNameValid() {
            tempUserName = dataStore.userName
            showNamePrompt = true
        } else {
            addContact()
        }
    }
    
    private func addContact() {
        // Generate verification code
        let verificationCode = TrustedContact.generateVerificationCode()
        generatedCode = verificationCode
        
        let contact = TrustedContact(
            name: name,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            email: email,
            notificationMethod: notificationMethod,
            consentStatus: .pending,
            verificationCode: verificationCode
        )
        
        // Send consent email
        Task {
            await ContactNotifier.shared.sendConsentRequest(
                to: email,
                contactName: name,
                verificationCode: verificationCode,
                userName: dataStore.userName
            )
        }
        
        dataStore.addContact(contact)
        showConsentInfo = true
    }
}

#Preview {
    AddContactView()
}
