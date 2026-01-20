# NutriFit: A Halal Nutrition and Fitness Planner Mobile Application

**Group Members:**
1. **TENGKU MUHAMMAD ABDUH BIN TENGKU MOHAMAD ZULKIFLI (2219029)**
2. **WAN AHMED FAUZIZAFRY BIN WAN KHALID (2221141)**
3. **NUR SAFIAH ASHIQIN BINTI SHUHANIZAL (2317618)**
4. **NURFARAH HANIS BINTI ISMAIL (2226488)**


## 1.0 Introduction

Maintaining a healthy lifestyle requires consistent monitoring of diet, physical activity, and personal health goals. However, many students and working adults struggle to manage their daily nutrition intake and exercise routines due to time constraints, lack of structured planning, and limited access to reliable, halal-compliant fitness guidance. Existing fitness applications often focus only on workouts or calorie tracking without integrating both elements in a user friendly and culturally appropriate manner.

NutriFit is proposed as a hybrid mobile application that integrates nutrition planning, meal logging, and workout management into a single platform. The application is designed to support halal and ethical lifestyle practices, making it suitable for Muslim users while remaining inclusive for the general public. NutriFit is relevant in promoting healthier habits, reducing lifestyle-related health risks, and encouraging sustainable fitness routines through technology.


## 2.0 Objectives 

**The objectives of NutriFit are:**
1. To provide users with a structured and personalised nutrition and workout planning system.
2. To enable users to track daily calorie intake, meals, and exercise activities efficiently.
3. To support healthy lifestyle management through progress monitoring and reminders.
4. To implement a halal-compliant, ethical, and user-friendly mobile fitness solution.
5. To demonstrate practical implementation of hybrid mobile development concepts using Flutter and Firebase.


## 3.0 Target Users

**The target users of NutriFit include:**
1. University students who want to manage diet and fitness effectively.
2. Young adults seeking a simple and structured health tracking application.
3. Users interested in halal-friendly nutrition and ethical fitness guidance.
4. Beginners in fitness who require guided workout and meal planning


## 4.0 Features & Functionalities 

### 4.1 Core Modules & Functional Features

#### 4.1.1 User Authentication
- Email and password registration and login using Firebase Authentication
- Secure session handling and user authentication state tracking
- Password reset functionality

#### 4.1.2 User Profile & Goal Setting
- Users input personal information such as age, height, weight, and activity level
- Users select personal fitness goals (weight loss, muscle gain, or health maintenance)
- Automatic daily calorie target calculation based on user inputs
- Profile data stored and retrieved from Firebase Cloud Firestore

#### 4.1.3 Meal Planning & Meal Logging
- Daily halal meal recommendations categorised by meal type (breakfast, lunch, dinner, snacks)
- Meal logging with calorie calculation and portion tracking
- Optional meal image upload using Firebase Storage
- Historical meal records stored in Firestore for progress analysis

#### 4.1.4 Workout Planning & Workout Logging
- Weekly workout plans based on fitness level (beginner, intermediate, advanced)
- Workout details including duration, repetitions, and intensity
- Workout completion logging and history tracking

#### 4.1.5 Progress Dashboard
- Weight progress tracking with visual indicators
- Daily calorie intake overview
- Weekly and monthly workout activity summaries
- Simple charts and progress indicators to help users stay motivated

#### 4.1.6 Reminders & Notifications
- Daily reminders for meals and workouts
- Motivational notifications encouraging consistency
- Notification data managed through Firebase services

### 4.2 User Interface Components

**The application will utilise the following Flutter UI components:**
- Cards and ListViews for displaying meals and workouts
- Forms with validation for user inputs
- Progress indicators and charts for activity tracking
- Bottom navigation bar for main modules
- Named routes for structured navigation


## 5.0 Proposed UI Mock-up

**The proposed UI mock-ups includes:**

