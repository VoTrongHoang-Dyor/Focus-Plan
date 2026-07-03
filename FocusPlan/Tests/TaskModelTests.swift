import XCTest
@testable import FocusPlan

final class TaskModelTests: XCTestCase {
    func test_priority_labels_vietnamese() {
        XCTAssertEqual(TaskPriority.low.label, "Thấp")
        XCTAssertEqual(TaskPriority.medium.label, "Trung bình")
        XCTAssertEqual(TaskPriority.high.label, "Cao")
    }

    func test_parsedDraft_decodes_from_gemini_json() throws {
        let jsonStr = """
        {"name":"Học tiếng Trung","estimated_minutes":30,"priority":"medium",
         "deadline":"2026-07-03T13:00:00Z","needs_confirmation":false,"note":null}
        """
        let draft = try JSONDecoder().decode(ParsedTaskDraft.self, from: Data(jsonStr.utf8))
        XCTAssertEqual(draft.name, "Học tiếng Trung")
        XCTAssertEqual(draft.estimatedMinutes, 30)
        XCTAssertEqual(draft.priority, .medium)
        XCTAssertFalse(draft.needsConfirmation)
        XCTAssertNotNil(draft.deadlineDate)
    }

    func test_parsedDraft_handles_null_deadline_and_minutes() throws {
        let jsonStr = """
        {"name":"Gọi mẹ","estimated_minutes":null,"priority":"high",
         "deadline":null,"needs_confirmation":true,"note":"không rõ thời lượng"}
        """
        let draft = try JSONDecoder().decode(ParsedTaskDraft.self, from: Data(jsonStr.utf8))
        XCTAssertNil(draft.estimatedMinutes)
        XCTAssertNil(draft.deadlineDate)
        XCTAssertTrue(draft.needsConfirmation)
    }
}
