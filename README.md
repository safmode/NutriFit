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

**2. User Onboarding & Goal Setup Screen**

**3. Home Dashboard (Calories & Workout Summary)**

**4. Meal Plan & Meal Details Screen**

**5. Add Meal Log Screen**

**6. Workout Plan & Workout Details Screen**

**7. Progress Tracking Screen**

**8. Profile Settings Screen**


## 6.0 Architecture / Technical Design

### 6.1 Application Architecture Overview

NutriFit is developed as a hybrid mobile application using Flutter, following a modular and scalable architecture. The application separates concerns between user interface components, business logic, and data services to ensure maintainability and clean code practices.

### 6.2 Widget and Folder Structure

**The project follows a structured folder organisation:**