**1. Splash Screen & Login/Register Screen**
<p align="center">
<img width="200" height="812" alt="Welcome Screen - 1" src="https://github.com/user-attachments/assets/1b4bc286-d4f2-4f8f-89a2-96115bdb0af6" /> 
<img width="200" height="812" alt="Login Page" src="https://github.com/user-attachments/assets/7305a95f-71e5-49fe-a235-ff79beb6451b" />
<img width="200" height="812" alt="Register Page - 1" src="https://github.com/user-attachments/assets/deeafdeb-d40f-4228-967b-f73d55c4c2e1" />
</p>

**2. User Onboarding & Goal Setup Screen**
<p align="center">
<img width="200" height="812" alt="&#39; (1)" src="https://github.com/user-attachments/assets/10550188-8e4f-49bb-abf9-9511d1e9cd06" />
<img width="200" height="812" alt="&#39;" src="https://github.com/user-attachments/assets/3df16cd0-7cca-441d-8a98-7c9456d1f17a" />
</p>

**3. Home Dashboard (Calories & Workout Summary)**
<p align="center">
<img width="200" height="812" alt="Home" src="https://github.com/user-attachments/assets/7115712f-3198-4f0f-9ce3-bb589e9fe5cf" />
</p>

**4. Meal Plan & Meal Details Screen**
<p align="center">
<img width="183" height="812" alt="Meal Planner" src="https://github.com/user-attachments/assets/60ff20a2-9db1-4b35-94b5-6010e696cbe7" />
<img width="200" height="812" alt="Category Breakfast" src="https://github.com/user-attachments/assets/9daa2488-b864-4207-ac08-f1c09f308f11" />
</p>

**5. Add Meal Log Screen** </br>
<p align="center">
<img width="200" height="812" alt="Meal Details" src="https://github.com/user-attachments/assets/c240355e-0636-4d7f-adc8-74042dfc832e" />
</p>

**6. Workout Plan & Workout Details Screen** </br>
<p align="center">
<img width="200" height="812" alt="Workout Tracker" src="https://github.com/user-attachments/assets/aad28384-3d75-422d-98e6-da5699765a57" />
<img width="200" height="628" alt="Workout Details 2" src="https://github.com/user-attachments/assets/de95e218-f0ca-4604-855b-6150456704bd" />
</p>

**7. Progress Tracking Screen** </br>
<p align="center">
<img width="200" height="812" alt="Progress Photo" src="https://github.com/user-attachments/assets/8ddb2187-0fc9-4d39-8dd7-060986474220" />
<img width="200" height="812" alt="image" src="https://github.com/user-attachments/assets/2700269f-4b43-4708-98db-cdde263ac6b1" />
</p>

**8. Profile Settings Screen** </br>
<p align="center">
<img width="200" height="812" alt="image" src="https://github.com/user-attachments/assets/df363717-2d2f-4131-8812-76a66c6b8f70" />
</p>

## 6.0 Architecture / Technical Design

### 6.1 Application Architecture Overview

NutriFit is developed as a hybrid mobile application using Flutter, following a modular and scalable architecture. The application separates concerns between user interface components, business logic, and data services to ensure maintainability and clean code practices.

### 6.2 Widget and Folder Structure

**The project follows a structured folder organisation:**
- main.dart – Application entry point
- screens/ – UI screens (authentication, dashboard, meals, workouts, profile)
- widgets/ – Reusable UI components such as cards, buttons, and form fields
- models/ – Data models representing users, meals, workouts, and logs
- providers/ – State management logic using Provider
- services/ – Firebase authentication, Firestore database, and storage services
- utils/ – Application constants, theme configurations, and helper functions

### 6.3 Navigation and Routing
**The application uses named routes to manage navigation between screens. Key routes include:**
- /login
- /register
- /onboarding
- /home
- /meals
- /addMeal
- /workouts
- /addWorkout
- /progress
- /profile

This approach ensures clean and maintainable navigation flow.

