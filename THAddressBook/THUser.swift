//
//  User.swift
//  THAddressBook
//
//  Created by 希达 on 2017/12/27.
//  Copyright © 2017年 Tan.huang. All rights reserved.
//


/*
Swift标准库协议
    CustomDebugStringConvertible,CustomStringConvertible
        调试的时候，选择性的打印变量
    Equatable
        让两个Class，struct或者enum 具备比较是否相等的能力
 */
struct User: Equatable, CustomDebugStringConvertible {
    var name: String
    var iphone: String

    init(name: String, iphone: String) {
        self.name = name
        self.iphone = iphone
    }
}

extension User {
    var debugDescription: String {
        return name + " " + iphone
    }
}

func ==(lhs: User, rhs: User) -> Bool {
    return lhs.name == rhs.name &&
        lhs.iphone == rhs.iphone
}



