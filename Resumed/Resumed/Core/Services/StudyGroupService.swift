//
//  StudyGroupService.swift
//  Resumed
//
//  Local-first Study Group service (UserDefaults persistence).
//  Supabase sync methods are stubbed — switching to real backend only
//  requires replacing the private persistence layer, not the UI contracts.
//

import Foundation
import Combine

@MainActor
final class StudyGroupService: ObservableObject {
    static let shared = StudyGroupService()

    @Published var myGroups: [StudyGroup] = []
    @Published var activeChallenges: [GroupChallenge] = []

    private let groupsKey = "studyGroups_v1"
    private let challengesKey = "studyChallenges_v1"

    private init() {
        loadGroups()
        loadAllChallenges()
    }

    // MARK: - Current user helpers

    private var currentUserId: String {
        SupabaseManager.shared.currentUser?.id ?? "local_user"
    }

    private var currentUserName: String {
        SupabaseManager.shared.currentUser?.fullName
            ?? UserDefaults.standard.string(forKey: "userFullName")
            ?? "Você"
    }

    // MARK: - Group CRUD

    @discardableResult
    func createGroup(name: String) -> StudyGroup {
        let group = StudyGroup(
            id: UUID().uuidString,
            name: name,
            ownerId: currentUserId,
            memberIds: [currentUserId],
            memberNames: [currentUserName],
            createdAt: Date(),
            inviteCode: StudyGroupService.generateInviteCode()
        )
        myGroups.append(group)
        saveGroups()
        HapticManager.shared.success()
        return group
    }

    @discardableResult
    func joinGroup(inviteCode: String) -> StudyGroup? {
        let code = inviteCode.uppercased().trimmingCharacters(in: .whitespaces)

        // Check if user is already a member
        if let existing = myGroups.first(where: { $0.inviteCode == code }) {
            return existing
        }

        // In local-first mode we can only join groups stored on this device.
        // When Supabase backend is added this will hit the API instead.
        guard let index = myGroups.firstIndex(where: { $0.inviteCode == code }) else {
            return nil
        }

        let uid = currentUserId
        guard !myGroups[index].memberIds.contains(uid) else { return myGroups[index] }
        myGroups[index].memberIds.append(uid)
        myGroups[index].memberNames.append(currentUserName)
        saveGroups()
        HapticManager.shared.success()
        return myGroups[index]
    }

    func leaveGroup(id: String) {
        let uid = currentUserId
        if let index = myGroups.firstIndex(where: { $0.id == id }) {
            if let memberIndex = myGroups[index].memberIds.firstIndex(of: uid) {
                myGroups[index].memberIds.remove(at: memberIndex)
                if memberIndex < myGroups[index].memberNames.count {
                    myGroups[index].memberNames.remove(at: memberIndex)
                }
            }
            // If owner leaves — remove group entirely (local-first behaviour)
            if myGroups[index].ownerId == uid {
                myGroups.remove(at: index)
            }
        }
        saveGroups()
    }

    func loadGroups() {
        guard let data = UserDefaults.standard.data(forKey: groupsKey),
              let decoded = try? JSONDecoder().decode([StudyGroup].self, from: data)
        else { return }
        myGroups = decoded
    }

    // MARK: - Challenge CRUD

    @discardableResult
    func createChallenge(
        groupId: String,
        title: String,
        description: String,
        metric: GroupChallenge.ChallengeMetric,
        durationDays: Int
    ) -> GroupChallenge {
        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: durationDays, to: now) ?? now
        let challenge = GroupChallenge(
            id: UUID().uuidString,
            groupId: groupId,
            title: title,
            description: description,
            startDate: now,
            endDate: end,
            entries: [],
            metric: metric,
            isActive: true
        )
        activeChallenges.append(challenge)
        saveChallenges()
        HapticManager.shared.success()
        return challenge
    }

    func updateMyScore(challengeId: String, score: Int) {
        guard let index = activeChallenges.firstIndex(where: { $0.id == challengeId }) else { return }
        let uid = currentUserId
        if let entryIndex = activeChallenges[index].entries.firstIndex(where: { $0.userId == uid }) {
            activeChallenges[index].entries[entryIndex].score = score
            activeChallenges[index].entries[entryIndex].lastUpdated = Date()
        } else {
            let entry = ChallengeEntry(
                id: UUID().uuidString,
                userId: uid,
                displayName: currentUserName,
                score: score,
                lastUpdated: Date()
            )
            activeChallenges[index].entries.append(entry)
        }
        saveChallenges()
    }

    func loadChallenges(for groupId: String) {
        loadAllChallenges()
        activeChallenges = activeChallenges.filter { $0.groupId == groupId && !$0.hasEnded }
    }

    func allChallenges(for groupId: String) -> [GroupChallenge] {
        let all = loadAllChallengesRaw()
        return all.filter { $0.groupId == groupId }
    }

    // MARK: - Invite Code

    static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }

    // MARK: - Local Persistence (swap for Supabase calls when backend is ready)

    private func saveGroups() {
        if let data = try? JSONEncoder().encode(myGroups) {
            UserDefaults.standard.set(data, forKey: groupsKey)
        }
    }

    private func saveChallenges() {
        let all = loadAllChallengesRaw()
        var updated = all.filter { challenge in
            !activeChallenges.contains(where: { $0.id == challenge.id })
        }
        updated.append(contentsOf: activeChallenges)
        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: challengesKey)
        }
    }

    private func loadAllChallenges() {
        activeChallenges = loadAllChallengesRaw()
    }

    private func loadAllChallengesRaw() -> [GroupChallenge] {
        guard let data = UserDefaults.standard.data(forKey: challengesKey),
              let decoded = try? JSONDecoder().decode([GroupChallenge].self, from: data)
        else { return [] }
        return decoded
    }

    // MARK: - Supabase Sync Stubs (future backend integration)

    func syncGroupsWithServer() async {
        // TODO: POST /study_groups — upsert myGroups to Supabase
    }

    func fetchGroupsFromServer() async {
        // TODO: GET /study_groups?user_id=... — replace myGroups from Supabase
    }

    func syncChallengesWithServer() async {
        // TODO: POST /group_challenges — upsert activeChallenges
    }
}