### 6.4 State Management Approach
The Provider package is used as the primary state management solution. It enables efficient data sharing and UI updates without unnecessary rebuilds.

**Implemented providers include:**
- AuthProvider – Manages authentication state
- MealProvider – Handles meal data and meal logging
- WorkoutProvider – Handles workout plans and workout logs
- ProgressProvider – Manages user progress and analytics

### 7.0 Firebase Integration

The application integrates Firebase services to support backend functionality:

1. Firebase Authentication:
   - Email and password login and registration
   - Secure user authentication
2. Cloud Firestore:
   - Storage of user profile data
   - Storage of meal logs, workout logs, and progress records
3. Firebase Storage:
   - Optional upload and storage of meal images
   - Firebase Cloud Messaging (Optional / Stretch Feature):
4. Push notifications for meal and workout reminders


## 8.0 Data Model Design

### 8.1 Firestore Collections and Documents

**Users Collection (users/{userId})**
- name : String
- age : int
- heightCm : double
- weightKg : double
- goal : String
- calorieTarget : int
- createdAt : Timestamp

**Meal Logs Subcollection (users/{userId}/mealLogs/{logId})**
- date : Timestamp
- mealName : String
- mealType : String
- calories : int
- photoUrl : String

**Workout Logs Subcollection (users/{userId}/workoutLogs/{logId})**
- date : Timestamp
- workoutName : String
- durationMinutes : int
- difficulty : String

### 8.2 Data Relationships

- One user can have multiple meal logs, workout logs, and weight logs
- Logs are stored as subcollections under each user document
- This structure ensures scalability and data security

## 9.0 Flowchart/Sequence Diagram
### 9.1 Flowchart

<img width="1079" height="1111" alt="MOBILE APP DEV-flowchart drawio (1)" src="https://github.com/user-attachments/assets/bb81bc0c-3d6b-483d-96e5-54c6ff4f422d" />


### 9.2 Sequence Diagram

<p align="center">
<img width="256" height="195" alt="image" src="https://github.com/user-attachments/assets/8ddf601b-7c92-4220-9220-49b489008771" /> </br>
</p>

<p align="center"> Figure 9.2.1 User Login Sequence</p>
The diagram illustrates the authentication process. It starts when the User enters their email and password. The App sends these credentials to Firebase Auth for verification. Once verified, the App fetches the user's profile and grants access by displaying the Home Screen. </br>

<p align="center">
<img width="256" height="195" alt="image" src="https://github.com/user-attachments/assets/17973347-141d-4491-8b34-baeaf557178c" /></br>
</p>

<p align="center"> Figure 9.2.2 Meal Logging Sequence</p>
This sequence shows how a user records a new meal. The User initiates the "Add Meal" action. The App handles two backend operations: it uploads any meal images to Firebase Storage and then saves the meal details and updates the total calorie count in the Firestore database.</br>

<p align="center">
<img width="267" height="214" alt="image" src="https://github.com/user-attachments/assets/6aa94077-1974-4317-b6b9-14a86b7c0f51" /></br>
</p>

<p align="center"> Figure 9.2.3 Workout Logging Sequence</p>
This diagram depicts the flow for tracking exercise. The User selects a workout and marks it as complete. The App then communicates with Firestore to save the specific workout log and update the user's overall progress records.</br>

<p align="center">
<img width="272" height="202" alt="image" src="https://github.com/user-attachments/assets/0dfcd297-db5a-4287-9749-4b8c8ce63372" /></br>
</p>

<p align="center">Figure 9.2.4 View Progress Sequence</p>
This sequence details how the app retrieves and displays data. When the User opens the progress screen, the App queries Firestore for past logs. Firestore returns the requested data, which the App then processes to display visual charts to the User.</br>

## 10.0 Shariah-Compliant and Ethical Considerations

