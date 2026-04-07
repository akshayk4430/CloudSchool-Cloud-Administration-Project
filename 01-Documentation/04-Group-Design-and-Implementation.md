# Group Design and Implementation

## 📌 Objective
The goal of this design is to organize users in a structured and scalable way based on real-world school requirements.

---

## 🏫 Group Strategy

Users are grouped based on:

- Grade
- Division
- Role (Student / Staff)
- Department (for staff)

---

## 🎓 Student Group Structure

### Grade-Level Groups
Each grade has a dedicated group:

- GRP-Grade-1
- GRP-Grade-2
- GRP-Grade-3
- GRP-Grade-4
- GRP-Grade-5
- GRP-Grade-6

### Division-Level Groups
Each grade is further divided into:

- A
- B
- C

Example:

- GRP-Grade-1a
- GRP-Grade-1b
- GRP-Grade-1c

This structure is repeated for all grades.

Total student groups: **24**

---

## 👨‍🏫 Staff Group Structure

### All Staff Group
- GRP-Staff-All → Contains all staff users

### Department Groups (Examples)
- GRP-Dept-IT
- GRP-Dept-Admin
- GRP-Dept-Accounts

---

## 🧠 Design Benefits

### 1. Easy Management
- Quickly target users based on grade or division

### 2. Scalability
- New grades or divisions can be added without redesign

### 3. Policy Assignment
- Policies (Teams, SharePoint, etc.) can be applied at group level

### 4. Automation Friendly
- PowerShell scripts can easily assign users to groups

---

## ⚙️ Implementation Method

All groups were created using:

- PowerShell scripts
- Microsoft Graph module

User assignments were also automated using scripts.

---

## 📌 Summary

The group structure ensures that the environment is organized, scalable, and ready for future configurations like policy assignments and access control.
