# Attribute Standardization

## 📌 Objective
To maintain a clean and manageable identity structure by using attributes to classify users.

---

## 🧩 Attributes Used

### 1. employeeType
Used to distinguish between staff and students.

Values:
- Staff → "Staff"
- Student → "Student"

---

### 2. extensionAttribute1
Used to store the **Grade** of the student.

Example:
- 1, 2, 3, 4, 5, 6

---

### 3. extensionAttribute2
Used to store the **Division**.

Example:
- A, B, C

---

## 🎯 Why This Matters

### 1. Easy Filtering
Admins can quickly filter users based on role, grade, or division.

### 2. Automation
Scripts can use these attributes to:
- Assign groups
- Apply policies
- Generate reports

### 3. Future Use
These attributes can be used for:
- Dynamic groups
- Conditional Access policies
- License assignment automation

---

## ⚙️ Implementation

Attributes were assigned using:

- PowerShell scripts
- Microsoft Graph module

---

## 📌 Summary

Using attributes ensures that the environment is structured, scalable, and automation-ready.
