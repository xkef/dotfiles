# Notification for LaunchDaemons

We need:

- launchctl config: `rsync_bak_notification.plist`
- daemon script: `rsync_bak_notification.sh`
- osa script turned to .app for changing icon

**path in .plist needs to point to the .sh file**

Copy .plist then activate

```sh
launchctl load -w /Library/LaunchDaemons/your-label.plist
```
encrypt with or create ne container (apfs encrypted) fdesetup
