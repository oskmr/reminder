//
//  ReminderDetailViewController.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/02.
//

import UIKit

class ReminderDetailViewController: UITableViewController {

    var reminder: Reminder?

    func configure(with reminder: Reminder) {
        self.reminder = reminder
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
