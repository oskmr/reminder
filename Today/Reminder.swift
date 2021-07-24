//
//  Reminder.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/02.
//

import Foundation

struct Reminder {
    var id: String
    var title: String
    var dueDate: Date
    var notes: String? = nil
    var isComplete: Bool = false
}
