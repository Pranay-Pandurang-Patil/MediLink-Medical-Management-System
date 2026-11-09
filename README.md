# 💊 MediLink

<p align="center">
  <b>A Flutter-Based Medical Shop Management Application</b>
</p>

<p align="center">
  🚧 <b>Currently Under Active Development</b>
</p>

---

## 📖 About

**MediLink** is a Flutter-based medical shop management application designed to simplify the daily operations of an individual medical shop.

The application provides a centralized platform for managing medicine inventory, tracking batches and expiry dates, monitoring stock levels, maintaining customer records, recording payments, and organizing daily shop notes.

MediLink is designed around a **single-store owner management model**, with a focus on practical functionality, reliable data management, and a clean user experience.

The project is being developed using Flutter, Firebase Authentication, and Hive local storage.

---

## 🎯 Project Objectives

- Simplify medicine inventory management.
- Maintain medicine and batch-wise stock records.
- Track medicine expiry dates.
- Monitor low-stock and out-of-stock medicines.
- Maintain regular customer information.
- Record frequently purchased medicines.
- Manage customer payment records and outstanding balances.
- Maintain daily shop notes.
- Support local access to essential medicine and inventory data.

---

## ✨ Current Development Progress

### 1. Application Foundation
- ✅ Flutter project initialized.
- ✅ Project structure established.
- ✅ Material 3 theme configuration.
- ✅ Custom application logo.
- ✅ Assets organization.
- ✅ Animated splash screen using Lottie.
- ✅ Login and registration screen flow.
- ✅ Main application navigation.

### 2. Dashboard
- ✅ Dashboard screen.
- ✅ Medicine and inventory overview.
- 🔄 Further dashboard refinements.

### 3. Medicine & Inventory Management
- ✅ Medicine CRUD operations.
- ✅ Medicine search.
- ✅ Medicine information management.
- ✅ Batch-wise inventory structure.
- ✅ Stock tracking.
- ✅ Low-stock and out-of-stock monitoring.
- ✅ Expiry tracking and alert structure.
- 🔄 Further inventory testing and refinements.

### 4. Alerts
- ✅ Low-stock alert functionality.
- ✅ Out-of-stock monitoring.
- ✅ Medicine expiry alert categories.
- ✅ 30-day, 60-day and 90-day expiry monitoring.
- 🔄 Notification and alert refinements.

### 5. Shop Profile
- ✅ Shop profile section.
- 🔄 Additional profile refinements.

### 6. Daily Notes
- ✅ Add notes.
- ✅ Edit notes.
- ✅ Delete notes.
- ✅ Hive-based persistence.
- ✅ Reactive note list updates.

### 7. Regular Customers
- ✅ Add customer information.
- ✅ Edit customer information.
- ✅ Delete customer records.
- ✅ Customer search.
- ✅ Reactive customer list updates.
- ✅ Customer-specific medicine records.

### 8. Customer Payment Management
- ✅ Add payment records.
- ✅ Edit payment records.
- ✅ Delete payment records.
- ✅ Payment status tracking.
- ✅ Total, paid and remaining amount summary.
- ✅ Outstanding balance calculation.
- ✅ Payment data validation improvements.

---

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Application development |
| Dart | Programming language |
| Firebase Authentication | Owner authentication |
| Hive | Local database |
| Material Design 3 | User interface |
| Lottie | Animations |
| Git | Version control |
| GitHub | Source code management |

---

## 🗄️ Data Management

MediLink uses a combination of Firebase Authentication and Hive local storage.

### Firebase Authentication
Used for owner account authentication and account access.

### Hive Local Storage
Used for storing application data such as:

- Medicine information.
- Medicine batches.
- Stock information.
- Expiry-related records.
- Shop information and Daily notes.
- Regular customer records.
- Customer medicine records.
- Customer payment records.

Essential medicine with inventory data is designed to remain accessible offline.

---

## 🏗️ Application Modules

| Module | Functionality |
|---|---|
| Authentication | Owner login and registration |
| Dashboard | Overview of store information |
| Inventory | Medicine and stock management |
| Alerts | Expiry and stock monitoring |
| Daily Notes | Store-related notes |
| Regular Customers | Customer information |
| Customer Medicines | Frequently purchased medicines |
| Payment Management | Customer payment records and balances |
| Profile | Shop information |

---

## 🚀 Development Roadmap

| Phase | Planned Work | Status |
|---|---|---|
| 1 | Application foundation and authentication | 🟡 Implemented; further verification |
| 2 | Medicine inventory and batch management | 🟡 Implemented; refinements ongoing |
| 3 | Expiry and stock alerts | 🟡 Implemented; testing ongoing |
| 4 | Daily Notes | ✅ Implemented |
| 5 | Regular Customers | ✅ Implemented |
| 6 | Customer medicines and payment management | 🟡 Implemented; testing ongoing |
| 7 | CSV import and export | 🔄 Planned |
| 8 | Backup and restore | 🔄 Planned |
| 9 | Functional testing and UI/UX refinement | 🔄 Ongoing |
| 10 | Documentation and production preparation | 🔄 Planned |

---

## 🧪 Development & Testing

MediLink is being developed incrementally, with attention to:

- Form validation.
- Medicine and batch data consistency.
- Hive database operations.
- Customer record management.
- Payment calculations.
- Outstanding balance accuracy.
- Reactive UI updates.
- Expiry and stock alert accuracy.
- Application stability.

Static analysis is performed using:

```bash
flutter analyze
```

---

## 💻 Getting Started

### Prerequisites

- Flutter SDK.
- Dart SDK.
- Android Studio or Visual Studio Code.
- Android SDK.
- Firebase project configuration.

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/Pranay-Pandurang-Patil/medilink.git
```

**2. Navigate to the project**

```bash
cd medilink
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Configure Firebase**

Configure the required Firebase project and platform-specific authentication settings.

**5. Run the application**

```bash
flutter run
```

**Note:** This public repository is a showcase version. Selected production implementation, configuration files, and business logic are intentionally excluded. Consequently the public repository may not be independently runnable.

---

## 📌 Project Status

MediLink is actively under development.

The project has progressed from its initial Flutter foundation to medicine inventory management, customer management, daily notes, and payment tracking.

Current development is focused on improving data integrity, validating existing functionality, refining the user experience, and preparing the application for a stable release.

---

## 👨‍💻 Developer

**Pranay Patil**

Computer Science Engineering Student

GitHub: [Pranay-Pandurang-Patil](https://github.com/Pranay-Pandurang-Patil)

---

## 🤝 Contributions & Feedback

MediLink is currently a personal learning and portfolio project.

Suggestions and constructive feedback are welcome.

---

## 📜 License & Copyright

© 2026 Pranay Patil. All rights reserved.

MediLink is a proprietary portfolio project.

The public repository is provided for portfolio viewing, educational review, and project evaluation purposes.

The source code, project structure, original implementation, and assets may not be copied, redistributed, commercially reused, or used to create derivative applications without prior written permission.

See the [LICENSE](LICENSE) file for the complete terms.

> **Public Showcase Notice:**  
> This repository represents the public showcase version of MediLink. Selected production implementation, configuration files, and business logic are intentionally excluded.

---

## ⭐ Support

If you find MediLink interesting, consider giving the repository a ⭐ on GitHub.

Your support motivates continued development.
