# NutriFit: A Halal Nutrition and Fitness Planner Mobile Application

**Group Members:**
1. **TENGKU MUHAMMAD ABDUH BIN TENGKU MOHAMAD ZULKIFLI (2219029)**
2. **WAN AHMED FAUZIZAFRY BIN WAN KHALID (2221141)**
3. **NUR SAFIAH ASHIQIN BIN SHUHANIZAL (2317618)**
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

<img width="200" height="812" alt="Welcome Screen - 1" src="https://github.com/user-attachments/assets/1b4bc286-d4f2-4f8f-89a2-96115bdb0af6" /> 
<img width="200" height="812" alt="Login Page" src="https://github.com/user-attachments/assets/7305a95f-71e5-49fe-a235-ff79beb6451b" />
<img width="200" height="812" alt="Register Page - 1" src="https://github.com/user-attachments/assets/deeafdeb-d40f-4228-967b-f73d55c4c2e1" />

**2. User Onboarding & Goal Setup Screen**

<img width="200" height="812" alt="&#39; (1)" src="https://github.com/user-attachments/assets/10550188-8e4f-49bb-abf9-9511d1e9cd06" />
<img width="200" height="812" alt="&#39;" src="https://github.com/user-attachments/assets/3df16cd0-7cca-441d-8a98-7c9456d1f17a" />

**3. Home Dashboard (Calories & Workout Summary)**

<img width="200" height="812" alt="Home" src="https://github.com/user-attachments/assets/7115712f-3198-4f0f-9ce3-bb589e9fe5cf" />

**4. Meal Plan & Meal Details Screen**

<img width="183" height="812" alt="Meal Planner" src="https://github.com/user-attachments/assets/60ff20a2-9db1-4b35-94b5-6010e696cbe7" />
<img width="200" height="812" alt="Category Breakfast" src="https://github.com/user-attachments/assets/9daa2488-b864-4207-ac08-f1c09f308f11" />


**5. Add Meal Log Screen** </br>
<img width="200" height="812" alt="Meal Details" src="https://github.com/user-attachments/assets/c240355e-0636-4d7f-adc8-74042dfc832e" />


**6. Workout Plan & Workout Details Screen** </br>
<img width="200" height="812" alt="Workout Tracker" src="https://github.com/user-attachments/assets/aad28384-3d75-422d-98e6-da5699765a57" />
<img width="200" height="628" alt="Workout Details 2" src="https://github.com/user-attachments/assets/de95e218-f0ca-4604-855b-6150456704bd" />

**7. Progress Tracking Screen** </br>
<img width="200" height="812" alt="Progress Photo" src="https://github.com/user-attachments/assets/8ddb2187-0fc9-4d39-8dd7-060986474220" />
<img width="200" height="812" alt="image" src="https://github.com/user-attachments/assets/2700269f-4b43-4708-98db-cdde263ac6b1" />

**8. Profile Settings Screen** </br>
<img width="200" height="812" alt="image" src="https://github.com/user-attachments/assets/df363717-2d2f-4131-8812-76a66c6b8f70" />


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
