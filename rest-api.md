# Smart Todo REST API

API contract สำหรับเว็บ Smart Todo ที่พัฒนาด้วย Express และ SQL Server ใช้ JSON ผ่าน `/api/tasks` และคืนชื่อฟิลด์แบบ camelCase

## รูปแบบ Task

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

`isCompleted` ใน API สอดคล้องกับ `completed` ที่เว็บใช้อยู่; ฝั่งเว็บควรแปลงชื่อฟิลด์เมื่อรับหรือส่งข้อมูล

## กฎ validation

- `id`: จำนวนเต็มบวกที่สร้างโดยฐานข้อมูล ห้ามรับจาก client ใน body
- `title`: ต้องเป็น string ที่ไม่ว่างหลัง trim และยาวไม่เกิน 200 ตัวอักษร
- `description`: ไม่บังคับ; ถ้าส่งต้องเป็น string หรือ `null` และยาวไม่เกิน 1,000 ตัวอักษร
- `priority`: ต้องเป็นหนึ่งใน `low`, `medium`, `high`
- `dueDate`: ต้องเป็นวันที่จริงตามรูปแบบ `YYYY-MM-DD`
- `isCompleted`: ต้องเป็น boolean จริง (`true` หรือ `false`) ไม่รับ `"true"`, `1` หรือ `"1"`
- `createdAt` และ `updatedAt`: อ่านอย่างเดียว ห้ามรับจาก client; server กำหนดเป็นเวลา UTC และส่งออกเป็น ISO 8601
- ทุก request ที่มี body ต้องใช้ `Content-Type: application/json`

## Endpoints

### `GET /api/tasks`

ดึงรายการงาน เรียงตาม `id` จากน้อยไปมาก ไม่ต้องส่ง request body

**Query parameters ที่ไม่บังคับ**

| Parameter | ค่าที่รับ | ความหมาย |
|---|---|---|
| `q` | ข้อความ | ค้นหาใน `title` หรือ `description` แบบไม่สนตัวพิมพ์เล็ก/ใหญ่ |
| `status` | `all`, `active`, `completed` | กรองสถานะ; `active` คือ `isCompleted: false` |
| `priority` | `all`, `low`, `medium`, `high` | กรองระดับความสำคัญ |

ตัวอย่าง: `GET /api/tasks?q=สอบ&status=active&priority=high`

**Response — `200 OK`:**

```json
{
  "data": [
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
  ]
}
```

คืน `400 Bad Request` เมื่อค่า `status` หรือ `priority` ไม่อยู่ในค่าที่รองรับ

### `GET /api/tasks/:id`

ดึงงานหนึ่งรายการ ไม่ต้องส่ง request body

- `200 OK`: คืน `{ "data": { ...task } }`
- `400 Bad Request`: `id` ไม่ใช่จำนวนเต็มบวก
- `404 Not Found`: ไม่พบ task ที่มี `id` ดังกล่าว

### `POST /api/tasks`

สร้างงานใหม่

**Request:**

```json
{
  "title": "อ่านหนังสือบทที่ 3",
  "description": "สรุปประเด็นสำคัญเพื่อเตรียมสอบ",
  "priority": "high",
  "dueDate": "2026-11-20",
  "isCompleted": false
}
```

`title`, `priority` และ `dueDate` เป็นฟิลด์ที่ต้องส่ง; `description` ไม่บังคับ และ `isCompleted` ไม่บังคับ (ค่าเริ่มต้น `false`) ห้ามส่ง `id`, `createdAt` หรือ `updatedAt`

- `201 Created`: คืน `{ "data": { ...task ที่สร้างแล้ว } }` และ header `Location: /api/tasks/{id}`
- `400 Bad Request`: JSON ผิดรูปแบบ, ฟิลด์ขาด/ชนิดข้อมูลผิด หรือไม่ผ่าน validation
- `415 Unsupported Media Type`: `Content-Type` ไม่ใช่ `application/json`

### `PUT /api/tasks/:id`

แทนที่ข้อมูลที่แก้ไขได้ของ task ไม่ใช่ partial update ต้องส่ง `title` และ `isCompleted` ให้ครบทุกครั้ง รวมทั้ง `priority` และ `dueDate` ซึ่งเป็นข้อมูลที่จำเป็นของ task

**Request:**

```json
{
  "title": "อ่านหนังสือบทที่ 3 (ทบทวน)",
  "description": "สรุปบทและทำแบบฝึกหัด",
  "priority": "medium",
  "dueDate": "2026-11-21",
  "isCompleted": true
}
```

`description` ส่งเป็น string หรือ `null` ได้; หากละไว้ให้ถือว่าเป็น `null` ตามการแทนที่ทั้ง resource ห้ามส่ง `id`, `createdAt` หรือ `updatedAt`

- `200 OK`: คืน `{ "data": { ...task หลังแก้ไข } }`
- `400 Bad Request`: `id` ไม่ถูกต้อง, JSON ผิดรูปแบบ, ขาด `title`/`isCompleted`/`priority`/`dueDate` หรือไม่ผ่าน validation
- `404 Not Found`: ไม่พบ task ที่ต้องการแก้ไข
- `415 Unsupported Media Type`: `Content-Type` ไม่ใช่ `application/json`

เมื่อแก้ไขสำเร็จ server ต้องปรับ `updatedAt` เป็นเวลา UTC ปัจจุบัน โดยไม่เปลี่ยน `id` หรือ `createdAt`

### `DELETE /api/tasks/:id`

ลบงาน ไม่ต้องส่ง request body

- `204 No Content`: ลบสำเร็จ ไม่มี response body
- `400 Bad Request`: `id` ไม่ใช่จำนวนเต็มบวก
- `404 Not Found`: ไม่พบ task ที่ต้องการลบ

## รูปแบบข้อผิดพลาด

เมื่อ status มี response body ให้ใช้รูปแบบนี้:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "title must be a non-empty string of at most 200 characters"
  }
}
```

ใช้ `400` สำหรับ request/validation ที่ไม่ถูกต้อง, `404` เมื่อไม่พบ resource และ `415` เมื่อ media type ไม่รองรับ หากเกิดข้อผิดพลาดภายในให้คืน `500 Internal Server Error` โดยไม่เปิดเผยรายละเอียด SQL Server
