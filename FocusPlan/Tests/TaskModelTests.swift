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
         "deadline":"2026-07-03T13:00:00Z","needs_confirmation":false,"note":null,
         "task_type":"deep"}
        """
        let draft = try JSONDecoder().decode(ParsedTaskDraft.self, from: Data(jsonStr.utf8))
        XCTAssertEqual(draft.name, "Học tiếng Trung")
        XCTAssertEqual(draft.estimatedMinutes, 30)
        XCTAssertEqual(draft.priority, .medium)
        XCTAssertFalse(draft.needsConfirmation)
        XCTAssertNotNil(draft.deadlineDate)
        XCTAssertEqual(draft.taskType, .deep)
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

    func test_parsedDraft_defaults_taskType_shallow_when_absent() throws {
        let jsonStr = """
        {"name":"Đọc mail","estimated_minutes":15,"priority":"low",
         "deadline":null,"needs_confirmation":false,"note":null}
        """
        let draft = try JSONDecoder().decode(ParsedTaskDraft.self, from: Data(jsonStr.utf8))
        XCTAssertEqual(draft.taskType, .shallow)
    }

    func test_taskItem_decodes_taskType_and_defaults_when_absent() throws {
        let withType = """
        {"id":"11111111-1111-1111-1111-111111111111","name":"Viết báo cáo",
         "estimated_minutes":90,"priority":"high","deadline":null,
         "task_type":"deep","created_at":"2026-07-05T01:00:00Z"}
        """
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        let t1 = try d.decode(TaskItem.self, from: Data(withType.utf8))
        XCTAssertEqual(t1.taskType, .deep)

        let noType = """
        {"id":"22222222-2222-2222-2222-222222222222","name":"Cũ",
         "estimated_minutes":null,"priority":"medium","deadline":null,
         "created_at":"2026-07-05T01:00:00Z"}
        """
        let t2 = try d.decode(TaskItem.self, from: Data(noType.utf8))
        XCTAssertEqual(t2.taskType, .shallow)
    }
}
