import { describe, expect, it } from 'vitest';
import { gateRequired, isEmailAllowed } from './EnvironmentGate';

describe('gateRequired', () => {
  it('gates staging and development on public hosts', () => {
    expect(gateRequired('staging', 'sprout-staging.web.app')).toBe(true);
    expect(gateRequired('development', 'sprout-dev.web.app')).toBe(true);
  });
  it('never gates production, unset, or localhost', () => {
    expect(gateRequired('production', 'sprout.example')).toBe(false);
    expect(gateRequired(undefined, 'sprout.example')).toBe(false);
    expect(gateRequired('staging', 'localhost')).toBe(false);
    expect(gateRequired('development', '127.0.0.1')).toBe(false);
  });
});

describe('isEmailAllowed', () => {
  it('fails closed with an empty allowlist', () => {
    expect(isEmailAllowed('a@b.com', [], [])).toBe(false);
  });
  it('matches exact emails and domains case-insensitively', () => {
    expect(isEmailAllowed('Mark@Example.com', ['mark@example.com'], [])).toBe(true);
    expect(isEmailAllowed('x@corp.com', [], ['corp.com'])).toBe(true);
    expect(isEmailAllowed('x@evil.com', ['mark@example.com'], ['corp.com'])).toBe(false);
  });
  it('rejects missing emails and lookalike domains', () => {
    expect(isEmailAllowed(null, ['a@b.com'], ['b.com'])).toBe(false);
    expect(isEmailAllowed('x@sub.corp.com', [], ['corp.com'])).toBe(false);
  });
});
