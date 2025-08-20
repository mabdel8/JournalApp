# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS app template built with SwiftUI that implements in-app purchases with StoreKit 2. The app features an onboarding flow, subscription paywall, and premium/free account states.

## Architecture

### Core Structure
- **Main App Entry**: `ApptemplateApp.swift` - Manages app lifecycle, onboarding state, and paywall presentation
- **State Management**: Uses `@StateObject` for StoreManager and `@AppStorage` for onboarding persistence
- **Navigation Flow**: Onboarding → Paywall (if not subscribed) → Main Content

### Key Components

#### StoreManager (`StoreManager.swift`)
- Central subscription management using StoreKit 2
- Handles product loading, purchasing, and transaction verification
- Maintains subscription status across the app
- Product IDs: `template_weekly` (with 3-day trial), `template_lifetime`

#### View Hierarchy
- `OnboardingView`: Initial welcome screen
- `PaywallView`: Subscription purchase interface with testimonials and plan selection
- `ContentView`: Main app content that adapts based on subscription status

## Development Commands

### Build & Run
```bash
# Open in Xcode
open Apptemplate.xcodeproj

# Build from command line (requires Xcode Command Line Tools)
xcodebuild -project Apptemplate.xcodeproj -scheme Apptemplate -configuration Debug build

# Run on simulator
xcodebuild -project Apptemplate.xcodeproj -scheme Apptemplate -destination 'platform=iOS Simulator,name=iPhone 15' run
```

### Testing StoreKit
- The project includes `apptemplatestorekit.storekit` configuration file for local testing
- Test subscriptions locally using Xcode's StoreKit Testing feature
- Products configured: Weekly subscription with 3-day trial ($3.99/week), Lifetime subscription ($19.99)

## Important Implementation Details

### StoreKit Integration
- Uses StoreKit 2's async/await API for all purchase operations
- Implements transaction listener for real-time purchase updates
- Verifies all transactions before granting access
- Handles restore purchases functionality

### State Management Patterns
- Subscription status is managed globally via `@EnvironmentObject`
- Onboarding completion tracked in `@AppStorage` for persistence
- Purchase state enum handles loading states and errors

### UI Considerations
- Paywall automatically dismisses when subscription is successful
- Content view updates reactively based on subscription status
- Testimonials rotate automatically with timer-based animation

## Common Development Tasks

### Adding New Features
- Premium features should check `storeManager.isSubscribed` before enabling
- Update `ContentView` to show/hide features based on subscription status

### Modifying Subscription Products
1. Update product IDs in `StoreManager.productIds` array
2. Modify StoreKit configuration file (`apptemplatestorekit.storekit`)
3. Update paywall UI in `PaywallView` to reflect new plans

### Testing Purchase Flows
1. Use Xcode's StoreKit Testing environment
2. Enable StoreKit configuration in scheme settings
3. Test various scenarios: successful purchase, cancellation, restore

## Notes
- The app currently has placeholder testimonials and app icon references
- TODO items in code: Terms and Privacy button actions need implementation
- Consider implementing proper error handling and user feedback for failed purchases