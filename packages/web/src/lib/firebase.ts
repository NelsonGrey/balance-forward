import { getApp, initializeApp, type FirebaseApp } from 'firebase/app';
import { getAuth, type Auth } from 'firebase/auth';
import { FirebaseClient, type FirebaseConfig } from '@shared/firebase-utils';

// Same VITE_FIREBASE_* shape wishlist-wizard/vehicle-vitals use, so the
// existing CI secrets → env var wiring (see .github/workflows/firebase-hosting-*.yml)
// carries over unchanged.
const config: FirebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
};

export const firebaseClient = FirebaseClient.initialize(config);

// A second, fully independent Firebase App used only by EnvironmentGate (the
// dev/staging access gate). Same project config, but its own Auth instance
// and persisted session, so App.tsx's onAuthStateChanged never sees the
// gate's sign-in -- passing the gate must not log the visitor into the app.
const GATE_APP_NAME = 'bf-gate';
const gateApp: FirebaseApp = (() => {
  try {
    return getApp(GATE_APP_NAME);
  } catch {
    return initializeApp(config, GATE_APP_NAME);
  }
})();
export const gateAuth: Auth = getAuth(gateApp);

if (import.meta.env.DEV) {
  firebaseClient.connectToEmulators();
}