NutriFit is designed in accordance with Shariah-compliant and ethical development principles:
- All meal recommendations and content are halal-friendly
- The application avoids body-shaming language and promotes healthy lifestyle balance
- No inappropriate imagery, advertisements, or misleading content
- The application does not provide medical diagnosis and serves only as a lifestyle support tool
- User data privacy and consent are respected at all times


## 11.0 Scope and Limitations
### 11.1 Project Scope
- User authentication and profile management
- Meal and workout logging system
- Progress dashboard with visual summaries
- Firestore-based data storage and retrieval

### 11.2 Limitations
- The application does not replace professional medical or dietary advice
- Advanced features such as AI-based meal recommendations are not included in the initial version
- Notification features may be limited based on implementation time

### 12.0 Final UI Screenshots

**1. Splash Screen & Login/Register Screen**
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/7f18ec59-9442-4db7-a512-dc13feb72ce7" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/310bec41-fa2e-4f37-9df9-43706cd87ac4" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/65dfca0c-52e3-4534-b54f-8bccc0672c47" />

**2. User Onboarding & Goal Setup Screen**


**3. Home Dashboard**
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/f7ce7e35-3b49-46fb-850e-6585e5db3969" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/7bbb0961-7a75-4161-bf4c-ed34faa1c133" />


**4. Meal Plan & Meal Details Screen**
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/b03ba9d6-5e3e-4d5e-b15b-508a5f50b6ad" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/aae4ecf1-01f5-466f-af4b-616a53323f35" />


**5. Add Meal Log Screen** </br>
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/cf017436-4c78-4867-b734-d3c1623c9cc4" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/2c77a056-4fd1-4bbd-9b2c-04ae0eea38ff" />


**6. Workout Plan & Workout Details Screen** </br>
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/d576f8fb-9498-4f97-b94b-3730e4af5092" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/56e96282-756a-4f46-b68d-6d67bcdad4d7" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/0be41c81-2afe-4224-89f8-4fc908aad57d" />


**7. Progress Tracking Screen** </br>
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/7274da19-0537-4054-ab90-b1921ec4fb92" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/bd01e388-9e57-447d-bbdc-722c4f571167" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/6e7a9955-3288-4933-8f13-eb52229ca660" />


**8. Profile Settings Screen** </br>
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/3eaf4c1c-dc50-48a7-9303-58526c8a3073" />
<img width="311" height="709" alt="image" src="https://github.com/user-attachments/assets/d96dc324-311a-4ef7-84d6-417003b81c99" />

### 13.0 Summary of achieved features
NutriFit successfully implements a comprehensive halal-compliant nutrition and fitness tracking system with the following core features:Authentication & User Management

**1. Secure email and password authentication using Firebase Authentication with session persistence**
- User profile creation and management with personalized fitness goal setting
- Onboarding flow collecting age, height, weight, activity level, and fitness objectives
- Automatic daily calorie target calculation based on user metrics and goals
- Meal Planning & Logging

**2. Halal meal recommendations categorized by meal type (breakfast, lunch, dinner, snacks)**
- Meal logging functionality with calorie tracking and portion management
- Optional meal image upload capability through Firebase Storage integration
- Daily calorie intake monitoring with visual progress indicators against target goals
- Historical meal records stored in Firestore for long-term tracking and analysis
- Workout Planning & Tracking

**3. Weekly workout plans tailored to different fitness levels (beginner, intermediate, advanced)**
- Detailed workout information including duration, repetitions, and intensity levels
- Workout completion logging with timestamp tracking
- Exercise history accessible for reviewing past activities
- Progress Dashboard

**4. Real-time weight progress tracking with visual trend indicators**
- Daily calorie intake overview showing consumed versus target calories
- Weekly and monthly workout activity summaries
- Simple charts and progress visualizations to maintain user motivation
- Comprehensive analytics accessible through intuitive navigation
- User Interface

