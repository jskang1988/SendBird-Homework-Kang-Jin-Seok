//
//  UserManagerBaseTests.swift
//  SendbirdUserManager
//
//  Created by Sendbird
//

import Foundation
import XCTest
import SendbirdUserManager


/// Unit Testing을 위해 제공되는 base test suite입니다.
/// 사용을 위해서는 해당 클래스를 상속받고,
/// `open func userManagerType() -> SBUserManager.Type!`를 override한뒤, 본인이 구현한 SBUserManager의 타입을 반환하도록 합니다.
open class UserManagerBaseTests: XCTestCase {
    open func userManagerType() -> SBUserManager.Type! {
        return UserManager.self
    }
    
    public let applicationId = "EC7CA74C-26A3-497F-8AE7-858AE881772A"
    public let apiToken = "4eaaa845794198f2b2684218f15a2c3f52bdc823"
    
    public func testInitApplicationWithDifferentAppIdClearsData() {
        let userManager = userManagerType().init()
        
        // First init
        userManager.initApplication(applicationId: "AppID1", apiToken: "Token1")    // Note: Add the first application ID and API Token
        
        let userId = UUID().uuidString
        let initialUser = UserCreationParams(userId: userId, nickname: "hello", profileURL: nil)
        userManager.createUser(params: initialUser) { _ in }
        
        // Check if the data exist
        let users = userManager.userStorage.getUsers()
        XCTAssertEqual(users.count, 0, "The number of cached users should be zero at the present time as it must be cached after successful server requests")
        
        // Second init with a different App ID
        userManager.initApplication(applicationId: "AppID2", apiToken: "Token2")    // Note: Add the second application ID and API Token
        
        // Check if the data is cleared
        let clearedUsers = userManager.userStorage.getUsers()
        XCTAssertEqual(clearedUsers.count, 0, "Data should be cleared after initializing with a different Application ID")
    }
    
