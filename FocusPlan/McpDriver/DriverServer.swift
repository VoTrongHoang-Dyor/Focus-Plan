import Foundation
import Network
import UIKit
import XCTest

/// HTTP loopback (127.0.0.1) trong tiến trình XCUITest runner, thực thi lệnh JSON lên
/// XCUIApplication. Reachable từ host mac vì simulator dùng chung network stack.
final class DriverServer {
    private let port: UInt16
    private var listener: NWListener?
    private let app = XCUIApplication(bundleIdentifier: "com.votronghoang.focusplan")

    init(port: UInt16) { self.port = port }

    func start() throws {
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1",
                                                           port: NWEndpoint.Port(rawValue: port)!)
        let l = try NWListener(using: params)
        l.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        l.start(queue: DispatchQueue(label: "mcp.driver.listener"))
        listener = l
        NSLog("[MCPDriver] listening on 127.0.0.1:\(port)")
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: DispatchQueue(label: "mcp.driver.conn"))
        receiveRequest(conn, buffer: Data())
    }

    /// Đọc tới khi đủ headers + Content-Length body (HTTP/1.1 tối giản, mỗi connection 1 request).
    private func receiveRequest(_ conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { [weak self] data, _, isComplete, error in
            guard let self else { conn.cancel(); return }
            var buf = buffer
            if let data, !data.isEmpty { buf.append(data) }
            guard let sep = buf.range(of: Data("\r\n\r\n".utf8)) else {
                if error != nil || isComplete { conn.cancel(); return }
                self.receiveRequest(conn, buffer: buf); return
            }
            let headers = String(decoding: buf[buf.startIndex..<sep.lowerBound], as: UTF8.self)
            let contentLength = headers.split(separator: "\r\n")
                .first { $0.lowercased().hasPrefix("content-length:") }
                .flatMap { Int($0.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)) } ?? 0
            let bodyAvailable = buf.distance(from: sep.upperBound, to: buf.endIndex)
            if bodyAvailable < contentLength {
                if error != nil || isComplete { conn.cancel(); return }
                self.receiveRequest(conn, buffer: buf); return
            }
            let bodyEnd = buf.index(sep.upperBound, offsetBy: contentLength)
            let body = Data(buf[sep.upperBound..<bodyEnd])
            // XCUITest API phải chạy trên main thread của test runner.
            DispatchQueue.main.async {
                let responseJSON = self.dispatch(body: body)
                self.send(conn, json: responseJSON)
            }
        }
    }

    private func send(_ conn: NWConnection, json: Data) {
        var resp = Data("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(json.count)\r\nConnection: close\r\n\r\n".utf8)
        resp.append(json)
        conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
    }

    // MARK: - Command dispatch (chạy trên main thread)

    private func dispatch(body: Data) -> Data {
        guard let cmd = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let action = cmd["action"] as? String else {
            return encode(["ok": false, "error": "bad request: body must be JSON {action,...}"])
        }
        switch action {
        case "status":
            return encode(["ok": true, "state": "ready"])
        case "launch":
            if let env = cmd["env"] as? [String: String] {
                for (k, v) in env { app.launchEnvironment[k] = v }
            }
            app.launch()
            return encode(["ok": true])
        case "elements":
            let els = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier != ''"))
                .allElementsBoundByIndex.prefix(200)
                .map(describe)
            return encode(["ok": true, "elements": Array(els)])
        case "tap":
            guard let id = cmd["id"] as? String else { return encode(["ok": false, "error": "missing id"]) }
            let el = find(id)
            guard el.exists else { return encode(["ok": false, "error": "element not found: \(id)"]) }
            guard el.isHittable else { return encode(["ok": false, "error": "element not hittable: \(id)"]) }
            el.tap()
            return encode(["ok": true])
        case "tap_label": // CHỈ cho system dialog (vd "Để sau"). Không dùng cho control app.
            guard let label = cmd["label"] as? String else { return encode(["ok": false, "error": "missing label"]) }
            let btn = app.buttons[label].firstMatch
            guard btn.waitForExistence(timeout: 2) else { return encode(["ok": false, "error": "no button labeled: \(label)"]) }
            btn.tap()
            return encode(["ok": true])
        case "type":
            guard let id = cmd["id"] as? String, let text = cmd["text"] as? String else {
                return encode(["ok": false, "error": "missing id/text"])
            }
            let el = find(id)
            guard el.waitForExistence(timeout: 5) else { return encode(["ok": false, "error": "element not found: \(id)"]) }
            el.tap()
            if (cmd["paste"] as? Bool) == true {
                UIPasteboard.general.string = text
                el.press(forDuration: 1.3)
                let paste = app.menuItems["Paste"].firstMatch
                guard paste.waitForExistence(timeout: 5) else { return encode(["ok": false, "error": "paste menu not shown for: \(id)"]) }
                paste.tap()
            } else {
                el.typeText(text)
            }
            return encode(["ok": true])
        case "read":
            guard let id = cmd["id"] as? String else { return encode(["ok": false, "error": "missing id"]) }
            let el = find(id)
            guard el.exists else { return encode(["ok": false, "error": "element not found: \(id)"]) }
            return encode(["ok": true, "element": describe(el)])
        case "wait":
            guard let id = cmd["id"] as? String else { return encode(["ok": false, "error": "missing id"]) }
            let timeout = (cmd["timeout"] as? Double) ?? 10
            let el = find(id)
            return el.waitForExistence(timeout: timeout)
                ? encode(["ok": true, "element": describe(el)])
                : encode(["ok": false, "error": "timeout (\(Int(timeout))s) waiting for: \(id)"])
        default:
            return encode(["ok": false, "error": "unknown action: \(action)"])
        }
    }

    private func find(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func describe(_ el: XCUIElement) -> [String: Any] {
        [
            "identifier": el.identifier,
            "type": Self.typeName(el.elementType),
            "label": el.label,
            "value": String(describing: el.value ?? ""),
            "enabled": el.isEnabled,
            "hittable": el.isHittable,
        ]
    }

    private static func typeName(_ t: XCUIElement.ElementType) -> String {
        switch t {
        case .button: return "button"
        case .textField: return "textField"
        case .secureTextField: return "secureTextField"
        case .staticText: return "staticText"
        case .switch: return "switch"
        case .segmentedControl: return "segmentedControl"
        case .datePicker: return "datePicker"
        case .other: return "other"
        default: return "type#\(t.rawValue)"
        }
    }

    private func encode(_ obj: [String: Any]) -> Data {
        (try? JSONSerialization.data(withJSONObject: obj)) ?? Data("{\"ok\":false,\"error\":\"encode failure\"}".utf8)
    }
}
