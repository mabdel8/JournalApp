# Widget Setup Instructions

## App Group Configuration

To enable data sharing between the main app and the widget, you need to configure App Groups in Xcode:

### Step 1: Configure App Group for Main App Target

1. In Xcode, select your main app target (`Apptemplate`)
2. Go to **Signing & Capabilities** tab
3. Click the **+ Capability** button
4. Add **App Groups** capability
5. Click the **+** button under App Groups
6. Add app group: `group.com.yourcompany.journalapp`
   - **Note**: Replace `yourcompany` with your actual team identifier or choose a unique identifier

### Step 2: Configure App Group for Widget Target

1. Select your widget target (`calendarwidget`)
2. Go to **Signing & Capabilities** tab
3. Click the **+ Capability** button
4. Add **App Groups** capability
5. Click the **+** button under App Groups
6. Add the **same** app group: `group.com.yourcompany.journalapp`

### Step 3: Update App Group Identifier (if needed)

If you used a different app group identifier than `group.com.yourcompany.journalapp`, you need to update it in the code:

1. Open `SharedDataManager.swift`
2. Update line 12: 
   ```swift
   private let appGroupIdentifier = "group.com.yourcompany.journalapp"
   ```
   Replace with your actual app group identifier.

## Verification

The app will automatically verify the app group configuration when:
- A journal entry is saved (main app)
- The widget loads data (widget)

Check the Xcode console for messages like:
- ✅ App Group configuration verified
- ✅ Journal data synced to widget
- ❌ App Group 'group.com.yourcompany.journalapp' is not configured properly

## Troubleshooting

### Widget shows sample data instead of real data
- Verify both targets have the same app group configured
- Check that the app group identifier matches in both capabilities and code
- Ensure you've journaled at least one entry in the main app

### App group configuration errors
- Make sure your Apple Developer account supports App Groups
- Verify the app group identifier is unique and follows the format `group.domain.appname`
- Check that both targets are signed with the same team/certificate

### Widget not updating
- Widgets update on their own schedule, but you can force an update by:
  - Removing and re-adding the widget
  - Opening the main app (triggers data sync)
  - Waiting for the next automatic update (daily at midnight)

## Data Shared with Widget

The widget receives the following data from the main app:
- **Journal Dates**: Days of the current month with journal entries (green dots on calendar)
- **Total Entries**: Total number of journal entries across all time
- **Current Streak**: Number of consecutive days with journal entries
- **Monthly Entries**: Entry counts for different months (for historical data)

This data is automatically synced whenever:
- A journal entry is saved or updated
- The app launches and model context is available
- The widget requests fresh data