//
//  EditDateCell.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/04.
//

import UIKit

class EditDateCell: UITableViewCell {

    typealias DateChangeAction = (Date) -> Void

    @IBOutlet private weak var datePicker: UIDatePicker!

    private var dateChangeAction: DateChangeAction?

    override func awakeFromNib() {
        super.awakeFromNib()

        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }

    func configure(date: Date, changeAction: @escaping DateChangeAction) {
        datePicker.date = date
        self.dateChangeAction = changeAction
    }

    @objc func dateChanged(_ sender: UIDatePicker) {
        dateChangeAction?(sender.date)
    }

}
