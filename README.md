# physio_app

Flutter app for a physiotherapist (admin) and their patients, with a Node/Express/MongoDB backend in `backend/`.

## Run
- Backend: `cd backend && npm install`, create `.env` (`MONGODB_URI`, `JWT_SECRET`), then `npm run dev`.
  Create the first admin with `node src/scripts/createAdmin.js`.
- App: `flutter pub get && flutter run` (use `--dart-define=API_URL=http://<ip>:5000/api` on a real phone).

The API contract is in [`backend/API.md`](backend/API.md).
Offline checks: `node backend/src/scripts/testSchedule.js`.
# physiotherapy-app
