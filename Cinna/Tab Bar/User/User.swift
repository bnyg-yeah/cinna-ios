//
//  User.swift
//  Cinna
//
//  Created by Brighton Young on 9/26/25.
//

import SwiftUI

struct User: View {
    @EnvironmentObject private var userInfo: UserInfoData
    @EnvironmentObject private var moviePreferences: MoviePreferencesData
    @State private var showNotifications = false

    //Custom notifications - temporary
    private let notifications: [UserNotification] = [
        .init(
            id: UUID(),
            title: "Ticket Reminder",
            message: "Don't forget your showing tonight at 7:30 PM."
        ),
        .init(
            id: UUID(),
            title: "New Recommendation",
            message: "We've added sci-fi thrillers to your weekly picks."
        ),
        .init(
            id: UUID(),
            title: "Seat Upgrade",
            message: "Premium seating now available for your favorite theater."
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {

                //body shit
                ScrollView {

                    (Text("My \(Text("Cinna").italic())"))
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .center, spacing: 6) {
                        Text("Member since October 2, 2025")
                            .font(.headline)
                        Text(
                            "Thank you for being an \(Text("OG").bold()) \(Text("Cinna").italic()) !"
                        )
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    //list of menu items
                    VStack(spacing: 12) {
                        NavigationLink(destination: Profile()) {
                            UserMenuItem(
                                title: "Profile",
                                systemImage: "person.crop.circle"
                            )
                        }

                        NavigationLink(destination: MovieTickets()) {
                            UserMenuItem(
                                title: "Movie Tickets",
                                systemImage: "ticket"
                            )
                        }

                        NavigationLink(destination: MoviePreferences()) {
                            UserMenuItem(
                                title: "Movie Preferences",
                                systemImage: "slider.horizontal.3"
                            )
                        }

                        NavigationLink(destination: PrivacySecurity()) {
                            UserMenuItem(
                                title: "Privacy & Security",
                                systemImage: "lock.shield"
                            )
                        }
                    }  //end list of menu items

                    Image("UserPicture")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)

                }  //end body
                .padding(.horizontal, 20)
                

                if showNotifications {
                    NotificationDropdown(notifications: notifications)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.trailing)
                        .padding(.top, 8)
                }
            }
            .navigationTitle(
                Text("User")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                //                ToolbarItem(placement: .topBarLeading) {
                //                    (Text("My \(Text("Cinna").italic())"))
                //                        .font(.headline)
                //                        .lineLimit(1)
                //                        .fixedSize()
                //                        .allowsHitTesting(false)
                //                        .accessibilityAddTraits(.isHeader)
                //                } //appears to be impossible to make it all the way to the left

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(
                            .spring(response: 0.3, dampingFraction: 0.8)
                        ) {
                            showNotifications.toggle()
                        }
                    } label: {
                        Image(
                            systemName: showNotifications ? "bell.fill" : "bell"
                        )
                        .font(.title3.weight(.semibold))
                        .accessibilityLabel("Notifications")
                    }
                }
            }

        }
    }
}

private struct NotificationDropdown: View {
    let notifications: [UserNotification]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)

            if notifications.isEmpty {
                Text("You're all caught up!")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(notifications) { notification in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.title)
                            .font(.subheadline.weight(.semibold))
                        Text(notification.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                    if notification.id != notifications.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 280, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
    }
}

private struct UserNotification: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
}

#Preview {
    User()
}
