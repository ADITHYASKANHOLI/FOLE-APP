# ENGIVAULT Mobile API Specification (v1)

**Base URL:** `https://<domain>/api/mobile/v1`  
**API Version:** `v1`  
**Protocol:** HTTPS  
**Date Format:** ISO-8601 with UTC offset (`YYYY-MM-DDTHH:mm:ss.sssZ`)  
**Timezone Rule:** Server stores and transmits timestamps in UTC. FOLE SPACE schedule and calendar presentation uses `Asia/Kolkata` (IST, UTC+05:30).

---

## 1. Global Conventions & Standards

### 1.1 Headers
- **`Accept: application/json`** (Required on all requests)
- **`Content-Type: application/json`** (Required on requests with JSON bodies)
- **`Authorization: Bearer <token>`** (Required on authenticated endpoints; accepts Supabase Student JWT or HMAC Admin Token)

### 1.2 Standard Error Response Format
All error responses return HTTP status codes in the 4xx or 5xx range with a consistent JSON schema:
```json
{
  "error": "A clear, actionable explanation of what failed.",
  "code": "MACHINE_READABLE_ERROR_CODE",
  "details": null
}
```

### 1.3 Standard HTTP Status Codes
| Status | Meaning | Usage |
|---|---|---|
| `200 OK` | Success | Read queries, successful mutations |
| `201 Created` | Resource Created | Account signup, event registration |
| `400 Bad Request` | Validation Error | Malformed body, missing fields, invalid input |
| `401 Unauthorized` | Authentication Required | Missing, invalid, or expired Bearer token |
| `403 Forbidden` | Access Denied | Authenticated user lacks required permission/role |
| `404 Not Found` | Not Found | Target resource ID or slug does not exist |
| `409 Conflict` | Business Conflict | Already checked in, event full, duplicate username |
| `429 Too Many Requests`| Rate Limited | Exceeded request quota; includes `Retry-After` header |
| `500 Server Error` | Unexpected Failure | Uncaught server exception |
| `503 Unavailable` | Schema / System Unready | FOLE SPACE database setup uninitialized |

### 1.4 Standard Pagination Envelope
Endpoints supporting pagination accept query parameters:
- `page`: 1-based integer (default: `1`)
- `limit`: items per page (default: `20`, max: `50`)

Paginated responses contain:
```json
{
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total_count": 48,
    "total_pages": 3,
    "has_next": true,
    "has_prev": false
  }
}
```

---

## 2. Public Academic Endpoints

### 2.1 Home Composite Feed
* **`GET /home`**
* **Auth:** Optional / Public
* **Cache-Control:** `public, s-maxage=30, stale-while-revalidate=60`
* **Response (200 OK):**
```json
{
  "site": {
    "site_name": "ENGIVAULT",
    "tagline": "KTU Learning. Simplified.",
    "maintenance_mode": false,
    "announcement": null
  },
  "departments": [
    {
      "id": "dep-cse-001",
      "name": "Computer Science & Engineering",
      "code": "CSE",
      "slug": "computer-science",
      "display_order": 1
    }
  ],
  "featured_subjects": [
    {
      "id": "sub-mat203",
      "title": "Discrete Mathematical Structures",
      "code": "MAT 203",
      "slug": "discrete-mathematical-structures",
      "short_description": "Sets, logic, graphs and combinatorics.",
      "semester_number": 3,
      "modules_count": 5,
      "lessons_count": 24,
      "materials_count": 6
    }
  ],
  "latest_lectures": [
    {
      "id": "lec-001",
      "title": "Equivalence Relations and Partitions",
      "slug": "equivalence-relations-and-partitions",
      "subject_title": "Discrete Mathematical Structures",
      "subject_slug": "discrete-mathematical-structures",
      "module_title": "Module 1 - Sets and Logic",
      "module_slug": "module-1-sets-and-logic",
      "youtube_video_id": "dQw4w9WgXcQ",
      "duration_seconds": 2740,
      "instructor": "Dr. Sarah Ahmed"
    }
  ],
  "space_status": {
    "is_open": true,
    "capacity": 30,
    "current_occupancy": 12,
    "available_seats": 18
  }
}
```

---

### 2.2 Departments & Semesters
* **`GET /departments`**
  - **Auth:** Public
  - **Response (200 OK):**
    ```json
    {
      "departments": [
        {
          "id": "dep-cse-001",
          "name": "Computer Science & Engineering",
          "code": "CSE",
          "slug": "computer-science",
          "description": "Software systems, algorithms, computing theory.",
          "display_order": 1
        }
      ]
    }
    ```

