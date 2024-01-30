//
//  UserManager.swift
//  
//
//  Created by Sendbird
//

import Foundation
import Alamofire

public typealias UserResult = Result<(SBUser), Error>
public typealias UsersResult = Result<[SBUser], Error>

/// Sendbird User Managent를 위한 SDK interface입니다.
public protocol SBUserManager {
    init()
    
    var networkClient: SBNetworkClient { get }
    var userStorage: SBUserStorage { get }
    
    /// Sendbird Application ID 및 API Token을 사용하여 SDK을 초기화합니다
    /// Init은 앱이 launching 될 때마다 불러야 합니다
    /// 만약 init의 sendbird application ID가 직전의 init에서 전달된 sendbird application ID와 다르다면 앱 내에 저장된 모든 데이터는 삭제되어야 합니다
    /// - Parameters:
    ///    - applicationId: Sendbird의 Application ID
    ///    - apiToken: 해당 Application에서 발급된 API Token
    func initApplication(applicationId: String, apiToken: String)
    
    /// UserCreationParams를 사용하여 새로운 유저를 생성합니다.
    /// Profile URL은 임의의 image URL을 사용하시면 됩니다
    /// 생성 요청이 성공한 뒤에 userStorage를 통해 캐시에 추가되어야 합니다
    /// - Parameters:
    ///    - params: User를 생성하기 위한 값들의 struct
    ///    - completionHandler: 생성이 완료된 뒤, user객체와 에러 여부를 담은 completion Handler
    func createUser(params: UserCreationParams, completionHandler: ((UserResult) -> Void)?)
    
    /// UserCreationParams List를 사용하여 새로운 유저들을 생성합니다.
    /// 한 번에 생성할 수 있는 사용자의 최대 수는 10명로 제한해야 합니다
    /// Profile URL은 임의의 image URL을 사용하시면 됩니다
    /// 생성 요청이 성공한 뒤에 userStorage를 통해 캐시에 추가되어야 합니다
    /// - Parameters:
    ///    - params: User를 생성하기 위한 값들의 struct
    ///    - completionHandler: 생성이 완료된 뒤, user객체와 에러 여부를 담은 completion Handler
    func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?)
    
    /// 특정 User의 nickname 또는 profileURL을 업데이트합니다
    /// 업데이트 요청이 성공한 뒤에 캐시에 upsert 되어야 합니다 
    func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?)
    
    /// userId를 통해 특정 User의 정보를 가져옵니다
    /// 캐시에 해당 User가 있으면 캐시된 User를 반환합니다
    /// 캐시에 해당 User가 없으면 /GET API 호출하고 캐시에 저장합니다
    func getUser(userId: String, completionHandler: ((UserResult) -> Void)?)
    
    /// Nickname을 필터로 사용하여 해당 nickname을 가진 User 목록을 가져옵니다
    /// GET API를 호출하고 캐시에 저장합니다
    /// Get users API를 활용할 때 limit은 10으로 고정합니다
    func getUsers(nicknameMatches: String, completionHandler: ((UsersResult) -> Void)?)
}

public class UserManager: SBUserManager {
    public var networkClient: SBNetworkClient
    public var userStorage: SBUserStorage
    
    private var applicationId: String
    private var apiToken: String
    
    public func initApplication(applicationId: String, apiToken: String) {
        /// applicationId가 다르다면 저장된 데이터 초기화
        if self.applicationId != applicationId {
            userStorage = UserStorage()
        }
        self.applicationId = applicationId
        self.apiToken = apiToken
    }
    
