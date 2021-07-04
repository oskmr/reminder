//
//  EditDateCell.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/04.
//

import UIKit

class EditDateCell: UITableViewCell {

    @IBOutlet private weak var datePicker: UIDatePicker!

    func configure(date: Date) {
        datePicker.date = date
    }
}
