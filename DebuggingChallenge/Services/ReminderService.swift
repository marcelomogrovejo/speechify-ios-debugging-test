/**
 # Task #2

 ## Task
 Fix the concurrency implementation in `DefaultReminderService` to correctly handle parallel reminder fetching using three different paradigms:

 1. Callback-Based (`fetchReminders`)
 2. Combine (`remindersPublisher`)
 3. Swift Concurrency (`fetchRemindersAsync`)

 Each implementation must:
 - Fetch three pages of reminders in parallel
 - Return a total of 12 reminders
 - Pass all associated tests in `DefaultReminderServiceTests`

 ## Success Criteria
 - All tests in `DefaultReminderServiceTests` pass successfully
 - Each method fetches exactly three pages concurrently
 - All methods return 12 unique reminders
 - Each implementation uses its designated concurrency paradigm
 - Each method has a unique implementation

 ## Important Notes
 - Some files are marked as "DO NOT MODIFY" - these must remain unchanged
 - In certain files, only specific sections are marked as protected with clear comments
 - Modifying any protected code (either entire files or marked sections) will result in automatic task failure
 - Work with the existing code structure; do not rewrite from scratch
 - Stay within each method's designated paradigm (Callbacks/Combine/Swift Concurrency)
 - Do not call other methods of the class within implementations
 */

import Combine
import Foundation

final class DefaultReminderService: ReminderService {
    private let dataSource: ReminderDataSource

    init(dataSource: ReminderDataSource) {
        self.dataSource = dataSource
    }

    // FIX: Callback-based parallel fetch.
    // BUG WAS: completion(reminders) was called right after the for loop,
    // before any async callbacks had fired. Result: always returned [].
    // FIX: Use a counter inside each callback. Only when the last callback fires
    // (completedCount == 3) do we call completion — guaranteeing all data is collected.
    // Debug tip: print() inside the callback to trace timing.
    func fetchReminders(completion: @escaping ([Reminder]) -> Void) {
        var reminders: [Reminder] = []
        var completedCount = 0

        for _ in 0 ..< 3 {
            dataSource.fetchReminders {
                reminders.append(contentsOf: $0)
                completedCount += 1
                if completedCount == 3 { completion(reminders) }
            }
        }
    }

    // FIX: Combine-based parallel fetch.
    // BUG WAS: promise(.success(reminders)) was called right after the forEach loop,
    // before any async callbacks had fired. Same timing bug as the callback method.
    // FIX: Same counter approach — promise is only resolved when all 3 callbacks complete.
    // A Future + promise is basically a callback wrapper: promise(.success(...)) = completion(...).
    // Debug tip: chain .print("label") or .handleEvents(receiveOutput:) to inspect emitted values.
    func remindersPublisher() -> AnyPublisher<[Reminder], Never> {
        var reminders: [Reminder] = []
        var completedCount = 0

        return Future { promise in
            (0..<3).forEach { _ in
                self.dataSource.fetchReminders { newReminders in
                    reminders.append(contentsOf: newReminders)
                    completedCount += 1
                    if completedCount == 3 { promise(.success(reminders)) }
                }
            }
        }
        .handleEvents(receiveOutput: { value in
            print("Publisher emitted: \(value)")
            print("Count: \(value.count)")
        })
        .print("DEBUG reminders")
        .eraseToAnyPublisher()
    }

    // FIX: async/await parallel fetch.
    // BUG WAS: Task {} blocks were fire-and-forget — the for loop launched them but
    // nobody awaited them. return reminders ran immediately with an empty array.
    // FIX: withTaskGroup runs tasks in parallel and `for await` waits for ALL of them
    // to finish before returning. group.addTask launches each fetch, for await collects results.
    // Debug tip: print() works anywhere here, reads top to bottom like normal code.
    func fetchRemindersAsync() async -> [Reminder] {
        let reminders = await withTaskGroup(of: [Reminder].self) { group in
            for _ in 0..<3 {
                group.addTask {
                    return await self.dataSource.fetchReminders()
                }
            }

            var collected: [Reminder] = []
            for await result in group {
                collected.append(contentsOf: result)
            }
            return collected
        }
        return reminders
    }

}
/*
 *****************************************************************************
 *                                                                           *
 *     >>>>>>>>>>>  DO NOT MODIFY ANYTHING FROM THIS POINT  <<<<<<<<<<<      *
 *                                                                           *
 *                YOU WILL AUTOMATICALLY FAIL IF YOU DO!                     *
 *                                                                           *
 *****************************************************************************
 */

protocol ReminderService: AnyObject {
    func fetchReminders(completion: @escaping ([Reminder]) -> Void)
    func remindersPublisher() -> AnyPublisher<[Reminder], Never>
    func fetchRemindersAsync() async -> [Reminder]
}

protocol ReminderDataSource: AnyObject {
    func fetchReminders(completion: @escaping ([Reminder]) -> Void)
    func fetchReminders() async -> [Reminder]
}
