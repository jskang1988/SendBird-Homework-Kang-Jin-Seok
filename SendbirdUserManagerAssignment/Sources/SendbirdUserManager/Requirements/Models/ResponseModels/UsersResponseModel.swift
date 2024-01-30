//
//  GetUsersResponseModel.swift
//
//
//  Created by 강진석 on 1/29/24.
//

import Foundation

// 유저 목록에 대한 응답을 파싱하기 위한 모델
struct UsersResponseModel: Decodable {
    
    let users: [UserResponseModel]
    
    enum CodingKeys: String, CodingKey {
        case users
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        users = (try? values.decode([UserResponseModel].self, forKey: .users)) ?? []
    }
}
