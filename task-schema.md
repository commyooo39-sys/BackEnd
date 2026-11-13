# SQL Server schema สำหรับ Smart Todo

Schema นี้รองรับทุกฟิลด์ของ Task ใน `smart-todo-rest-api.md` รวมถึง `description`, `priority` และ `dueDate` จาก feature spec ของเว็บ

## ตาราง schema

| คอลัมน์ SQL Server | ชนิดข้อมูล | ข้อกำหนด | ฟิลด์ใน API |
|---|---|---|---|
| `id` | `INT` | `IDENTITY(1,1)`, Primary Key, `NOT NULL` | `id` |
| `title` | `NVARCHAR(200)` | `NOT NULL`, ต้องไม่ว่าง | `title` |
| `description` | `NVARCHAR(1000)` | `NULL` ได้ | `description` |
| `priority` | `NVARCHAR(10)` | `NOT NULL`, จำกัดค่าเป็น `low`, `medium`, `high` | `priority` |
| `due_date` | `DATE` | `NOT NULL` | `dueDate` |
| `is_completed` | `BIT` | `NOT NULL`, default `0` | `isCompleted` |
| `created_at` | `DATETIME2(3)` | `NOT NULL`, default UTC | `createdAt` |
| `updated_at` | `DATETIME2(3)` | `NOT NULL`, default UTC | `updatedAt` |

`isCompleted` เป็นชื่อใน API ที่จับคู่กับ `is_completed` ในฐานข้อมูล; เว็บปัจจุบันใช้ชื่อ `completed` จึงควรแปลงชื่อในชั้นเชื่อมต่อ API

## สร้างตารางและเพิ่มข้อมูลตัวอย่าง

```sql
CREATE TABLE dbo.tasks (
    id           INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_tasks PRIMARY KEY,
    title        NVARCHAR(200) NOT NULL,
    description  NVARCHAR(1000) NULL,
    priority     NVARCHAR(10) NOT NULL,
    due_date     DATE NOT NULL,
    is_completed BIT NOT NULL
        CONSTRAINT DF_tasks_is_completed DEFAULT (0),
    created_at   DATETIME2(3) NOT NULL
        CONSTRAINT DF_tasks_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at   DATETIME2(3) NOT NULL
        CONSTRAINT DF_tasks_updated_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT CK_tasks_title_not_blank
        CHECK (LEN(LTRIM(RTRIM(title))) > 0),
    CONSTRAINT CK_tasks_priority
        CHECK (priority IN (N'low', N'medium', N'high'))
);

INSERT INTO dbo.tasks (title, description, priority, due_date, is_completed)
VALUES
    (N'อ่านหนังสือบทที่ 3', N'สรุปประเด็นสำคัญเพื่อเตรียมสอบ', N'high',   '2026-11-20', 0),
    (N'ส่งรายงาน',           NULL,                                 N'medium', '2026-11-18', 1),
    (N'นัดประชุมทีม',        N'เตรียมหัวข้อประชุม',                N'low',    '2026-11-25', 0);
```

ไม่ต้องระบุ `id` เพราะเป็น `IDENTITY`; ไม่ต้องระบุ `created_at` และ `updated_at` ตอนสร้าง เพราะ default ใช้ `SYSUTCDATETIME()` ส่วน `N` ก่อนข้อความช่วยให้ SQL Server เก็บข้อความ Unicode ได้ถูกต้อง

## แปลงชื่อ snake_case เป็น camelCase

ใช้ alias ใน `SELECT` เพื่อให้ชื่อคอลัมน์ที่ส่งกลับตรงกับ API:

```sql
SELECT
    id,
    title,
    description,
    priority,
    due_date     AS dueDate,
    is_completed AS isCompleted,
    created_at   AS createdAt,
    updated_at   AS updatedAt
FROM dbo.tasks;
```

ตัวอย่าง response:

```json
{
  "id": 1,
  "title": "อ่านหนังสือบทที่ 3",
  "description": "สรุปประเด็นสำคัญเพื่อเตรียมสอบ",
  "priority": "high",
  "dueDate": "2026-11-20",
  "isCompleted": false,
  "createdAt": "2026-11-12T00:00:00.000Z",
  "updatedAt": "2026-11-12T00:00:00.000Z"
}
```

serialize `createdAt` และ `updatedAt` เป็น ISO 8601 ใน UTC; `dueDate` ให้คงรูปแบบวันที่ `YYYY-MM-DD` โดยไม่แปลงเป็นเวลา

## การเพิ่ม `user_id` ในอนาคต

สร้างตารางผู้ใช้ก่อน แล้วเพิ่ม `user_id` ใน `dbo.tasks` โดยใช้ชนิดข้อมูลเดียวกับ primary key ของตารางผู้ใช้ และเพิ่ม Foreign Key หากมีข้อมูล tasks อยู่แล้ว ให้เพิ่มคอลัมน์เป็น nullable ชั่วคราวและกำหนดเจ้าของให้แถวเดิมก่อนเปลี่ยนเป็น `NOT NULL` เมื่อทุก task ต้องมีเจ้าของ ควรสร้างดัชนีบน `user_id` เพื่อช่วยค้นหา tasks ของผู้ใช้แต่ละคน
