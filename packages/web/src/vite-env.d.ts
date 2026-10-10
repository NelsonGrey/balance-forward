/// <reference types="vite/client" />

interface ImportMetaEnv {
  // Access gate (EnvironmentGate): set VITE_ENVIRONMENT to "development" or
  // "staging" on publicly hosted non-prod builds to require a Google
  // sign-in from an allowlisted email. Unset/"production" = no gate.
  readonly VITE_ENVIRONMENT?: string;
  readonly VITE_ALLOWED_EMAILS?: string;
  readonly VITE_ALLOWED_EMAIL_DOMAINS?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
