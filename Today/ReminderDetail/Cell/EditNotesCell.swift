//
//  EditNotesCell.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/04.
//

import UIKit

class EditNotesCell: UITableViewCell {

    @IBOutlet private weak var notesTextView: UITextView!

    func configure(notes: String?) {
        notesTextView.text = notes
    }
}
