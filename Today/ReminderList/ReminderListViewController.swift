//
//  ViewController.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/02.
//

import UIKit

class ReminderListViewController: UITableViewController {

    private var reminderListDataSource: ReminderListDataSource?
    static let showDetailSegueIdentifier = "ShowReminderDetailSegue"

    @IBAction func addButtonTriggered(_ sender: UIBarButtonItem) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showDetailSegueIdentifier,
           let destination = segue.destination as? ReminderDetailViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let rowIndex = indexPath.row
            guard let reminder = reminderListDataSource?.reminder(at: rowIndex) else {
                fatalError("Couldn't find data source for reminder list.")
            }
            destination.configure(with: reminder) { reminder in
                self.reminderListDataSource?.update(reminder, at: rowIndex)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        reminderListDataSource = ReminderListDataSource()
        tableView.dataSource = reminderListDataSource
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let navigationController = navigationController,
           navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(false, animated: animated)
        }
    }

}
