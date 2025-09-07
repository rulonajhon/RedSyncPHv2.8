## Vivo V27e Android 15 Notification Troubleshooting Guide

### Common Vivo Android 15 Issues:
1. **iManager Battery Optimization** - Vivo's aggressive battery management
2. **Background App Restrictions** - Prevents app from running in background
3. **Autostart Management** - Blocks apps from starting automatically
4. **Notification Channel Restrictions** - Limits notification delivery
5. **Android 15 Full Screen Intent** - New permission required for lock screen notifications

### Manual Configuration Steps:

#### 1. Battery Optimization (Critical)
- Open **Settings** → **Battery** → **Background App Refresh**
- Find **RedSync PH** → Set to **Allow**
- Go to **Battery Optimization** → **All Apps** → **RedSync PH** → **Don't Optimize**

#### 2. iManager Configuration
- Open **iManager** app (pre-installed on Vivo)
- Go to **App Manager** → **Autostart Manager**
- Enable **RedSync PH** autostart
- Go to **Background App Refresh** → Enable **RedSync PH**

#### 3. Notification Settings
- **Settings** → **Apps & Notifications** → **RedSync PH**
- Enable **Show Notifications**
- Enable **Lock Screen Notifications**
- Enable **Override Do Not Disturb**
- Set **Importance** to **High**

#### 4. Android 15 Specific
- **Settings** → **Apps** → **Special App Access**
- **Full Screen Intent** → Enable for **RedSync PH**
- **Exact Alarm** → Enable for **RedSync PH**

#### 5. Developer Options (If Available)
- Enable **Developer Options**
- Disable **Background Activity Limits**
- Set **Background App Limit** to **Standard Limit**

### If Notifications Still Don't Work:
1. Restart the device after configuration
2. Test notifications immediately after configuration
3. Keep the app open for a few minutes after setup
4. Check if notifications work when device is unlocked first

### Vivo-Specific Settings to Check:
- **Smart Scene** → Disable power saving for RedSync PH
- **Ultra Game Mode** → Add RedSync PH to exceptions
- **Power Saving Mode** → Disable or whitelist RedSync PH
