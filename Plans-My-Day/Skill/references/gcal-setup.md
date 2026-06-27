# Guide to configuring Google OAuth for the Artifact

## Why do you need a Client ID?

The Google Calendar API requires an application to be registered to receive access. The Client ID is the identifier of that application — in this case, the React Artifact running inside Claude.

---

## Configuration steps (5–10 minutes, one time)

### 1. Create a Google Cloud Project
- Go to [console.cloud.google.com](https://console.cloud.google.com)
- Click "New Project" → name it (e.g. "plan-my-day")
- Wait for the project to be created

### 2. Enable the Google Calendar API
- From the menu → "APIs & Services" → "Library"
- Search "Google Calendar API" → click "Enable"

### 3. Create OAuth 2.0 Credentials
- "APIs & Services" → "Credentials" → "Create Credentials" → "OAuth client ID"
- Application type: **Web application**
- Name: "Plan My Day Artifact"
- Authorized JavaScript origins: add `https://claude.ai`
- Click "Create"

### 4. Get the Client ID
- Copy the string in the form: `123456789-abcdef.apps.googleusercontent.com`
- Paste it into the `GOOGLE_CLIENT_ID` field in the Artifact

### 5. OAuth Consent Screen (if prompted)
- User type: **External**
- App name: "Plan My Day"
- Support email: your email
- Scopes: add `https://www.googleapis.com/auth/calendar.events`
- Test users: add your Google email

---

## Common troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `redirect_uri_mismatch` | Origin not added | Add `https://claude.ai` to Authorized origins |
| `access_denied` | Test user not added | Add your email to the OAuth consent screen |
| `invalid_client` | Wrong Client ID | Re-copy it from the Google Cloud Console |
| Events not showing | Wrong timezone | Make sure you use `Asia/Ho_Chi_Minh` |

---

## Alternative: Use .ics (no configuration needed)

If you don't want to configure OAuth, the Artifact has a "Download .ics" button to export a file and import it into Google Calendar:
- Open Google Calendar → Settings (⚙️) → "Import & export" → "Import"
- Choose the downloaded .ics file

This way needs no Client ID but requires manual import every day.
