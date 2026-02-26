# Security Policy

## Supported Versions

Soulmate actively supports the following versions for security updates. We strongly recommend users stay updated to the latest available version to ensure they have the latest features and security patches.

| Version | Supported          |
| ------- | ------------------ |
| 12.0.x  | :white_check_mark: |
| 11.0.x  | :white_check_mark: |
| 10.0.x  | :x:                |
| < 10.0  | :x:                |

## Security Architecture & Active Defenses

Soulmate employs several active defense mechanisms to guarantee user privacy and data security:

* **Firestore Cross-Validation Injection Protection:** All Firestore rules for chats and messages dynamically cross-validate the authenticated user against the parent conversation's participant list over the network, making unauthorized eavesdropping or message injection impossible.
* **Encrypted Local Storage:** All cached conversational metadata and offline chat histories are exclusively stored in an AES-encrypted vault powered by Android Keystore and the iOS Keychain (`flutter_secure_storage`).
* **Secure Session Wiping:** A dynamic `.deleteAll()` mechanism violently destroys the entire local encrypted key-store immediately upon sign out, ensuring zero sensitive relationship data residuals survive on shared hardware.
* **Email Verification Enforcement:** Our Authentication framework aggressively rejects login payloads from non-verified email addresses to isolate the app from spam, spoofing, and automated attacks.

## Reporting a Vulnerability

We take the security of Soulmate and our users' data very seriously. If you have discovered a security vulnerability in our application, we appreciate your help in disclosing it to us in a responsible manner.

### How to Report
Please report any suspected vulnerabilities privately to our security team via email at:
**badal.aryal@gmail.com**

Please **do not** create public GitHub issues for security vulnerabilities to prevent exploitation before a patch is available.

### What to Include in Your Report
To help us quickly address the issue, please include the following in your report:
* A detailed description of the vulnerability.
* Steps to reproduce the issue (including any necessary code snippets or payloads).
* Information on the environment where the vulnerability was observed (OS version, app version, etc.).
* Potential impact of the vulnerability.

### What to Expect
* We will acknowledge receipt of your vulnerability report within 48 hours.
* We will send you regular updates about our progress as we investigate and develop a fix.
* Once the issue is resolved and a patch is released, we will notify you.

Thank you for helping keep Soulmate secure!
