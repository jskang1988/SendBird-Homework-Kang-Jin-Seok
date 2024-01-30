//
//  GetUserResponseModel.swift
//  
//
//  Created by 강진석 on 1/28/24.
//

import Foundation

// 유저에 대한 응답을 파싱하기 위한 모델
struct UserResponseModel: Decodable {
    
    let userId: String
    let nickName: String
    let profileUrl: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickName = "nickname"
        case profileUrl = "profile_url"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        userId = (try? values.decode(String.self, forKey: .userId)) ?? ""
        nickName = (try? values.decode(String.self, forKey: .nickName)) ?? ""
        profileUrl = (try? values.decode(String.self, forKey: .profileUrl)) ?? ""
    }
}
