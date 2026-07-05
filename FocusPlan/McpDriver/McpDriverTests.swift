import XCTest

/// KHÔNG phải test thường — đây là entry giữ DriverServer sống để MCP server điều khiển app.
/// Chỉ chạy khi TEST_RUNNER_MCP_DRIVER=1 (xcodebuild strip prefix → env MCP_DRIVER=1),
/// qua scheme FocusPlanMcpDriver. An toàn kép: nếu lọt suite khác sẽ skip.
final class McpDriverTests: XCTestCase {
    func test_runDriver() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["MCP_DRIVER"] == "1",
                          "MCP driver only (set TEST_RUNNER_MCP_DRIVER=1)")
        let port = UInt16(ProcessInfo.processInfo.environment["MCP_DRIVER_PORT"] ?? "") ?? 8931
        let server = DriverServer(port: port)
        try server.start()
        // Giữ test runner sống — main runloop phục vụ cả DispatchQueue.main (nơi chạy XCUITest).
        while true { RunLoop.current.run(mode: .default, before: .distantFuture) }
    }
}