    public func testCreateUser() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)
        
        let userId = UUID().uuidString
        let userNickname = UUID().uuidString
        let params = UserCreationParams(userId: userId, nickname: userNickname, profileURL: nil)
        let expectation = self.expectation(description: "Wait for user creation")
        
        userManager.createUser(params: params) { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertEqual(user.nickname, userNickname)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testCreateUsers() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId1 = UUID().uuidString
        let userNickname1 = UUID().uuidString
        
        let userId2 = UUID().uuidString
        let userNickname2 = UUID().uuidString
        
        let params1 = UserCreationParams(userId: userId1, nickname: userNickname1, profileURL: nil)
        let params2 = UserCreationParams(userId: userId2, nickname: userNickname2, profileURL: nil)
        
        let expectation = self.expectation(description: "Wait for users creation")
    
        userManager.createUsers(params: [params1, params2]) { result in
            switch result {
            case .success(let users):
                XCTAssertEqual(users.count, 2)
                XCTAssertEqual(users[0].nickname, userNickname1)
                XCTAssertEqual(users[1].nickname, userNickname2)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testUpdateUser() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId = UUID().uuidString
        let initialUserNickname = UUID().uuidString
        let updatedUserNickname = UUID().uuidString
        
        let initialParams = UserCreationParams(userId: userId, nickname: initialUserNickname, profileURL: nil)
        let updatedParams = UserUpdateParams(userId: userId, nickname: updatedUserNickname, profileURL: nil)
        
        let expectation = self.expectation(description: "Wait for user update")
        
        userManager.createUser(params: initialParams) { creationResult in
            switch creationResult {
            case .success(_):
                userManager.updateUser(params: updatedParams) { updateResult in
                    switch updateResult {
                    case .success(let updatedUser):
                        XCTAssertEqual(updatedUser.nickname, updatedUserNickname)
                    case .failure(let error):
                        XCTFail("Failed with error: \(error)")
                    }
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testGetUser() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId = UUID().uuidString
        let userNickname = UUID().uuidString
        
        let params = UserCreationParams(userId: userId, nickname: userNickname, profileURL: nil)
        
        let expectation = self.expectation(description: "Wait for user retrieval")
        
        userManager.createUser(params: params) { creationResult in
            switch creationResult {
            case .success(let createdUser):
                userManager.getUser(userId: createdUser.userId) { getResult in
                    switch getResult {
                    case .success(let retrievedUser):
                        XCTAssertEqual(retrievedUser.nickname, userNickname)
                    case .failure(let error):
                        XCTFail("Failed with error: \(error)")
                    }
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testGetUsersWithNicknameFilter() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId1 = UUID().uuidString
        let userNickname1 = UUID().uuidString
        
        let userId2 = UUID().uuidString
        let userNickname2 = UUID().uuidString
        
        let params1 = UserCreationParams(userId: userId1, nickname: userNickname1, profileURL: nil)
        let params2 = UserCreationParams(userId: userId2, nickname: userNickname2, profileURL: nil)
        
        let expectation = self.expectation(description: "Wait for users retrieval with nickname filter")
        
        userManager.createUsers(params: [params1, params2]) { creationResult in
            switch creationResult {
            case .success(_):
                userManager.getUsers(nicknameMatches: userNickname1) { getResult in
                    switch getResult {
                    case .success(let users):
                        XCTAssertEqual(users.count, 1)
                        XCTAssertEqual(users[0].nickname, userNickname1)
                    case .failure(let error):
                        XCTFail("Failed with error: \(error)")
                    }
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // Test that trying to create more than 10 users at once should fail
    public func testCreateUsersLimit() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let users = (0..<11).map { UserCreationParams(userId: "user_id_\(UUID().uuidString)\($0)", nickname: "nickname_\(UUID().uuidString)\($0)", profileURL: nil) }
        
        let expectation = self.expectation(description: "Wait for users creation with limit")
        
        userManager.createUsers(params: users) { result in
            switch result {
            case .success(_):
                XCTFail("Shouldn't successfully create more than 10 users at once")
            case .failure(let error):
                // Ideally, check for a specific error related to the limit
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // Test race condition when simultaneously trying to update and fetch a user
    public func testUpdateUserRaceCondition() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId = UUID().uuidString
        let initialUserNickname = UUID().uuidString
        let updatedUserNickname = UUID().uuidString
        
        let initialParams = UserCreationParams(userId: userId, nickname: initialUserNickname, profileURL: nil)
        let updatedParams = UserUpdateParams(userId: userId, nickname: updatedUserNickname, profileURL: nil)
        
        let expectation1 = self.expectation(description: "Wait for user update")
        let expectation2 = self.expectation(description: "Wait for user retrieval")
        
        userManager.createUser(params: initialParams) { creationResult in
            guard let createdUser = try? creationResult.get() else {
                XCTFail("Failed to create user")
                return
            }
            
            DispatchQueue.global().async {
                userManager.updateUser(params: updatedParams) { _ in
                    expectation1.fulfill()
                }
            }
            
            DispatchQueue.global().async {
                userManager.getUser(userId: createdUser.userId) { getResult in
                    if case .success(let user) = getResult {
                        XCTAssertTrue(user.nickname == initialUserNickname || user.nickname == updatedUserNickname)
                    } else {
                        XCTFail("Failed to retrieve user")
                    }
                    expectation2.fulfill()
                }
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }
    
    // Test for edge cases where the nickname to be matched is either empty or consists of spaces
    public func testGetUsersWithEmptyNickname() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let expectation = self.expectation(description: "Wait for users retrieval with empty nickname filter")
        
        userManager.getUsers(nicknameMatches: "") { result in
            if case .failure(let error) = result {
                // Ideally, check for a specific error related to the invalid nickname
                XCTAssertNotNil(error)
            } else {
                XCTFail("Fetching users with empty nickname should not succeed")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    public func testRateLimitCreateUser() {
        let userManager = userManagerType().init()
        userManager.initApplication(applicationId: applicationId, apiToken: apiToken)
        
        // Concurrently create 11 users
        let dispatchGroup = DispatchGroup()
        var results: [UserResult] = []
        
        for _ in 0..<11 {
            dispatchGroup.enter()
            let params = UserCreationParams(userId: UUID().uuidString, nickname: UUID().uuidString, profileURL: nil)
            userManager.createUser(params: params) { result in
                results.append(result)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.wait()
        
        // Assess the results
        let successResults = results.filter {
            if case .success = $0 { return true }
            return false
        }
        let rateLimitResults = results.filter {
            if case .failure(_) = $0 { return true }
            return false
        }

        XCTAssertEqual(successResults.count, 10)
        XCTAssertEqual(rateLimitResults.count, 1)
    }
}
