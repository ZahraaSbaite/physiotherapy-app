# Physio API contract

Base URL: `/api`. JSON in, JSON out. Every route except `POST /auth/login` needs
`Authorization: Bearer <token>`. Errors look like `{ "message": "..." }`.
Admin routes return 403 to patients, and `/me` routes return 403 to admins.
Every query is limited to the logged-in admin's own data (`adminId`), and patients only see their own records.

Dates: appointments use full ISO times (`startTime`, `endTime`). Assignment `startDate` / `endDate` are plain `YYYY-MM-DD`.
Weekdays on the server: `0` = Sunday ... `6` = Saturday.

## Scope: communication
One-to-one chat (Conversation, Message) is **not part of this version**. Communication is done with two features:
**broadcasts** (one-way announcements) and **channels** (a group the therapist posts in; members reply only if allowed).
There are no live sockets or push notifications yet: the app refreshes a channel every 20 seconds and on send.

## Patients (admin)
| Method | Path | Notes |
|---|---|---|
| GET | `/patients?search=&isActive=&page=&limit=` | `{ patients, total, page, limit }` |
| POST | `/patients` | `name`, `email`, `password` (8+), `phone?`, `dateOfBirth?`, `gender?`, `medicalNotes?` |
| GET | `/patients/:id` | includes `medicalNotes` |
| PATCH | `/patients/:id` | any of the fields above except password; `""`/`null` clears optional fields |
| POST | `/patients/:id/reset-password` | `{ newPassword }` |
| PATCH | `/patients/:id/deactivate` / `/reactivate` | no body |
| DELETE | `/patients/:id?confirm=true` | permanent |
| GET | `/patients/:id/assignments` | `{ assignments }` with progress |
| POST | `/patients/:id/assignments` | see Assignments |
| GET | `/patients/:id/completions?limit=` | `{ completions }`, newest first |

## Appointments (admin)
| Method | Path | Notes |
|---|---|---|
| GET | `/appointments?from=&to=&patientId=&status=` | `{ appointments }`, `patientId` is `{ _id, name }` |
| POST | `/appointments` | `patientId`, `startTime`, `endTime` required; `title?`, `location?`, `notes?`, `status?`, `reminderMinutesBefore?`, `payment?` |
| GET | `/appointments/:id` | `{ appointment }` |
| PATCH | `/appointments/:id` | partial; patient cannot change; `payment: null` clears it |
| DELETE | `/appointments/:id` | 409 if exercises are linked (cancel instead) |

`payment`: `{ amount?, currency?, status: unpaid|partial|paid, method?: cash|card|transfer|other, paidAmount?, note? }`.
`paid` sets `paidAmount = amount`; `unpaid` resets it to 0; `partial` needs `0 < paidAmount < amount`.
Status values: `scheduled | completed | cancelled | no_show`.

## Exercises (admin)
`GET /exercises`, `POST /exercises`, `GET|PATCH|DELETE /exercises/:id`.
Fields: `title` (required), `description`, `category`, `videoUrl`, `imageUrls[]`, `precautions`,
`defaultSets`, `defaultReps`, `defaultDurationSeconds`, `defaultRestSeconds`.
`DELETE` archives the exercise if it was ever assigned, otherwise removes it. Assignments keep their own copy.

## Assignments
`POST /patients/:id/assignments` (admin):

```json
{
  "exerciseId": "...", "appointmentId": "...", "nextAppointmentId": "...",
  "sets": 3, "reps": 10, "durationSeconds": 30, "restSeconds": 30, "instructions": "...",
  "startDate": "2026-11-23", "endDate": "2026-12-06", "totalTimes": 10,
  "repeat": { "type": "auto|daily|weekly", "daysOfWeek": [1, 3] },
  "reminderTimes": ["08:00", "18:00"]
}
```
`appointmentId`, `startDate`, `endDate`, `totalTimes` are required. Sets/reps default to the exercise's defaults.
`auto` spreads the sessions evenly over the date range, `daily` is every day, `weekly` uses `daysOfWeek`.
Each reminder time is one session per day. `totalTimes` must fit in the schedule or the request is rejected.

Response shape (list and detail): `_id`, `exercise { _id, title, description, videoUrl, imageUrls, precautions }`,
the fields above, `progress { done, total }` (the "6/10"), and for patients also `completed` (today's sessions are done).

`DELETE /assignments/:id` (admin): switches the assignment off if it has history, otherwise removes it.

## Patient (`/me`)
| Method | Path | Notes |
|---|---|---|
| GET | `/me/appointments?from=&to=` / `/me/appointments/:id` | own appointments |
| GET | `/me/assignments?date=YYYY-MM-DD` | exercises due that day |
| GET | `/me/assignments/:id` | one exercise with progress |
| POST | `/me/assignments/:id/complete` | `{ painLevel?: 0-10, patientNote?: string, date?, scheduledTime? }` → `{ completion, progress }` |
| GET | `/me/completions?limit=` | own history |

Completing twice for the same session returns 409.

## Broadcasts (admin)
| Method | Path | Notes |
|---|---|---|
| GET | `/broadcasts` | `{ broadcasts }` with `recipientCount`, `readCount` |
| POST | `/broadcasts` | `{ title?, text, audience: { type: 'all' \| 'selected', patientIds? } }`; recipients are fixed at send time (active patients only) |
| GET | `/broadcasts/:id` | adds `recipients: [{ _id, name, read }]` |
| DELETE | `/broadcasts/:id` | |

Patient: `GET /me/broadcasts` (`isRead` per item) and `POST /me/broadcasts/:id/read`.

## Channels
Admin: `GET /channels`, `POST /channels` (`name`, `description?`, `imageUrl?`, `memberIds`, `membersCanReply`),
`GET /channels/:id` (adds `members`), `PATCH /channels/:id` (any field, plus `isArchived`).
Each channel in a list has `memberCount`, `unreadCount` and `lastMessage`.

Messages, for the admin under `/channels/:id/...` and for members under `/me/channels/:id/...`:
| Method | Path | Notes |
|---|---|---|
| GET | `/messages?before=&limit=` | oldest first, `hasMore` for paging back |
| POST | `/messages` | `{ text, clientMessageId }`; sending the same `clientMessageId` again returns the first message. Members get 403 unless `membersCanReply` |
| POST | `/read` | marks everything in the channel as read for the caller |
| DELETE | `/channels/:id/messages/:messageId` | admin only; hides the text, keeps the row |

Patient: `GET /me/channels` lists the channels they are a member of.
