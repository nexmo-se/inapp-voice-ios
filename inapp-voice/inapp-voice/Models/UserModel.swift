//
//  User.swift
//  inapp-voice
//
//  Created by iujie on 20/04/2023.
//

import Foundation

struct UserModel: Decodable {
    let username: String
    let token: String
    let region: String
    let dc: String
    let ws: String
}
