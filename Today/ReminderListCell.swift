//
//  ReminderListCell.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/02.
//

import UIKit

class ReminderListCell: UITableViewCell {

    typealias DoneButtonAction = () -> Void
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!

    var doneButtonAction: DoneButtonAction?

    @IBAction func doneButtonTriggered(_ sender: UIButton) {
        doneButtonAction?()
    }
}
