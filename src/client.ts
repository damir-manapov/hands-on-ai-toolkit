const AI_TOOLKIT_URL = process.env['AI_TOOLKIT_URL'] ?? 'http://localhost:8675';

export interface ToolkitConfig {
  baseUrl: string;
  authToken?: string;
}

export function getConfig(): ToolkitConfig {
  const authToken = process.env['AI_TOOLKIT_AUTH'];
  return {
    baseUrl: AI_TOOLKIT_URL,
    ...(authToken !== undefined ? { authToken } : {}),
  };
}

export async function fetchToolkit(path: string, options?: RequestInit): Promise<Response> {
  const config = getConfig();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options?.headers as Record<string, string>),
  };

  if (config.authToken) {
    headers['Authorization'] = `Bearer ${config.authToken}`;
  }

  return fetch(`${config.baseUrl}${path}`, {
    ...options,
    headers,
  });
}
