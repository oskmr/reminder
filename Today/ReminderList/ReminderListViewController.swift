//
//  ViewController.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/02.
//

import UIKit

class ReminderListViewController: UITableViewController {

    static let showDetailSegueIdentifier = "ShowReminderDetailSegue"
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showDetailSegueIdentifier,
           let destination = segue.destination as? ReminderDetailViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let reminder = Reminder.testData[indexPath.row]
            destination.configure(with: reminder)
        }
    }

}
