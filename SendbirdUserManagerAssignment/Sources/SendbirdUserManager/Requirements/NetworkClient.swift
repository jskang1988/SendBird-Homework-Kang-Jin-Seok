//
//  NetworkClient.swift
//  
//
//  Created by Sendbird
//

import Foundation
import Alamofire

// 서버 요청시 파라미터에 들어갈 키 값
enum ParamKeys: String {
    case userId = "user_id"
    case nickname = "nickname"
    case profileUrl = "profile_url"
    case limit = "limit"
}

// 서버 요청시 헤더에 들어갈 키 값
enum HeaderKeys: String {
    case contentType = "Content-Type"
    case apiToken = "Api-Token"
}

// Default 값 정의
enum DefaultValue: String {
    case baseUrl = "https://api-%@.sendbird.com/v3/users"
    case applicationJson = "application/json"
    case defaultProfileUrl = "https://sendbird.com/main/img/profiles/profile_05_512px.png"
}

public protocol Request {
    associatedtype Response: Decodable
    var baseUrl: String { get }
    var parameters: Parameters? { get }
    var headers: HTTPHeaders { get }
    var encoding: ParameterEncoding { get }
    var method: HTTPMethod { get }
}

// CreateUser에 대한 요청 명세
struct CreateUserRequest: Request {
    var baseUrl: String
    var parameters: Parameters?
    var headers: HTTPHeaders
    var encoding: ParameterEncoding
    var method: HTTPMethod
    var applicationId: String
    var apiToken: String
    public typealias Response = UserResponseModel
    
    init(applicationId: String, apiToken: String, params: UserCreationParams) {
        self.applicationId = applicationId
        self.apiToken = apiToken
        self.baseUrl = String(format: DefaultValue.baseUrl.rawValue, applicationId)
        self.parameters = [
            ParamKeys.userId.rawValue: params.userId,
            ParamKeys.nickname.rawValue: params.nickname
        ]
        self.parameters?[ParamKeys.profileUrl.rawValue] = params.profileURL ?? DefaultValue.defaultProfileUrl.rawValue
        self.headers = [
            HeaderKeys.contentType.rawValue : DefaultValue.applicationJson.rawValue,
            HeaderKeys.apiToken.rawValue: apiToken
        ]
        self.encoding = JSONEncoding.default
        self.method = .post
    }
    
}

// GetUser에 대한 요청 명세
struct GetUserRequest: Request {
    var baseUrl: String
    var parameters: Parameters?
    var headers: HTTPHeaders
    var encoding: ParameterEncoding
    var method: HTTPMethod
    var applicationId: String
    var apiToken: String
    public typealias Response = UserResponseModel
    
    init(applicationId: String, apiToken: String, userId: String) {
        self.applicationId = applicationId
        self.apiToken = apiToken
        self.baseUrl = String(format: DefaultValue.baseUrl.rawValue, applicationId) + "/\(userId)"
        self.headers = [
            HeaderKeys.contentType.rawValue : DefaultValue.applicationJson.rawValue,
            HeaderKeys.apiToken.rawValue: apiToken
        ]
        self.encoding = URLEncoding.default
        self.method = .get
    }
}

// GetUsers에 대한 요청 명세
struct GetUsersRequest: Request {
    var baseUrl: String
    var parameters: Parameters?
    var headers: HTTPHeaders
    var encoding: ParameterEncoding
    var method: HTTPMethod
    var applicationId: String
    var apiToken: String
    public typealias Response = UsersResponseModel
    
    init(applicationId: String, apiToken: String, nickName: String, limit: Int) {
        self.applicationId = applicationId
        self.apiToken = apiToken
        self.baseUrl = String(format: DefaultValue.baseUrl.rawValue, applicationId)
        self.parameters = [
            ParamKeys.nickname.rawValue: nickName,
            ParamKeys.limit.rawValue: limit
        ]
        self.headers = [
            HeaderKeys.contentType.rawValue : DefaultValue.applicationJson.rawValue,
            HeaderKeys.apiToken.rawValue: apiToken
        ]
        self.encoding = URLEncoding.default
        self.method = .get
    }
}

