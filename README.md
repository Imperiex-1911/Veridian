# Veridian - AI Home Energy Advisor 🌿

Veridian is a full-stack mobile application designed to help homeowners understand their energy consumption, discover personalized recommendations, and connect with government rebates and certified contractors to build a more sustainable future.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)]()
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi&logoColor=white)]()
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)]()
[![Google Gemini](https://img.shields.io/badge/Google%20Gemini-8E77F0?style=for-the-badge&logo=google-gemini&logoColor=white)]()

## 🎬 Live Demo

https://youtu.be/OZiThfwGdwI
## ✨ Key Features

- **Multi-Step Home Audit**: An intuitive wizard for users to input data about their appliances, insulation, and energy habits.
- **Carbon Footprint Analysis**: A dynamic dashboard that visualizes the user's carbon emissions by category using a clean pie chart.
- **Intelligent Recommendation Engine**: A rule-based system that analyzes audit results and connects users with relevant rebates and contractors.
- **Personalized Rebate Finder**: Fetches and filters Australian government rebates based on the user's location and income.
- **Contractor Directory**: A searchable directory of certified contractors, filterable by the services they provide.
- **AI Energy Advisor**: A personalized chatbot, powered by Google's Gemini API, that provides contextual advice based on the user's unique audit data.

## 🛠️ Tech Stack

| Component          | Technology              | Purpose                                                   |
| :----------------- | :---------------------- | :-------------------------------------------------------- |
| **Frontend**       | Flutter, Dart           | Cross-platform mobile application framework.              |
| **Backend**        | FastAPI (Python)        | High-performance API for calculations and data filtering. |
| **Database**       | Google Firestore        | NoSQL database for user data, audits, and more.           |
| **Authentication** | Firebase Authentication | Secure user sign-up and login.                            |
| **AI Chatbot**     | Google Gemini API       | Powers the intelligent AI Advisor.                        |
| **Deployment**     | Render                  | Cloud platform for hosting the FastAPI backend.           |

## 🚀 Getting Started

To run this project locally, follow these steps:

### Prerequisites

- Flutter SDK installed.
- Python 3.8+ installed.
- A Firebase project with Firestore and Authentication enabled.
- A Google Gemini API key from Google AI Studio.

### Setup Instructions

1.  **Clone the Repository**

    ```sh
   git clone https://github.com/Imperiex-1911/Veridian
   cd Veridian
    ```

2.  **Configure Firebase (Frontend)**

    - Follow the FlutterFire CLI instructions to configure your Flutter app with your Firebase project.
    - Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files in the correct directories.

3.  **Configure Backend Environment**

    - In the `backend/` directory, create a `.env` file.
    - Download your Firebase service account key JSON and save it in the `backend/` directory.
    - Add the following variables to your `.env` file:
      ```env
      FIREBASE_KEY_PATH=./your-firebase-key-name.json
      GEMINI_API_KEY=your_gemini_api_key_here
      ```

4.  **Install Dependencies**

    - **Frontend**:
      ```sh
      cd frontend
      flutter pub get
      ```
    - **Backend**:
      ```sh
      cd ../backend
      pip install -r requirements.txt
      ```

5.  **Run the Application**
    - **Run the Backend Server** (in one terminal):
      ```sh
      cd backend
      uvicorn main:app --reload
      ```
    - **Run the Frontend App** (in a second terminal):
      ```sh
      cd frontend
      flutter run
      ```
