import { GoogleAuthProvider, signInWithPopup, signOut } from 'firebase/auth';
import { useMemo, useState, type ReactNode } from 'react';
import { gateAuth } from '../lib/firebase';
import { Button } from './ui/button';

// This gate's own "authorized" state is tracked here, deliberately separate
// from the app's Firebase Auth user -- see gateAuth in lib/firebase.ts.
const GATE_SESSION_KEY = 'sprout_env_gate_authorized';
const GATE_EMAIL_KEY = 'sprout_env_gate_email';

const parseList = (raw: string | undefined) =>
  (raw ?? '')
    .split(',')
    .map(item => item.trim().toLowerCase())
    .filter(Boolean);

/**
 * Whether the gate applies to this build. Production (and anything without an
 * explicit non-prod marker) is never gated, and neither is a local dev server
 * -- localhost isn't a public attack surface.
 */
export function gateRequired(environment: string | undefined, hostname: string): boolean {
  if (/^(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])$/.test(hostname)) return false;
  return environment === 'staging' || environment === 'development';
}

/**
 * Whether `email` is on the allowlist. Fails closed: with no allowlist
 * configured, nobody is authorized.
 */
export function isEmailAllowed(
  email: string | null | undefined,
  allowedEmails: string[],
  allowedDomains: string[],
): boolean {
  if (!email) return false;
  const normalized = email.toLowerCase();
  if (allowedEmails.includes(normalized)) return true;
  const domain = normalized.split('@')[1];
  return Boolean(domain) && allowedDomains.includes(domain);
}

/**
 * Google Sign-In gate for the publicly reachable dev/staging deployments.
 * Ported from vehicle-vitals' EnvironmentGate.
 *
 * Configured at build time via:
 * - VITE_ENVIRONMENT: "development" | "staging" (anything else = no gate)
 * - VITE_ALLOWED_EMAILS: comma-separated exact emails
 * - VITE_ALLOWED_EMAIL_DOMAINS: comma-separated domains
 *
 * This is a UI-level gate: it keeps casual visitors out and stops the app
 * rendering, but the static bundle itself is still served. Real data
 * protection comes from Firestore/Storage rules and Auth, not from this.
 *
 * Signs in through `gateAuth`, an independent Firebase App instance the
 * app's own auth listener never observes, so passing the gate does not
 * silently log the visitor into the app.
 */
export function EnvironmentGate({ children }: { children: ReactNode }) {
  const environment = import.meta.env.VITE_ENVIRONMENT;
  const requiresAuth =
    typeof window !== 'undefined' && gateRequired(environment, window.location.hostname);

  const [authorizedEmail, setAuthorizedEmail] = useState<string | null>(() => {
    try {
      return sessionStorage.getItem(GATE_SESSION_KEY) === '1'
        ? sessionStorage.getItem(GATE_EMAIL_KEY) || ''
        : null;
    } catch {
      return null;
    }
  });
  const [error, setError] = useState('');
  const [isSigningIn, setIsSigningIn] = useState(false);

  const allowed = useMemo(
    () => ({
      emails: parseList(import.meta.env.VITE_ALLOWED_EMAILS),
      domains: parseList(import.meta.env.VITE_ALLOWED_EMAIL_DOMAINS),
    }),
    [],
  );

  if (!requiresAuth) return <>{children}</>;

  const handleSignIn = async () => {
    setError('');
    setIsSigningIn(true);
    try {
      const provider = new GoogleAuthProvider();
      provider.setCustomParameters({ prompt: 'select_account' });
      const credential = await signInWithPopup(gateAuth, provider);
      const email = credential.user.email;

      if (isEmailAllowed(email, allowed.emails, allowed.domains)) {
        try {
          sessionStorage.setItem(GATE_SESSION_KEY, '1');
          sessionStorage.setItem(GATE_EMAIL_KEY, email ?? '');
        } catch {
          // sessionStorage unavailable -- works for this render, not a reload.
        }
        setAuthorizedEmail(email ?? '');
      } else {
        setError(`Your email (${email}) is not authorized to access this environment.`);
      }
      await signOut(gateAuth).catch(() => {});
    } catch (err) {
      const e = err as { code?: string; message?: string };
      if (e.code !== 'auth/popup-closed-by-user') {
        setError(e.message || 'Failed to sign in. Please try again.');
      }
    } finally {
      setIsSigningIn(false);
    }
  };

  const handleRevoke = () => {
    try {
      sessionStorage.removeItem(GATE_SESSION_KEY);
      sessionStorage.removeItem(GATE_EMAIL_KEY);
    } catch {
      // ignore
    }
    setAuthorizedEmail(null);
  };

  if (authorizedEmail !== null) {
    return (
      <>
        {children}
        <button
          type="button"
          onClick={handleRevoke}
          title={`Team access granted to ${authorizedEmail}`}
          className="fixed bottom-4 right-4 z-50 rounded bg-ink px-3 py-2 text-xs text-on-dark shadow-lg hover:opacity-90"
        >
          {authorizedEmail} (Revoke access)
        </button>
      </>
    );
  }

  const label = environment ? environment.charAt(0).toUpperCase() + environment.slice(1) : '';

  return (
    <div className="flex min-h-dvh items-center justify-center bg-bg p-4 text-ink">
      <div className="w-full max-w-md rounded-lg border border-border bg-surface p-8 shadow-lg">
        <h1 className="mb-2 text-center text-2xl font-bold">{label} Environment</h1>
        <p className="mb-4 text-center text-sm text-muted">
          This is a restricted {environment} environment. Access is limited to authorized team
          members.
        </p>
        {error && (
          <div role="alert" className="mb-4 rounded-lg border border-danger p-3 text-sm text-danger">
            {error}
          </div>
        )}
        <Button onClick={handleSignIn} disabled={isSigningIn} className="w-full">
          {isSigningIn ? 'Signing in...' : 'Sign in with Google'}
        </Button>
      </div>
    </div>
  );
}
