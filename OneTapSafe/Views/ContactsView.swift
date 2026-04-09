//
//  ContactsView.swift
//  OneTapSafe
//

import SwiftUI

struct ContactsView: View {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAddContact = false
    @State private var showingPaywall = false
    @State private var contactToVerify: TrustedContact?
    @State private var verificationCodeInput = ""
    @State private var showVerificationError = false
    
    var body: some View {
        NavigationStack {
            List {
                if dataStore.trustedContacts.isEmpty {
                    ContentUnavailableView(
                        "No Emergency Contacts",
                        systemImage: "person.2.slash",
                        description: Text("Add a trusted contact who will be notified if you miss your daily check-in")
                    )
                } else {
                    ForEach(dataStore.trustedContacts) { contact in
                        HStack {
                            NavigationLink {
                                EditContactView(contact: contact)
                            } label: {
                                ContactRow(contact: contact)
                            }
                            
                            if contact.consentStatus == .pending {
                                Button("Verify") {
                                    contactToVerify = contact
                                    verificationCodeInput = ""
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                            }
                        }
                    }
                    .onDelete(perform: deleteContacts)
                }
            }
            .navigationTitle("Emergency Contacts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if subscriptionManager.canAddContact(currentCount: dataStore.trustedContacts.count) {
                            showingAddContact = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                if !dataStore.trustedContacts.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView()
            }
            .sheet(isPresented: $showingPaywall) {
                OB11PaywallView(vm: OnboardingViewModel(), onComplete: { showingPaywall = false })
            }
            .alert("Verify Contact", isPresented: Binding(
                get: { contactToVerify != nil },
                set: { if !$0 { contactToVerify = nil } }
            )) {
                TextField("6-digit code", text: $verificationCodeInput)
                    .keyboardType(.numberPad)
                Button("Verify") {
                    verifyContact()
                }
                Button("Cancel", role: .cancel) {
                    contactToVerify = nil
                    verificationCodeInput = ""
                }
            } message: {
                Text("Enter the 6-digit verification code that \(contactToVerify?.name ?? "your contact") received via email.")
            }
            .alert("Verification Failed", isPresented: $showVerificationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The code you entered doesn't match. Please check with your contact and try again.")
            }
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = dataStore.trustedContacts[index]
            dataStore.deleteContact(contact)
        }
    }
    
    private func verifyContact() {
        guard let contact = contactToVerify,
              let storedCode = contact.verificationCode,
              verificationCodeInput == storedCode else {
            showVerificationError = true
            return
        }
        
        // Update contact status to verified
        var updatedContact = contact
        updatedContact.consentStatus = .verified
        dataStore.updateContact(updatedContact)
        FirebaseManager.shared.logEvent(name: "contact_verified")
        
        contactToVerify = nil
        verificationCodeInput = ""
    }
}

struct ContactRow: View {
    let contact: TrustedContact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(contact.name)
                    .font(.headline)
                
                if contact.consentStatus == .verified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text(contact.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Phone Number - Hidden for free version
            // if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
            //     HStack {
            //         Image(systemName: "phone.fill")
            //             .foregroundColor(.green)
            //             .font(.caption)
            //         Text(phoneNumber)
            //             .font(.subheadline)
            //             .foregroundColor(.secondary)
            //     }
            // }
            
            HStack {
                // Notification method badge - Hidden for now (only Email)
                // Text(contact.notificationMethod.rawValue)
                //     .font(.caption)
                //     .padding(.horizontal, 8)
                //     .padding(.vertical, 4)
                //     .background(Color.green.opacity(0.2))
                //     .foregroundColor(.green)
                //     .cornerRadius(8)
                
                if contact.consentStatus == .pending {
                    Text("⏳ Pending")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContactsView()
}