    public func createUser(params: UserCreationParams, completionHandler: ((UserResult) -> Void)?) {
        let request = CreateUserRequest(applicationId: self.applicationId,
                                                  apiToken: self.apiToken,
                                                  params: params)
        
        networkClient.request(request: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                let sbUser = SBUser(userId: user.userId,
                                    nickname: user.nickName,
                                    profileURL: user.profileUrl)
                self.userStorage.upsertUser(sbUser)
                completionHandler?(.success(sbUser))
            case .failure(let error):
                completionHandler?(.failure(error))
                break
            }
        }
        
    }
    
    public func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?) {
        let paramLimitNumber = 10
        // 요청된 추가유저 수가 10명 초과인 경우 에러 처리
        if params.count > paramLimitNumber {
            let sbError = SBError.invalidParameters(message: "The number of users to be created is limited to \(paramLimitNumber).")
            completionHandler?(.failure(sbError))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var results: [UserResult] = []
        
        for param in params {
            dispatchGroup.enter()
            self.createUser(params: param) { result in
                results.append(result)
                dispatchGroup.leave()
            }
        }
        
        // DispatchGroup을 이용하여 요청들이 모두 끝난 시점을 캐치하여 결과 처리
        dispatchGroup.notify(queue: .main) {
            var sbUsers: [SBUser] = []
            var successCount = 0
            for result in results {
                if let sbUser = try? result.get() {
                    successCount += 1
                    sbUsers.append(sbUser)
                }
            }
            if successCount == params.count {
                completionHandler?(.success(sbUsers))
            }
            else {
                // 부분성공 또는 실패한 경우, 에러 처리(성공/실패한 유저 수, userId목록을 안내)
                let userIdsParams = params.map({ $0.userId })
                let userIdsSuccess = sbUsers.map({ $0.userId })
                let failedUserIds = userIdsParams.filter({ !userIdsSuccess.contains($0) })
                let sbError = SBError.notSuccessful(message: "Number of users created is \(userIdsSuccess.count). Created user IDs: \(userIdsSuccess). Number of users failed is \(failedUserIds.count). Failed user IDs: \(failedUserIds).")
                completionHandler?(.failure(sbError))
                return
            }
        }

    }
    
    public func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?) {
        let request = UpdateUserRequest(applicationId: applicationId,
                                        apiToken: apiToken,
                                        params: params)
        
        networkClient.request(request: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let updatedUser):
                let sbUser = SBUser(userId: updatedUser.userId,
                                    nickname: updatedUser.nickName,
                                    profileURL: updatedUser.profileUrl)
                self.userStorage.upsertUser(sbUser)
                completionHandler?(.success(sbUser))
            case .failure(let error):
                completionHandler?(.failure(error))
                break
            }
        }
    }
    
    public func getUser(userId: String, completionHandler: ((UserResult) -> Void)?) {
        // 이미 캐싱되어 있는경우 바로 반환
        if let user = userStorage.getUser(for: userId) {
            completionHandler?(.success(user))
        }
        let request = GetUserRequest(applicationId: applicationId,
                                     apiToken: apiToken,
                                     userId: userId)
        networkClient.request(request: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let createdUser):
                let sbUser = SBUser(userId: createdUser.userId,
                                    nickname: createdUser.nickName,
                                    profileURL: createdUser.profileUrl)
                self.userStorage.upsertUser(sbUser)
                completionHandler?(.success(sbUser))
            case .failure(let error):
                completionHandler?(.failure(error))
                break
            }
        }
    }
    
    public func getUsers(nicknameMatches: String, completionHandler: ((UsersResult) -> Void)?) {
        // 닉네임이 빈 스트링이면 에러 처리
        if nicknameMatches.isEmpty {
            let sbError = SBError.invalidParameters(message: "nicknameMatches can't be empty strings")
            completionHandler?(.failure(sbError))
            return
        }
        let request = GetUsersRequest(applicationId: applicationId,
                                      apiToken: apiToken,
                                      nickName: nicknameMatches,
                                      limit: 100)
        
        networkClient.request(request: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let createdUsers):
                var sbUsers: [SBUser] = []
                for user in createdUsers.users {
                    let sbUser = SBUser(userId: user.userId,
                                        nickname: user.nickName,
                                        profileURL: user.profileUrl)
                    sbUsers.append(sbUser)
                    self.userStorage.upsertUser(sbUser)
                }
                completionHandler?(.success(sbUsers))
            case .failure(let error):
                completionHandler?(.failure(error))
                break
            }
        }
        
    }
    
    required public init() {
        self.networkClient = NetworkClient()
        self.userStorage =  UserStorage()
        self.applicationId = ""
        self.apiToken = ""
    }
}
