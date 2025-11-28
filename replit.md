# MLWIO - Multi-Platform Video Streaming App

## Overview
MLWIO is a multi-platform Flutter application designed to provide a YouTube-like video streaming experience. It supports movies and series with episode playback, auto-play functionality, and integrates video streaming from the MovieWay API. The project aims to deliver a high-quality user interface with smooth animations, Material 3 design, and a focus on scalability and user experience, making it production-ready for UI/UX demonstration and future API integration.

## User Preferences
My preferences are as follows:
- **Interaction**: Ask before making major changes.
- **Workflow**: I want iterative development.
- **Communication**: I prefer simple language and detailed explanations.
- **Code Style**: I prefer functional programming paradigms where applicable.
- **Restrictions**: Do not make changes to the `Z` folder. Do not make changes to the `Y` file.

## Recent Changes (Nov 28, 2025)
- **Thumbnail Loading Speed**: Implemented CachedNetworkImage with memory caching (memCacheWidth/memCacheHeight) for fast thumbnail loading on home screen
- **Mini Player Fix**: Fixed down arrow button and drag-down gesture to properly minimize player via MiniPlayerService, preserving player state
- **Removed Description Section**: Cleaned up player UI by removing description section from both wide and narrow layouts
- **Bottom-Right Mini Player**: Updated to display thumbnail with CachedNetworkImage and content title

## Changes (Nov 27, 2025)
- Updated video models to support `playbackUrl` from API for direct video streaming
- Fixed `VideoUrlConverter` to handle MovieWay API URLs (drive.movieway.site)
- Updated thumbnail loading to use `signedThumbnail` field when available
- Added YouTube-style video player with overlay controls
- Added video settings sheet (Quality, Playback Speed, Captions, Audio Track, Lock Screen)
- Added swipe-down gesture to minimize player
- Added mini-player overlay widget

## System Architecture
The application is built using Flutter, ensuring a single codebase across Android, iOS, macOS, Windows, Linux, and Web platforms.

**UI/UX Decisions:**
- **Dark Mode Theme:** Exclusive dark mode with `#0B0B0D` background, white text (`#FFFFFF`), and red accent (`#FF5252`).
- **Animations:** Extensive use of smooth, premium-quality animations for screen transitions, logo entrances, scaling, and glow effects, including Hero transitions for seamless navigation.
- **Material 3 Design:** Leverages modern Flutter components conforming to Material 3 guidelines.
- **Responsive Layout:** Adapts to various screen sizes and ensures proper padding with safe areas.
- **Core Screens:**
    - **Splash Screen:** Initial loading screen with animated logo (drop animation from top, scale with bounce effect 0→1.2→1.0, red glow pulse effect) that loads app data in parallel (version check, Firebase auth, Hive database initialization). Duration: ~3 seconds.
    - **Welcome Screen:** Features static logo at top, with "Welcome", "MLWIO" text and "Get Start" button that slide up from bottom with fade-in animation.
    - **Sign-in Screen:** Displays MLWIO logo with "Hello!" greeting (capital H), a curved arc design, "Sign in with Google" button, and a feature list.
    - **Home Screen:** YouTube-like vertical list feed with category filtering for content (simplified 2-tab navigation: Home & Profile).
    - **Series Detail Screen:** Provides season and episode listings for series.
    - **Video Player Screen:** YouTube-style player with overlay controls, swipe-down to minimize, settings sheet.
    - **Profile Screen:** User profile and settings management.
    - **Notifications Screen:** Displays notification cards.
    - **Search Screen:** Real-time search with debouncing and result display.

**Technical Implementations:**
- **Content Models:** `ContentItem`, `MovieContent`, `SeriesContent`, `Season`, and `Episode` for structured data with `playbackUrl` support.
- **Services:** `ApiService` for real API integration (api.movieway.site), `AuthService` for Google authentication, `AdMobService` for simplified ad display.
- **Controllers:** `PlaylistController` manages episode playback and auto-play.
- **Video URL Handling:** `VideoUrlConverter` converts various URL formats including MovieWay signed URLs.
- **Core Functionality:**
    - YouTube-like UI with content cards.
    - Smart Content Detection for movies vs. series.
    - Category Filtering (All, Movie, Anime, Web-series).
    - Video Playback via InAppWebView with MovieWay signed URLs.
    - YouTube-style player controls (play/pause, prev/next, progress bar, fullscreen).
    - Settings sheet with Quality, Playback Speed, Captions, Audio Track, Lock Screen options.
    - Swipe-down gesture to minimize player.
    - Auto-play and playlist controls for episodes.
    - Real-time search with debouncing.
    - Lazy loading for images with shimmer placeholders.
    - Pull-to-refresh functionality.
    - Loading, empty, and error states handling.
    - Google Sign-In with a confirmation flow.
    - **Simple Ad System:** Interstitial ads display automatically every 8 minutes with 5-minute cooldown (like YouTube/Facebook apps).

**System Design Choices:**
- **Scalability:** Designed with a clean architecture to easily integrate with a real API.
- **Maintainability:** Organized code structure with clear separation of concerns (models, services, screens, widgets, utils).
- **Performance:** Optimized with lazy loading, image caching, and pagination.

## External Dependencies
The project integrates with the following external services and libraries:

- **`http`**: For making API calls to the backend.
- **`cached_network_image`**: For efficient caching and lazy loading of network images.
- **`shimmer`**: To display shimmering loading placeholders.
- **`url_launcher`**: For launching external URLs, potentially for video links.
- **`google_sign_in`**: For implementing Google OAuth authentication.
- **`google_mobile_ads`**: For AdMob integration with simple interstitial ads.
- **`hive_flutter`**: Local database for watch history and offline downloads.
- **`get`**: State management for navigation and dependency injection.
- **`cupertino_icons`**: Provides iOS-style icons.
- **`flutter_inappwebview`**: For embedding video player with web content.
- **MovieWay API**: Custom backend API hosted at `https://api.movieway.site/api/content` for content retrieval with signed playback URLs.
- **Google OAuth 2.0**: For user authentication, configured with a Replit Secret (`GOOGLE_OAUTH_CLIENT_ID`).
- **AdMob**: For displaying interstitial ads (web platform uses simulation logging).

## API Response Format
The API returns content with the following structure:
```json
{
  "_id": "string",
  "title": "string",
  "category": "Movie|Anime|Web-series",
  "thumbnail": "string (URL)",
  "signedThumbnail": "string (signed URL)",
  "releaseYear": number,
  "driveLink": "string (relative path)",
  "playbackUrl": "string (signed URL for video playback)",
  "seasons": []
}
```
