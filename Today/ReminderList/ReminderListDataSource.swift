//
//  ReminderListDataSource.swift
//  Today
//
//  Created by OsakaMiseri on 2021/07/04.
//

import UIKit
import EventKit

class ReminderListDataSource: NSObject {

    typealias ReminderCompletedAction = (Int) -> Void
    typealias ReminderDeletedAction = () -> Void
    typealias RemindersChangedAction = () -> Void

    enum Filter: Int {
        case today
        case future
        case all

        func shouldInclude(date: Date) -> Bool {
            let isInToday = Locale.current.calendar.isDateInToday(date)
            switch self {
            case .today:
                return isInToday
            case .future:
                return (date > Date()) && !isInToday
            case .all:
                return true
            }
        }
    }

    var filter: Filter = .today
    var filteredReminders: [Reminder] {
        return reminders.filter { filter.shouldInclude(date: $0.dueDate) }.sorted { $0.dueDate < $1.dueDate }
    }
    var percentComplete: Double {
        guard filteredReminders.count > 0 else {
            return 1
        }
        let numComplete: Double = filteredReminders.reduce(0) { $0 + ($1.isComplete ? 1 : 0) }
        // 完了したリマインダーの数をリマインダーの総数で割る
        return numComplete / Double(filteredReminders.count)
    }

    private let eventStore = EKEventStore()
    private var reminders: [Reminder] = []
    private var reminderCompletedAction: ReminderCompletedAction?
    private var reminderDeletedAction: ReminderDeletedAction?
    private var remindersChangeAction: RemindersChangedAction?

    init(reminderCompletedAction: @escaping ReminderCompletedAction, reminderDeletedAction: @escaping ReminderDeletedAction, remindersChangeAction: @escaping RemindersChangedAction) {
        self.reminderCompletedAction = reminderCompletedAction
        self.reminderDeletedAction = reminderDeletedAction
        self.remindersChangeAction = remindersChangeAction
        super.init()

        requestAccess { authorized in
            if authorized {
                self.readAllReminders()
                NotificationCenter.default.addObserver(self, selector: #selector(self.storeChanged(_:)), name: .EKEventStoreChanged, object: self.eventStore)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: self.eventStore)
    }

    @objc func storeChanged(_ notification: NSNotification) {
        requestAccess { authorized in
            if authorized {
                self.readAllReminders()
            }
        }
    }

    func update(_ reminder: Reminder, at row: Int, completion: (Bool) -> Void) {
        saveReminder(reminder) { success in
            if success {
                let index = self.index(for: row)
                reminders[index] = reminder
            }
            completion(success)
        }
    }

    func delete(at row: Int) {
        let index = self.index(for: row)
        reminders.remove(at: index)
    }

    func reminder(at row: Int) -> Reminder {
        return filteredReminders[row]
    }

    func add(_ reminder: Reminder) -> Int? {
        reminders.insert(reminder, at: 0)
        return filteredReminders.firstIndex(where: { $0.id == reminder.id})
    }

    func index(for filteredIndex: Int) -> Int {
        let filteredReminder = filteredReminders[filteredIndex]
        guard let index = reminders.firstIndex(where: { $0.id == filteredReminder.id }) else {
            fatalError("Couldn't retrieve index in source array")
        }
        return index
    }
}

extension ReminderListDataSource: UITableViewDataSource {
    static let reminderListCellIdentifier = "ReminderListCell"

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredReminders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.reminderListCellIdentifier, for: indexPath) as? ReminderListCell else {
            fatalError("Unable to dequeue ReminderCell")
        }
        let currentReminder = reminder(at: indexPath.row)
        let dateText = currentReminder.dueDateTimeText(for: filter)
        cell.configure(title: currentReminder.title, dateText: dateText, isDone: currentReminder.isComplete) {
            var modifiedReminder = currentReminder
            modifiedReminder.isComplete.toggle()
            self.update(modifiedReminder, at: indexPath.row) { success in
                if success {
                    self.reminderCompletedAction?(indexPath.row)
                }
            }
            self.reminderCompletedAction?(indexPath.row)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        delete(at: indexPath.row)
        tableView.performBatchUpdates({
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }) { (_) in
            tableView.reloadData()
        }
        reminderDeletedAction?()
    }
}

extension Reminder {
    static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter
    }()

    static let futureDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    static let todayDateFormatter: DateFormatter = {
        let format = NSLocalizedString("'Today at '%@", comment: "format string for dates occurring today")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = String(format: format, "hh:mm a")
        return dateFormatter
    }()

    func dueDateTimeText(for filter: ReminderListDataSource.Filter) -> String {
        let isInToday = Locale.current.calendar.isDateInToday(dueDate)
        switch filter {
        case .today:
            return Self.timeFormatter.string(from: dueDate)
        case .future:
            return Self.futureDateFormatter.string(from: dueDate)
        case .all:
            if isInToday {
                return Self.todayDateFormatter.string(from: dueDate)
            } else {
                return Self.futureDateFormatter.string(from: dueDate)
            }
        }
    }
}

extension ReminderListDataSource {
    // ユーザーがイベントへのアクセス許可をしたかどうかを取得
    private var isAvailable: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .authorized
    }

    private func requestAccess(completion: @escaping (Bool) -> Void) {
        let currentStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard currentStatus == .notDetermined else {
            completion(currentStatus == .authorized)
            return
        }
        eventStore.requestAccess(to: .reminder) { success, error in
            completion(success)
        }
    }

    // アプリがリマインダーにアクセスできない場合はメソッドを終了
    private func readAllReminders() {
        guard isAvailable else { return }
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { (ekReminders) in
            guard let ekReminders = ekReminders else {
                self.reminders = []
                return
            }
            self.reminders = ekReminders.compactMap {
                guard let dueDate = $0.alarms?.first?.absoluteDate else {
                    return nil
                }
                let reminder = Reminder(id: $0.calendarItemIdentifier,
                                        title: $0.title,
                                        dueDate: dueDate,
                                        notes: $0.notes,
                                        isComplete: $0.isCompleted)
                return reminder
            }
            self.remindersChangeAction?()
        }
    }

    private func saveReminder(_ reminder: Reminder, completion: (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }

        readReminder(with: reminder.id) { ekReminder in
            let ekReminder = ekReminder ?? EKReminder(eventStore: self.eventStore)
            ekReminder.title = reminder.title
            ekReminder.notes = reminder.notes
            ekReminder.isCompleted = reminder.isComplete
            ekReminder.calendar = self.eventStore.defaultCalendarForNewReminders()
            ekReminder.alarms?.forEach { alarm in
                if let absoluteDate = alarm.absoluteDate {
                    let comparsion = Locale.current.calendar.compare(reminder.dueDate, to: absoluteDate, toGranularity: .minute)
                    if comparsion != .orderedSame {
                        ekReminder.removeAlarm(alarm)
                    }
                }
            }
            if !ekReminder.hasAlarms {
                ekReminder.addAlarm(EKAlarm(absoluteDate: reminder.dueDate))
            }

            do {
                try self.eventStore.save(ekReminder, commit: true)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }

    private func readReminder(with id: String, completion: (EKReminder?) -> Void) {
        // リマインダーへのアクセス許可がない場合はreturn
        guard isAvailable else {
            completion(nil)
            return
        }

        guard let calenderItem = eventStore.calendarItem(withIdentifier: id),
              let ekReminder = calenderItem as? EKReminder else {
            completion(nil)
            return
        }
        completion(ekReminder)
    }
}