**5. Clean, modern interface following Material Design principles**
- Bottom navigation bar for seamless module switching
- Responsive cards and list views for displaying meals and workouts
- Form validation ensuring data integrity
- Consistent color scheme and typography aligned with health and wellness branding

### 14.0 Technical explaination
**Architecture & Development Stack**
NutriFit is built using Flutter framework, enabling true cross-platform development with a single codebase for both Android and iOS. The application follows a modular architecture pattern separating concerns between presentation, business logic, and data layers.

**14.1 State Management Implementation**
The Provider package serves as the state management solution, implementing the following architecture:
- AuthProvider: Manages authentication state, user session handling, and login/logout operations. Listens to Firebase Authentication state changes and updates UI accordingly.
- MealProvider: Handles meal data retrieval, meal logging operations, and calorie calculations. Maintains daily calorie intake state and synchronizes with Firestore.
- WorkoutProvider: Manages workout plan data, workout completion logging, and exercise history. Provides filtered views based on difficulty levels and dates.
- ProgressProvider: Aggregates data from meal and workout logs to generate progress analytics, charts, and trend visualizations.

**14.2 Firebase Backend Integration**
The application leverages multiple Firebase services for comprehensive backend functionality:

- Firebase Authentication: Implements secure email/password authentication with automatic session management. Password reset functionality integrated through email verification.
- Cloud Firestore: Serves as the primary database with a hierarchical structure:
   - Users collection stores profile data (name, age, height, weight, goals, calorie targets)
   - Meal logs subcollection tracks daily food intake with timestamps, calorie data, and optional image URLs
   - Workout logs subcollection records exercise activities with duration and difficulty metrics
   - Real-time synchronization ensures data consistency across devices


- Firebase Storage: Handles meal image uploads with automatic URL generation and secure access rules
- Security Rules: Implemented to ensure users can only access and modify their own data

**14.3 Data Flow Architecture**

1. User interactions trigger UI events in Flutter widgets
2. Events invoke methods in Provider classes
3. Providers communicate with Firebase services through dedicated service classes
4. Service classes handle API calls, error handling, and data transformation
5. Providers update internal state and notify listening widgets
6. UI automatically rebuilds with updated data

**14.4 Navigation System**
Named routes provide structured navigation throughout the app:
- Routes defined in main.dart for centralized management
- Route guards implemented to protect authenticated-only screens
- Smooth transitions between screens using Flutter's Navigator 2.0 API
- Deep linking capability for future notification integration

**Data Validation & Error Handling**
- Form validation implemented using Flutter's Form widget and TextFormField validators
- Try-catch blocks wrapping all Firebase operations
- User-friendly error messages displayed via SnackBars
- Loading states managed to prevent duplicate submissions
- Offline capability with local caching for improved user experience

**UI/UX Implementation**
- Responsive design adapting to different screen sizes using MediaQuery
- Custom reusable widgets (meal cards, workout cards, progress charts) for consistency
- Async operations handled with FutureBuilder and StreamBuilder widgets
- Smooth animations for screen transitions and UI feedback
- Accessibility features including semantic labels and contrast ratios

### 15.0 Limitations and future enhancements
**15.1 Current Limitations**

1. No Professional Integration: The app does not connect with certified nutritionists or fitness trainers for professional guidance and cannot replace expert medical or dietary advice.
2. Limited Meal Database: Meal recommendations are currently based on a predefined static list rather than a comprehensive, searchable database of halal foods.
3. Basic Calorie Calculation: Uses simplified formulas (likely Mifflin-St Jeor or Harris-Benedict) without accounting for specific health conditions, metabolic variations, or precise body composition analysis.
4. Manual Data Entry: Users must manually log all meals and workouts, which can be time-consuming and prone to user error or inconsistency.
5. Limited Notification System: Push notifications for reminders may not be fully implemented or may lack customization options for timing and frequency.
6. No Social Features: Lacks community support, friend challenges, or social accountability features that could enhance user engagement and motivation.
7. Basic Progress Analytics: Charts and visualizations are simple and may not provide deep insights into trends, patterns, or correlations between diet and exercise.
8. Single Language Support: Currently supports only one language (likely English), limiting accessibility for non-English speaking Muslim users.
9. No Offline Mode: Requires internet connectivity for most operations, limiting usability in areas with poor network coverage.
10. Limited Exercise Variety: Workout plans may not cover specialized training (strength training progressions, sport-specific exercises, yoga, etc.).

