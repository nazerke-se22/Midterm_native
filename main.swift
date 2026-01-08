import Foundation

// - Models

enum Priority: Int, CaseIterable, CustomStringConvertible {
    case low = 1
    case medium = 2
    case high = 3

    var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

enum Status: Int, CaseIterable, CustomStringConvertible {
    case todo = 1
    case inProgress = 2
    case done = 3

    var description: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        }
    }
}

struct Task: CustomStringConvertible {
    let id: UUID
    var title: String
    var taskDescription: String
    var priority: Priority
    var status: Status

    var description: String {
        """
        [\(id.uuidString.prefix(6))] \(title)
          Description: \(taskDescription)
          Priority: \(priority)
          Status: \(status)
        """
    }
}

// - Errors

enum TaskError: Error {
    case emptyTitle
    case invalidInput
    case taskNotFound
}

// MARK: - Protocol

protocol TaskManaging {
    func listTasks()
    func addTask(title: String, description: String, priority: Priority, status: Status) throws
    func updateTask(idPrefix: String, newTitle: String?, newDescription: String?, newPriority: Priority?, newStatus: Status?) throws
    func deleteTask(idPrefix: String) throws

    func filterTasks(using predicate: (Task) -> Bool) -> [Task]
    func sortTasks(using comparator: (Task, Task) -> Bool) -> [Task]
}

// MARK: - Manager

final class TaskManager: TaskManaging {

    private var tasks: [Task] = []

    func listTasks() {
        if tasks.isEmpty {
            print("No tasks available.\n")
            return
        }

        print("\nTask list:")
        for task in tasks {
            print(task)
            print("")
        }
    }

    func addTask(title: String, description: String, priority: Priority, status: Status) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw TaskError.emptyTitle
        }

        let task = Task(
            id: UUID(),
            title: trimmedTitle,
            taskDescription: description,
            priority: priority,
            status: status
        )

        tasks.append(task)
        print("Task added.\n")
    }

    func updateTask(idPrefix: String, newTitle: String?, newDescription: String?, newPriority: Priority?, newStatus: Status?) throws {
        guard let index = findTaskIndex(by: idPrefix) else {
            throw TaskError.taskNotFound
        }

        if let title = newTitle {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw TaskError.emptyTitle }
            tasks[index].title = trimmed
        }

        if let description = newDescription {
            tasks[index].taskDescription = description
        }

        if let priority = newPriority {
            tasks[index].priority = priority
        }

        if let status = newStatus {
            tasks[index].status = status
        }

        print("Task updated.\n")
    }

    func deleteTask(idPrefix: String) throws {
        guard let index = findTaskIndex(by: idPrefix) else {
            throw TaskError.taskNotFound
        }

        tasks.remove(at: index)
        print("Task deleted.\n")
    }

    func filterTasks(using predicate: (Task) -> Bool) -> [Task] {
        tasks.filter(predicate)
    }

    func sortTasks(using comparator: (Task, Task) -> Bool) -> [Task] {
        tasks.sorted(by: comparator)
    }

    private func findTaskIndex(by prefix: String) -> Int? {
        tasks.firstIndex {
            $0.id.uuidString.lowercased().hasPrefix(prefix.lowercased())
        }
    }
}

// MARK: - Console helpers

func readInput(_ text: String) -> String {
    print(text, terminator: "")
    return readLine() ?? ""
}

func choosePriority() throws -> Priority {
    print("Choose priority: 1) Low  2) Medium  3) High")
    guard let value = Int(readInput("> ")),
          let priority = Priority(rawValue: value) else {
        throw TaskError.invalidInput
    }
    return priority
}

func chooseStatus() throws -> Status {
    print("Choose status: 1) To Do  2) In Progress  3) Done")
    guard let value = Int(readInput("> ")),
          let status = Status(rawValue: value) else {
        throw TaskError.invalidInput
    }
    return status
}

// MARK: - App

let manager: TaskManaging = TaskManager()

while true {
    print("""
    ----------------------------
    Personal Task Tracker
    1) Add task
    2) List tasks
    3) Update task
    4) Delete task
    5) Filter by status
    6) Sort by priority
    0) Exit
    ----------------------------
    """)

    let choice = readInput("Select option: ")

    do {
        switch choice {
        case "1":
            let title = readInput("Title: ")
            let description = readInput("Description: ")
            let priority = try choosePriority()
            let status = try chooseStatus()
            try manager.addTask(title: title, description: description, priority: priority, status: status)

        case "2":
            manager.listTasks()

        case "3":
            manager.listTasks()
            let id = readInput("Enter task id prefix: ")
            let newTitle = readInput("New title (leave empty to skip): ")
            let titleValue = newTitle.isEmpty ? nil : newTitle

            let newDesc = readInput("New description (leave empty to skip): ")
            let descValue = newDesc.isEmpty ? nil : newDesc

            let priorityValue: Priority? = readInput("Change priority? (y/n): ").lowercased() == "y" ? try choosePriority() : nil
            let statusValue: Status? = readInput("Change status? (y/n): ").lowercased() == "y" ? try chooseStatus() : nil

            try manager.updateTask(
                idPrefix: id,
                newTitle: titleValue,
                newDescription: descValue,
                newPriority: priorityValue,
                newStatus: statusValue
            )

        case "4":
            manager.listTasks()
            let id = readInput("Enter task id prefix: ")
            try manager.deleteTask(idPrefix: id)

        case "5":
            let status = try chooseStatus()
            let filtered = manager.filterTasks { $0.status == status }
            filtered.forEach { print($0); print("") }

        case "6":
            let sorted = manager.sortTasks { $0.priority.rawValue > $1.priority.rawValue }
            sorted.forEach { print($0); print("") }

        case "0":
            exit(0)

        default:
            throw TaskError.invalidInput
        }
    } catch {
        print("An error occurred. Please try again.\n")
    }
}