* **`GET /semesters`**
  - **Query Params:** `department_id` (optional string)
  - **Auth:** Public
  - **Response (200 OK):**
    ```json
    {
      "semesters": [
        {
          "id": "sem-s3",
          "number": 3,
          "title": "Semester 3 (S3)",
          "slug": "s3",
          "department_id": "dep-cse-001"
        }
      ]
    }
    ```

---

### 2.3 Subjects Catalog & Details
* **`GET /subjects`**
  - **Query Params:**
    - `department_slug` (string, optional)
    - `semester` (integer 1–8, optional)
    - `search` (string, optional)
    - `page` (integer, default: 1)
    - `limit` (integer, default: 20, max: 50)
  - **Auth:** Public
  - **Response (200 OK):**
    ```json
    {
      "data": [
        {
          "id": "sub-mat203",
          "title": "Discrete Mathematical Structures",
          "code": "MAT 203",
          "slug": "discrete-mathematical-structures",
          "short_description": "Sets, logic, graphs and combinatorics.",
          "department_id": "dep-cse-001",
          "semester_number": 3,
          "modules_count": 5,
          "lessons_count": 24,
          "materials_count": 6
        }
      ],
      "pagination": { ... }
    }
    ```

* **`GET /subjects/:slug`**
  - **Auth:** Public
  - **Response (200 OK):**
    ```json
    {
      "subject": {
        "id": "sub-mat203",
        "title": "Discrete Mathematical Structures",
        "code": "MAT 203",
        "slug": "discrete-mathematical-structures",
        "description": "Comprehensive KTU syllabus coverage with video derivations and notes.",
        "semester_number": 3,
        "modules": [
          {
            "id": "mod-01",
            "title": "Module 1 - Sets, Relations and Functions",
            "slug": "module-1-sets-relations-functions",
            "module_number": 1,
            "description": "Fundamentals of naive set theory, equivalence relations, and posets.",
            "lessons_count": 5,
            "lessons": [
              {
                "id": "lec-001",
                "title": "Equivalence Relations and Partitions",
                "slug": "equivalence-relations-partitions",
                "lesson_number": 1,
                "duration_seconds": 2740,
                "youtube_video_id": "dQw4w9WgXcQ",
                "instructor": "Dr. Sarah Ahmed"
              }
            ]
          }
        ],
        "materials": [
          {
            "id": "mat-001",
            "title": "Module 1 Handwritten Class Notes",
            "material_type": "notes",
            "original_filename": "MAT203_Mod1_Notes.pdf",
            "file_size": 3450210
          }
        ]
      }
    }
    ```

---

### 2.4 Lesson Detail & YouTube Video Player
* **`GET /lessons/:id-or-slug`**
  - **Query Params:** `subject_slug`, `module_slug` (required when querying by lesson slug)
  - **Auth:** Public
  - **Response (200 OK):**
    ```json
    {
      "lesson": {
        "id": "lec-001",
        "title": "Equivalence Relations and Partitions",
        "slug": "equivalence-relations-partitions",
        "lesson_number": 1,
        "duration_seconds": 2740,
        "description": "Formal definitions of reflexivity, symmetry, transitivity and congruence classes.",
        "youtube_video_id": "dQw4w9WgXcQ",
        "youtube_watch_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "youtube_embed_url": "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ",
        "youtube_thumbnail_url": "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
        "instructor": "Dr. Sarah Ahmed",
        "hierarchy": {
          "subject": { "id": "sub-mat203", "title": "Discrete Mathematical Structures", "slug": "discrete-mathematical-structures", "code": "MAT 203" },
          "module": { "id": "mod-01", "title": "Module 1 - Sets, Relations and Functions", "slug": "module-1-sets-relations-functions" },
          "topic": { "id": "top-01", "title": "Relations and Equivalence", "slug": "relations-equivalence" }
        },
        "materials": [
          {
            "id": "mat-001",
            "title": "Module 1 Handwritten Class Notes",
            "material_type": "notes",
            "original_filename": "MAT203_Mod1_Notes.pdf",
            "file_size": 3450210
          }
        ],
        "navigation": {
          "prev_lesson": null,
          "next_lesson": {
            "id": "lec-002",
            "title": "Partial Orderings and Hasse Diagrams",
            "slug": "partial-orderings-hasse-diagrams"
          }
        }
      }
    }
    ```

