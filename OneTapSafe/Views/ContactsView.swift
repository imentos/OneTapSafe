//
//  ContactsView.swift
//  OneTapSafe
//

import SwiftUI

struct ContactsView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var showingAddContact = false
    
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
                        NavigationLink {
                            EditContactView(contact: contact)
                        } label: {
                            ContactRow(contact: contact)
                        }
                    }
                    .onDelete(perform: deleteContacts)
                }
            }
            .navigationTitle("Emergency Contacts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddContact = true
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
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = dataStore.trustedContacts[index]
            dataStore.deleteContact(contact)
        }
    }
}

struct ContactRow: View {
    let contact: TrustedContact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(contact.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let email = contact.email, !email.isEmpty {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(contact.notificationMethod.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContactsView()
}
