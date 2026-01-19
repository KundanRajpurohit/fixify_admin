# Notification Debugging Guide

## Common Issues and Solutions

### 1. **Notifications Not Received**

#### Check the following:

**Android:**
1. ✅ Verify `google-services.json` exists in `android/app/`
2. ✅ Check AndroidManifest.xml has:
   - `POST_NOTIFICATIONS` permission (for Android 13+)
   - Firebase Messaging service configured
3. ✅ Ensure notification channel is created (check logs for "Android notification channel created")
4. ✅ Check if runtime permissions are granted (Android 13+):
   ```dart
   // The app should show a permission dialog automatically
   // Check logs for "Android Permission Granted: true/false"
   ```

**iOS:**
1. ✅ Verify `GoogleService-Info.plist` exists in `ios/Runner/`
2. ✅ Check Info.plist has `UIBackgroundModes` with `remote-notification`
3. ✅ Ensure AppDelegate.swift has FCM configuration
4. ✅ Check if notification permissions are granted:
   ```dart
   // Check logs for "iOS Permission Status: authorized"
   ```

#### Debug Steps:

1. **Check FCM Token:**
   ```dart
   final notificationService = NotificationService();
   await notificationService.printStatus(); // Print full status
   final token = await notificationService.getToken();
   print('FCM Token: $token');
   ```
   - Token should be non-null and have length > 100
   - If null, check Firebase initialization

2. **Check Logs on App Startup:**
   Look for these logs:
   ```
   ✅ Firebase initialized successfully
   ✅ Background message handler registered
   ✅ Notification service initialized successfully
   ✅ FCM Token retrieved: ...
   ✅ Android notification channel created (Android only)
   📱 [NotificationService] iOS Permission Status: authorized (iOS only)
   ```

3. **Send Test Notification from Firebase Console:**
   - Go to Firebase Console > Cloud Messaging
   - Send test message to your FCM token
   - Check logs for:
     - Foreground: "Foreground message received"
     - Background: "Background message received"
     - App closed: Notification should appear in system tray

### 2. **Notifications Received But Not Displayed**

**Foreground (App Open):**
- Check logs for "Foreground message received"
- Local notification should be shown automatically
- If not showing, check notification channel (Android) or permissions (iOS)

**Background (App Minimized):**
- Check logs for "Background message received"
- Notification should appear in system tray
- On Android, ensure notification channel importance is `HIGH`

**App Closed:**
- Notification should appear in system tray
- On tap, app should open and navigate based on payload

### 3. **Notification Tap Not Working**

Check navigation:
- `navigatorKey` must be set in `MaterialApp`
- Notification payload must have correct data structure:
  ```json
  {
    "type": "job",
    "job_token": "abc123",
    "job_id": "123"
  }
  ```
- Check logs for "Notification tapped" and navigation logs

### 4. **Token Not Generated**

1. Check Firebase initialization:
   - Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) exists
   - Check Firebase project has Cloud Messaging enabled
   
2. Check permissions:
   - Android 13+: Runtime permission must be granted
   - iOS: Must request and grant permissions

3. Check device:
   - Ensure device has internet connection
   - Check Google Play Services (Android) is up to date

## Testing Checklist

- [ ] Firebase initialized successfully
- [ ] FCM token retrieved and logged
- [ ] Notification permissions granted (check logs)
- [ ] Notification channel created (Android - check logs)
- [ ] Test notification from Firebase Console:
  - [ ] Foreground notification received
  - [ ] Background notification received
  - [ ] App closed notification received
- [ ] Notification tap navigation works

## Logs to Check

### On App Startup:
```
✅ Firebase initialized successfully
✅ Background message handler registered
✅ Notification service initialized successfully
📱 [NotificationService] FCM Token: ...
✅ [NotificationService] Android notification channel created (Android)
📱 [NotificationService] iOS Permission Status: authorized (iOS)
```

### When Notification Received (Foreground):
```
🔔 [NotificationService] Foreground message received
📝 [NotificationService] Title: ...
📝 [NotificationService] Body: ...
```

### When Notification Received (Background):
```
🔔 [Background] Background message received: ...
📝 [Background] Title: ...
📝 [Background] Body: ...
```

### When Notification Tapped:
```
👆 [NotificationService] Notification tapped
🧭 [NotificationService] Navigating from notification
```

## Common Errors

1. **"Background message handler not registered"**
   - Fix: Ensure `FirebaseMessaging.onBackgroundMessage()` is called BEFORE `Firebase.initializeApp()` in `main.dart`

2. **"Permission denied"**
   - Android 13+: User must grant runtime permission
   - iOS: User must allow notifications in Settings

3. **"Token is null"**
   - Check Firebase configuration files exist
   - Check internet connection
   - Check Google Play Services (Android)

4. **"Notifications not showing"**
   - Check notification channel importance (Android)
   - Check permissions are granted
   - Check if device has DND enabled