---

### 2.5 Lectures Catalog Browser
* **`GET /lectures`**
  - **Query Params:**
    - `dept`: Department slug or ID
    - `sem`: Semester number (1–8)
    - `subject`: Subject slug or ID
    - `q`: Search keyword
    - `page`, `limit`
  - **Auth:** Public
  - **Response (200 OK):** Paginated array of lecture items with subject/module context.

---

### 2.6 Study Materials Delivery
* **`GET /materials`**
  - **Query Params:** `subject_id`, `module_id`, `search`, `page`, `limit`
  - **Auth:** Public
  - **Response (200 OK):** Paginated array of material descriptors.

* **`GET /materials/:id/download`**
  - **Auth:** Public (or Student/Admin Bearer for draft verification)
  - **Response (200 OK):**
    ```json
    {
      "download_url": "https://<ref>.supabase.co/storage/v1/object/sign/engivault-materials/path.pdf?token=...",
      "expires_at": "2026-11-07T14:45:00Z",
      "filename": "MAT203_Module1_Notes.pdf",
      "file_size": 3450210,
      "mime_type": "application/pdf"
    }
    ```

---

### 2.7 Global Academic Search
* **`GET /search`**
  - **Query Params:** `q` (required string, min 1 char)
  - **Auth:** Public
  - **Response (200 OK):**
    ```json
    {
      "results": [
        {
          "id": "sub-mat203",
          "type": "subject",
          "title": "Discrete Mathematical Structures (MAT 203)",
          "slug": "discrete-mathematical-structures",
          "code": "MAT 203",
          "breadcrumbs": ["Computer Science", "S3"]
        },
        {
          "id": "lec-001",
          "type": "lesson",
          "title": "Equivalence Relations and Partitions",
          "slug": "equivalence-relations-partitions",
          "subject_slug": "discrete-mathematical-structures",
          "module_slug": "module-1-sets-relations-functions",
          "breadcrumbs": ["MAT 203", "Module 1"]
        }
      ]
    }
    ```

---

### 2.8 FOLE WORKS Activities
* **`GET /fole-works`**
  - **Auth:** Public
  - **Response (200 OK):**
    ```json
    {
      "activities": [
        {
          "id": "w-01",
          "title": "Full-Stack Flutter & Supabase Masterclass",
          "slug": "flutter-supabase-masterclass",
          "short_description": "Build high-performance mobile apps with backend auth and realtime sync.",
          "start_date": "2026-11-15T09:30:00Z",
          "end_date": "2026-11-15T16:30:00Z",
          "venue": "FOLE SPACE Main Lab & Online",
          "fee": "Free",
          "registration_url": "https://forms.gle/sample",
          "flyer_url": "/api/fole-works/flutter-supabase-masterclass/flyer",
          "status": "upcoming"
        }
      ]
    }
    ```

* **`GET /fole-works/:slug`**
  - Returns detailed activity specification with supporting syllabus resources.

---

## 3. Student Authentication Endpoints

### 3.1 Student Login
* **`POST /auth/login`**
* **Auth:** None (Public)
* **Rate Limit:** 6 attempts / 15 minutes per IP and username
* **Request Body:**
  ```json
  {
    "username": "adithyan_k",
    "password": "StrongPassword123!"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "user": {
      "id": "u1b2c3d4-...",
      "username": "adithyan_k",
      "display_name": "adithyan_k"
    },
    "session": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "refresh_token_...",
      "expires_in": 3600,
      "expires_at": 1794060000
    }
  }
  ```
* **Errors:**
  - `401 Unauthorized`: `{ "error": "Invalid username or password.", "code": "INVALID_CREDENTIALS" }`
  - `429 Too Many Requests`: `{ "error": "Too many login attempts. Please wait.", "code": "RATE_LIMITED" }`

---

### 3.2 Student Registration
* **`POST /auth/signup`**
* **Auth:** None (Public)
* **Rate Limit:** 3 attempts / 15 minutes per IP
* **Request Body:**
  ```json
  {
    "username": "adithyan_k",
    "password": "StrongPassword123!"
  }
  ```
* **Response (201 Created):**
  Same response structure as `/auth/login` (auto-issues session tokens).
* **Errors:**
  - `400 Bad Request`: `{ "error": "Username must be 3-20 alphanumeric characters.", "code": "INVALID_USERNAME" }`
  - `409 Conflict`: `{ "error": "This username is already taken.", "code": "USERNAME_TAKEN" }`

