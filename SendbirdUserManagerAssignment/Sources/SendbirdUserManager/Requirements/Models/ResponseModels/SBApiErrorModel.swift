//
//  SBApiErrorModel.swift
//  
//
//  Created by 강진석 on 1/28/24.
//

import Foundation

// SendBird API Error를 파싱하기 위한 모델
struct SBApiErrorModel: Decodable, Error {
    
    let message: String
    let code: Int
    
    enum CodingKeys: String, CodingKey {
        case message
        case code
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        message = (try? values.decode(String.self, forKey: .message)) ?? ""
        code = (try? values.decode(Int.self, forKey: .code)) ?? 0
    }
}