Proposed Future Enhancements
Short-term Enhancements (Version 2.0)

Barcode Scanning: Integrate barcode scanner for quick meal logging from packaged food items with automatic halal certification verification.
Enhanced Notifications: Implement Firebase Cloud Messaging with customizable reminder schedules for meals, workouts, hydration, and prayer times.
Water Intake Tracking: Add hydration monitoring with daily water intake goals and reminder notifications.
Recipe Suggestions: Provide detailed halal recipes with step-by-step cooking instructions and nutritional breakdowns.
Exercise Video Tutorials: Embed instructional videos demonstrating proper form for each workout to reduce injury risk.
Dark Mode: Implement theme switching for improved user experience in low-light conditions.
Data Export: Allow users to export their logs and progress reports in PDF or CSV format for personal records or sharing with healthcare providers.

**15.2 Medium-term Enhancements (Version 3.0)**

1. AI-Powered Meal Recognition: Implement machine learning models to identify meals from photos and automatically estimate calorie content.
2. Smart Recommendations: Use AI algorithms to suggest personalized meal plans and workout routines based on user progress, preferences, and goals.
3. Integration with Wearables: Connect with fitness trackers and smartwatches (Fitbit, Apple Watch, Samsung Galaxy Watch) for automatic activity and calorie tracking.
4. Macro Nutrient Tracking: Expand beyond calories to track proteins, carbohydrates, fats, fiber, and micronutrients for comprehensive nutrition management.
5. Community Features: Add forums, group challenges, success story sharing, and leaderboards to build a supportive Muslim fitness community.
6. Multi-language Support: Implement internationalization for Arabic, Malay, Urdu, and other languages common in Muslim-majority regions.
7. Prayer Time Integration: Sync with Islamic prayer times to schedule workouts and meals around religious obligations.

**Long-term Enhancements (Version 4.0+)**

1. Professional Network: Connect users with certified halal nutritionists, Islamic fitness coaches, and healthcare providers for virtual consultations.
2. Advanced Analytics: Implement predictive analytics to forecast progress, identify plateaus, and suggest interventions using machine learning.
3. Ramadan Mode: Special features for fasting periods including Suhoor/Iftar meal planning, adjusted workout schedules, and spiritual wellness tracking.
4. Supplement Tracking: Database of halal-certified supplements with interaction warnings and effectiveness tracking.
5. Medical Integration: HIPAA-compliant integration with electronic health records for users with chronic conditions or specific medical needs.
6. Gamification: Achievement badges, streak tracking, and reward systems to increase long-term engagement and adherence.
7. AR Workout Coach: Augmented reality features using device cameras to provide real-time form correction during exercises.
8. Meal Planning Automation: AI-generated weekly meal plans with automatic grocery lists and integration with halal food delivery services.
9. Genetic Integration: Optional integration with genetic testing data to provide personalized nutrition recommendations based on individual metabolic profiles.
10. Mental Wellness Module: Add stress management, sleep tracking, and mindfulness features aligned with Islamic practices to support holistic health.


## References
Flutter. (2024). Flutter documentation. https://docs.flutter.dev </br>
Flutter Team. (2024). Managing state with Provider. https://docs.flutter.dev/data-and-backend/state-mgmt/simple</br>
Google. (2024). Firebase documentation. https://firebase.google.com/docs</br>
Figma. (2024). Figma design platform. https://www.figma.com</br>