---

### 3.3 Session Refresh
* **`POST /auth/refresh`**
* **Auth:** None
* **Request Body:**
  ```json
  {
    "refresh_token": "refresh_token_..."
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "session": {
      "access_token": "new_access_token_...",
      "refresh_token": "new_refresh_token_...",
      "expires_in": 3600,
      "expires_at": 1794063600
    }
  }
  ```

---

### 3.4 Student Profile & Password
* **`GET /auth/me`**
  - **Auth:** Student Bearer Token
  - **Response (200 OK):** Returns user profile, username, organizer flag, and registration date.

* **`POST /auth/change-password`**
  - **Auth:** Student Bearer Token
  - **Request Body:** `{ "current_password": "...", "new_password": "..." }`
  - **Response (200 OK):** `{ "success": true, "message": "Password updated successfully." }`

* **`POST /auth/logout`**
  - **Auth:** Student Bearer Token
  - **Response (200 OK):** `{ "success": true, "message": "Logged out." }`

---

## 4. FOLE SPACE Endpoints

### 4.1 Space Status & Walk-in Sessions
* **`GET /fole-space/status`**
  - **Auth:** Optional / Student Bearer (if authenticated, returns user's active session)
  - **Response (200 OK):**
    ```json
    {
      "is_open": true,
      "capacity": 30,
      "current_occupancy": 12,
      "available_seats": 18,
      "opening_hours": {
        "monday": { "open": "09:00", "close": "18:00", "closed": false }
      },
      "server_now": "2026-11-07T14:15:30Z",
      "user_active_session": null
    }
    ```

* **`POST /fole-space/checkin`**
  - **Auth:** Student Bearer Token
  - **Rate Limit:** 10 requests / 5 minutes
  - **Response (200 OK):**
    ```json
    {
      "success": true,
      "session": {
        "id": "sess-01",
        "started_at": "2026-11-07T14:15:30Z",
        "expires_at": "2026-11-07T14:45:30Z",
        "status": "active"
      },
      "server_now": "2026-11-07T14:15:30Z"
    }
    ```
  - **Errors:**
    - `409 Conflict`: `{ "error": "FOLE SPACE is currently at maximum capacity.", "code": "CAPACITY_FULL" }`
    - `409 Conflict`: `{ "error": "You already have an active study pass.", "code": "ACTIVE_SESSION_EXISTS" }`

* **`POST /fole-space/checkout`**
  - **Auth:** Student Bearer Token
  - **Response (200 OK):** `{ "success": true, "message": "Checked out successfully." }`

* **`POST /fole-space/extend`**
  - **Auth:** Student Bearer Token
  - **Response (200 OK):** Returns updated session with new `expires_at`.

---

### 4.2 Events & Digital Passes
* **`GET /fole-space/events`**
  - **Query Params:** `category`, `month` (`YYYY-MM`), `limit`
  - **Auth:** Optional / Student Bearer (enriches with user's registration status)
  - **Response (200 OK):**
    ```json
    {
      "events": [
        {
          "id": "ev-01",
          "title": "Competitive Programming & Graph Algorithms",
          "slug": "competitive-programming-graphs",
          "starts_at": "2026-11-12T10:00:00Z",
          "ends_at": "2026-11-12T13:00:00Z",
          "capacity": 25,
          "registered_count": 14,
          "status": "published",
          "allow_virtual_checkin": false,
          "user_registration": null
        }
      ]
    }
    ```

* **`POST /fole-space/events/:id/register`**
  - **Auth:** Student Bearer Token
  - **Response (201 Created):**
    ```json
    {
      "success": true,
      "registration": {
        "id": "reg-01",
        "event_id": "ev-01",
        "ticket_code": "FS1.aB3_x9Z0-123456",
        "status": "registered",
        "registered_at": "2026-11-07T14:20:00Z"
      }
    }
    ```

* **`POST /fole-space/events/:id/cancel`**
  - **Auth:** Student Bearer Token
  - **Response (200 OK):** `{ "success": true, "message": "Registration cancelled." }`

* **`POST /fole-space/events/:id/checkin/virtual`**
  - **Auth:** Student Bearer Token (Virtual check-in allowed only when session is marked `live`)
  - **Response (200 OK):** `{ "success": true, "message": "Check-in verified!" }`

* **`GET /fole-space/my`**
  - **Auth:** Student Bearer Token
  - **Response (200 OK):**
    ```json
    {
      "active_session": null,
      "upcoming_registrations": [
        {
          "registration_id": "reg-01",
          "event_id": "ev-01",
          "event_title": "Competitive Programming & Graph Algorithms",
          "starts_at": "2026-11-12T10:00:00Z",
          "ends_at": "2026-11-12T13:00:00Z",
          "ticket_code": "FS1.aB3_x9Z0-123456",
          "status": "registered",
          "event_status": "published"
        }
      ],
      "history": [ ... ]
    }
    ```

---

## 5. Organizer Check-In Desk Endpoints

All organizer endpoints require a verified organizer Bearer token (`isOrganizer === true` in `space_organizers`).

### 5.1 Event Desk Data
* **`GET /organizer/events`**
  - **Auth:** Organizer Bearer Token
  - **Response (200 OK):** List of events owned by caller.

* **`GET /organizer/events/:id/desk`**
  - **Auth:** Organizer Bearer Token (must own event or be admin)
  - **Response (200 OK):**
    ```json
    {
      "event": {
        "id": "ev-01",
        "title": "Competitive Programming & Graph Algorithms",
        "status": "live",
        "starts_at": "2026-11-12T10:00:00Z",
        "ends_at": "2026-11-12T13:00:00Z",
        "capacity": 25,
        "allow_virtual_checkin": true
      },
      "stats": {
        "registered": 18,
        "checked_in": 12,
        "virtual_checked_in": 3
      },
      "attendees": [
        {
          "registration_id": "reg-01",
          "student_id": "u1",
          "username": "adithyan_k",
          "display_name": "Adithyan K",
          "ticket_code": "FS1.aB3_x9Z0-123456",
          "is_checked_in": true,
          "checked_in_at": "2026-11-12T10:05:00Z",
          "checkin_method": "qr",
          "checkin_id": "chk-01"
        }
      ]
    }
    ```

---

### 5.2 Attendance Check-in Mutations
* **`POST /organizer/events/:id/checkin/qr`**
  - **Auth:** Organizer Bearer Token
  - **Rate Limit:** 30 scans / minute
  - **Request Body:** `{ "qr_payload": "FS1.aB3_x9Z0-123456" }`
  - **Response (200 OK):**
    ```json
    {
      "success": true,
      "checkin": {
        "id": "chk-01",
        "registration_id": "reg-01",
        "student_username": "adithyan_k",
        "checkin_time": "2026-11-12T10:05:00Z",
        "method": "qr"
      },
      "message": "Check-in confirmed!"
    }
    ```
  - **Errors:**
    - `400 Bad Request`: `{ "error": "This attendee has already checked in.", "code": "ALREADY_CHECKED_IN" }`
    - `400 Bad Request`: `{ "error": "Ticket does not belong to this event.", "code": "INVALID_TICKET" }`
    - `400 Bad Request`: `{ "error": "Event is not currently live.", "code": "EVENT_NOT_LIVE" }`

* **`POST /organizer/events/:id/checkin/manual`**
  - **Auth:** Organizer Bearer Token
  - **Request Body:** `{ "registration_id": "reg-01" }`
  - **Response (200 OK):** Same as QR check-in with `method: "manual"`.

* **`DELETE /organizer/events/:id/checkin/:checkinId`**
  - **Auth:** Organizer Bearer Token
  - **Response (200 OK):** `{ "success": true, "message": "Check-in revoked." }`

* **`POST /organizer/events/:id/status`**
  - **Auth:** Organizer Bearer Token
  - **Request Body:** `{ "action": "live" | "end" | "publish" | "unpublish" | "cancel" }`
  - **Response (200 OK):** `{ "success": true, "status": "live" }`

---

## 6. Administrator Mobile Authentication Endpoint

* **`POST /admin/login`**
  - **Auth:** None (HTTPS only)
  - **Rate Limit:** 6 attempts / 15 minutes
  - **Request Body:** `{ "code": "..." }`
  - **Response (200 OK):**
    ```json
    {
      "success": true,
      "token": "eyJyb2xlIjoiYWRtaW4iLCJpYXQiOjE3OTQwNjAwMDAsImV4cCI6MTc5NDA4ODgwMCwianRpIjoiLi4uIn0....",
      "expires_in": 28800
    }
    ```
  - **Errors:**
    - `401 Unauthorized`: `{ "error": "Invalid administrator access code.", "code": "INVALID_ADMIN_CODE" }`