// UpdateUser에 대한 요청 명세
struct UpdateUserRequest: Request {
    var baseUrl: String
    var parameters: Parameters?
    var headers: HTTPHeaders
    var encoding: ParameterEncoding
    var method: HTTPMethod
    var applicationId: String
    var apiToken: String
    public typealias Response = UserResponseModel
    
    init(applicationId: String, apiToken: String, params: UserUpdateParams) {
        self.applicationId = applicationId
        self.apiToken = apiToken
        self.baseUrl = String(format: DefaultValue.baseUrl.rawValue, applicationId) + "/\(params.userId)"
        self.parameters = Parameters()
        if let nickname = params.nickname {
            parameters?[ParamKeys.nickname.rawValue] = nickname
        }
        if let profileURL = params.profileURL {
            parameters?[ParamKeys.profileUrl.rawValue] = profileURL
        }
        self.headers = [
            HeaderKeys.contentType.rawValue : DefaultValue.applicationJson.rawValue,
            HeaderKeys.apiToken.rawValue: apiToken
        ]
        self.encoding = JSONEncoding.default
        self.method = .put
    }
}

public protocol SBNetworkClient {
    init()
    
    /// 리퀘스트를 요청하고 리퀘스트에 대한 응답을 받아서 전달합니다
    func request<R: Request>(
        request: R,
        completionHandler: @escaping (Result<R.Response, Error>) -> Void
    )
}

public class NetworkClient: SBNetworkClient {
    // 마지막으로 서버에 요청했던 시간
    var lastDispatch: DispatchTime = DispatchTime(uptimeNanoseconds: 0)
    
    // rate limit 값 : 1이면 1초에 한번 요청 가능
    let dispatchDelaySecond = 1
    
    // rate limit 제한으로 인해 요청을 지연시킬때, 큐에 쌓일수 있는 최대 요청 수
    // 해당 값이 10이라면 현재 요청을 포함해 10개까지 대기 가능, 11번째 요청이 들어온다면 해당 요청은 실패처리
    let rateLimitMaxQueueCount = 10
    
    // rate limit으로 인해 지연 요청을 하기 위한 concurrent Queue
    let queue: DispatchQueue = DispatchQueue(label: "Rate Limit Management Queue", attributes: .concurrent)
    
    public func request<R>(request: R, completionHandler: @escaping (Result<R.Response, Error>) -> Void) where R : Request {
        
        // 요청 지연 큐의 한도를 넘은 경우 해당 요청을 rate limit으로 실패처리
        if lastDispatch > .now() + .seconds(dispatchDelaySecond * (rateLimitMaxQueueCount - 1)) {
            completionHandler(.failure(SBError.rateLimitExced))
            return
        }
        
        // 마지막으로 요청한 시간을 갱신
        lastDispatch = max(lastDispatch + .seconds(dispatchDelaySecond), .now())
        queue.asyncAfter(deadline: lastDispatch) { [weak self] in
            guard let self = self else { return }
            AF.request(request.baseUrl,
                       method: request.method,
                       parameters: request.parameters,
                       encoding: request.encoding,
                       headers: request.headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: R.Response.self, queue: self.queue, completionHandler: { [weak self] response in
                guard let _ = self else { return }
                switch response.result {
                case .success(let result):
                    completionHandler(.success(result))
                case .failure(let error):
                    print(error.localizedDescription)
                    if let data = response.data, let sendBirdError = try? JSONDecoder().decode(SBApiErrorModel.self, from: data) {
                        let sbError = SBError.apiError(code: sendBirdError.code, message: sendBirdError.message)
                        completionHandler(.failure(sbError))
                    }
                    else {
                        let sbError = SBError.responseParsingError
                        completionHandler(.failure(sbError))
                    }
                    
                }
            })
        }
    }
    
    required public init() {
        
    }
}
