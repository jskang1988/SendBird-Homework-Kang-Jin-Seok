//
//  UserStorage.swift
//  
//
//  Created by Sendbird
//

import Foundation

/// Sendbird User 를 관리하기 위한 storage class입니다
public protocol SBUserStorage {
    init()
    
    /// 해당 User를 저장 또는 업데이트합니다
    func upsertUser(_ user: SBUser)
    
    /// 현재 저장되어있는 모든 유저를 반환합니다
    func getUsers() -> [SBUser]
    /// 현재 저장되어있는 유저 중 nickname을 가진 유저들을 반환합니다
    func getUsers(for nickname: String) -> [SBUser]
    /// 현재 저장되어있는 유저들 중에 지정된 userId를 가진 유저를 반환합니다.
    func getUser(for userId: String) -> (SBUser)?
}

public class UserStorage: SBUserStorage {
    private var users: [SBUser] = []
    
    // UserStorage를 Thread Safe으로 만들기 위한 queue
    private let queue = DispatchQueue(label: "Thread Safe User Store", attributes: .concurrent)
    
    required public init() {
        
    }
    
    public func upsertUser(_ user: SBUser) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if let index = self.users.firstIndex(where: { $0.userId == user.userId }) {
                self.users[index] = user
            } else {
                self.users.append(user)
            }
        }
    }
    
    public func getUsers() -> [SBUser] {
        queue.sync { [weak self] in
            guard let self = self else { return [] }
            return self.users
        }
    }
    
    public func getUsers(for nickname: String) -> [SBUser] {
        queue.sync { [weak self] in
            guard let self = self else { return [] }
            return self.users.filter({ $0.nickname == nickname })
        }
    }
    
    public func getUser(for userId: String) -> (SBUser)? {
        queue.sync { [weak self] in
            guard let self = self else { return nil }
            return users.filter({ $0.userId == userId }).first
        }
    }
}
