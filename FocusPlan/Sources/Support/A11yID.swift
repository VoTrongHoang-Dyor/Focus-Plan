import Foundation

/// Accessibility identifiers tập trung — nguồn sự thật duy nhất, không magic string trong view.
/// Convention: "{screen}.{element}-{type}" (lowercase, kebab-case); hàng động: "{screen}.row.{uuid}".
/// Chi tiết: FocusPlan/docs/accessibility-identifiers.md
enum A11yID {
    enum SignIn {
        static let emailField = "signin.email-field"
        static let passwordField = "signin.password-field"
        static let submitButton = "signin.submit-button"
        static let goToSignUpButton = "signin.go-to-signup-button"
        static let errorText = "signin.error-text"
    }

    enum SignUp {
        static let emailField = "signup.email-field"
        static let passwordField = "signup.password-field"
        static let confirmPasswordField = "signup.confirm-password-field"
        static let submitButton = "signup.submit-button"
        static let goToSignInButton = "signup.go-to-signin-button"
        static let errorText = "signup.error-text"
        static let infoText = "signup.info-text"
    }

    enum Home {
        static let greetingText = "home.greeting-text"
        static let signOutButton = "home.sign-out-button"
        static let alarmButton = "home.alarm-button"
    }

    enum AlarmForm {
        static let timeText = "alarmform.time-text"
        static let timePicker = "alarmform.time-picker"
        /// weekday chuẩn Calendar: 1=CN … 7=T7.
        static func dayToggle(_ weekday: Int) -> String { "alarmform.day-toggle-\(weekday)" }
        static let loopAudioToggle = "alarmform.loop-audio-toggle"
        static let vibrateToggle = "alarmform.vibrate-toggle"
        static let volumeMaxToggle = "alarmform.volume-max-toggle"
        static let showNotificationToggle = "alarmform.show-notification-toggle"
        static let createButton = "alarmform.create-button"
        static let cancelButton = "alarmform.cancel-button"
        static let hintText = "alarmform.hint-text"
    }

    enum TaskList {
        static let addButton = "tasklist.add-button"
        static let emptyState = "tasklist.empty-state"
        static func row(_ id: UUID) -> String { "tasklist.row.\(id.uuidString)" }
    }

    enum AddTask {
        static let inputField = "addtask.input-field"
        static let parseButton = "addtask.parse-button"
        static let cancelButton = "addtask.cancel-button"
        static let errorText = "addtask.error-text"
    }

    enum TaskForm {
        static let nameField = "taskform.name-field"
        static let minutesField = "taskform.minutes-field"
        static let priorityPicker = "taskform.priority-picker"
        static let taskTypePicker = "taskform.tasktype-picker"
        static let deadlineToggle = "taskform.deadline-toggle"
        static let deadlinePicker = "taskform.deadline-picker"
        static let noteText = "taskform.note-text"
        static let errorText = "taskform.error-text"
        static let saveButton = "taskform.save-button"
        static let cancelButton = "taskform.cancel-button"
    }
}
