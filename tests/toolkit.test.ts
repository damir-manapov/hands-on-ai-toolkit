import { describe, expect, it } from 'vitest';
import { fetchToolkit, getConfig } from '../src/index.js';

describe('AI Toolkit', () => {
  it('should have a valid config', () => {
    const config = getConfig();
    expect(config.baseUrl).toBeDefined();
    expect(config.baseUrl).toMatch(/^https?:\/\//);
  });

  it('should respond to health check', async () => {
    const response = await fetchToolkit('/');
    expect(response.ok).toBe(true);
  });
});
