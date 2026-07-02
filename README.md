# GymBros — Smart Gym Occupancy Tracker

A Flutter mobile application that helps gym-goers check real-time crowd levels before heading to the gym. Members use NFC to check in and out, and the app automatically tracks how many people are currently inside each gym. Besides occupancy tracking, GymBros also serves as a personal fitness companion by enabling users to log workouts, track progress, and manage fitness goals.

---

## Group Information

**Group Name:** London is blue 
**Course:** CSCI 4311 — Mobile Application Development  
**Section:** 1  
**Semester:** 2

## Group Members
1. Faris Syafi Hakim Bin Mohd Suhaidi (2226745) Group leader
2. Iman Adzroy Bin (2228779)
3. Arif  (2318237)
4. Muhammad Izzat Izzuddin Bin Mohd Yusof (2314525)

## Task Distribution

1.Faris Syafi Hakim (2226745)
- Project Ideation & Initiation, Login, Register, Main, Home, Gym Detail screens

2.Iman Adzroy (2228779)
-  Requirement Analysis & Planning, Workout module 

3.Arif  (2318237)
- Project Development, Progress screen (graphs, personal records)

4.Muhammad Izzat Izzuddin Bin Mohd Yusof (2314525)
- Project Design, Profile screen

# 1. Project Ideation & Initiation (Faris Syafi)

## Project Overview

GymBros is a mobile application developed to solve one of the most common problems faced by gym members—arriving at a gym only to discover that it is overcrowded. The application provides real-time occupancy information using NFC technology, allowing users to check how busy a gym is before visiting.

Besides occupancy tracking, GymBros also serves as a personal fitness companion by enabling users to log workouts, track progress, and manage fitness goals.

## Problem Statement

Many gyms do not provide members with real-time occupancy information. As a result, users often waste time travelling to overcrowded gyms, leading to longer waiting times for equipment and a poorer workout experience.

Gym owners also lack an automated system to accurately monitor the number of people currently inside their facilities, making occupancy management inefficient.

## Proposed Solution

GymBros uses NFC technology to automate gym check-in and check-out.

When users arrive, they simply tap their NFC-enabled smartphone against the gym's NFC reader (simulated using an NFC tag during the prototype). The application verifies the user and records the entry in the database, automatically updating the gym's occupancy count.

Upon leaving, users perform another NFC tap to check out, ensuring occupancy information remains accurate in real time.

## Objectives

- Provide real-time gym occupancy information.
- Reduce overcrowding by helping users plan their gym visits.
- Automate gym attendance using NFC technology.
- Prevent duplicate check-ins.
- Enforce maximum gym capacity.
- Allow users to record workouts and monitor fitness progress.

## Target Users

- Gym Members
- Gym Owners and Managers
- Fitness Enthusiasts

## Core Features

- User Registration & Login
- Live Gym Occupancy Display
- NFC Check-in & Check-out
- Occupancy Status Indicators
- Duplicate Entry Prevention
- Capacity Enforcement
- Workout Logging
- Progress Tracking
- User Profile Management

## Technology Stack

| Component | Technology |
|----------|------------|
| Frontend | Flutter |
| Backend | Supabase |
| Database | PostgreSQL |
| Authentication | Supabase Auth |
| Storage | Supabase Storage |
| IDE | Visual Studio Code |
| Version Control | GitHub |

---

# 2. Requirement Analysis & Planning (Iman Adzroy)

## Functional Requirements

- User authentication
- Gym listing
- Real-time occupancy tracking
- NFC check-in/check-out
- Workout management
- Progress tracking
- Profile management

## Non-Functional Requirements

- Fast response time
- Secure authentication
- Reliable database storage
- Responsive mobile interface
- Real-time data synchronization

## Project Planning

- Requirement gathering
- Database planning
- UI/UX planning
- Development sprint planning
- Testing schedule
- Deployment preparation

---

# 3. Project Design (Izzat)

## 3.1 User Interface (UI) Design

GymBros follows a **mobile-first design** built with Flutter to provide an intuitive and responsive user interface.

The application consists of several main screens:

- **Authentication** – Login and registration with secure password visibility toggle.
- **Home** – Displays a list of gyms with images, location, live occupancy, and capacity indicators.
- **Gym Details** – Allows users to perform NFC check-in and check-out while viewing gym information.
- **Workout** – Create workouts using predefined templates or custom exercises, with logging for sets, reps, and weight.
- **Progress** – Displays workout history, strength progression, personal records, and analytics using charts.
- **Profile** – Manage personal information, fitness goals, subscription status, and workout streaks.

The interface uses reusable Flutter widgets such as Cards, ListViews, Forms, Bottom Navigation Bar, Floating Action Button, and Modal Bottom Sheets to maintain a clean and consistent design.

---

## 3.2 User Experience (UX) Design

The application is designed to provide a smooth and efficient experience for gym members.

Key UX principles include:

- Simple bottom navigation with four main tabs (Home, Workout, Progress, Profile).
- Real-time occupancy updates using color indicators (Green, Orange, Red).
- Fast NFC check-in/check-out with minimal user interaction.
- Flexible workout logging using predefined templates or custom workouts.
- Progress visualization through charts and personal records.
- Gamification features including workout streaks and fitness milestones.

---

## 3.3 Design Consistency

GymBros maintains a consistent design language throughout the application.

### Theme

- Dark mode interface
- Neon yellow accent color
- High contrast for readability

### Typography

- Consistent heading hierarchy
- Readable body text
- Standardized font sizes

### Components

Reusable UI components include:

- Cards
- Buttons
- Input fields
- Icons
- Navigation Bar
- Progress Bars
- Charts

All screens follow the same spacing, rounded corners, color palette, and interaction patterns to provide a seamless user experience.

# 4. Project Development (Arif)

## Development Environment

- Flutter SDK
- Dart
- Visual Studio Code
- Supabase
- GitHub

## Modules Implemented

- Authentication Module
- Home Module
- Gym Occupancy Module
- NFC Module
- Workout Module
- Progress Module
- Profile Module

## Testing

- Authentication testing
- Database testing
- NFC testing
- UI testing
- Integration testing

## Current Limitations

- NFC requires a physical Android device.
- NFC cannot be tested on an emulator.
- Prototype uses an NFC tag to simulate a reader.
- Limited iOS NFC support.

## Future Improvements

- Support multiple gym branches.
- Reservation system.
- AI-based crowd prediction.
- Push notifications for occupancy updates.
- Wearable device integration.
- Apple Wallet / Google Wallet support.

