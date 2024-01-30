//
//  ErrorModel.swift
//
//
//  Created by 강진석 on 1/29/24.
//

import Foundation

// SendBird API, SDK 내부 로직에 의한 에러를 통합하여, Client에 전달 될 에러 타입
enum SBError: Error {
    case apiError(code: Int, message: String)
    case responseParsingError
    case invalidParameters(message: String)
    case notSuccessful(message: String)
    case rateLimitExced
    
}
