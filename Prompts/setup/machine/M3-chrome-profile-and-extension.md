# M3 — Chrome profile and UiPath extension

The robot opens Oracle Fusion in Chrome (S0_SignIn). The supplier questionnaire upload needs the UiPath
extension's **Allow access to file URLs** in the profile Chrome opens. S0 picks the profile from:

1. the S0 argument `in_ChromeProfile`, if a caller passes one, else
2. the per-machine environment variable `UIP_CHROME_PROFILE` (e.g. `Profile 4`), else
3. Chrome's last-used profile.

**You do:**

1. In Chrome, open the profile you want the robot to use. In `chrome://extensions` → UiPath → Details,
   turn on **Allow access to file URLs** (and make sure the extension is enabled).
2. In that profile open `chrome://version` and note the last folder of **Profile Path**
   (`Default`, `Profile 1`, `Profile 4`, …). That folder name is `<CHROME_PROFILE>`.

**Then paste this prompt:**

```text
Set up Chrome for the OracleFusion_AgenticTesting robot on this machine.

1. List the Chrome profiles under %LOCALAPPDATA%\Google\Chrome\User Data (folder name and the profile's
   display name from its Preferences file) and show which have the UiPath extension installed. Read-only.
2. I will use profile "<CHROME_PROFILE>". Before changing anything, tell me the exact command, then — once I
   say yes — set the user environment variable UIP_CHROME_PROFILE to that value
   (`[Environment]::SetEnvironmentVariable("UIP_CHROME_PROFILE", "<CHROME_PROFILE>", "User")`).
3. Remind me that UiPath Assistant/Robot and Studio must be restarted (or I sign out and in) to see the new
   variable, and that unattended jobs on this machine run as my Windows user, so the user-level variable
   applies to them too.
Do not open or drive Chrome yourself.
```

**Done when:** `UIP_CHROME_PROFILE` is set, the extension has file access in that profile, and the
Robot/Studio were restarted.
