/**
 * Backend API ile iletişim katmanı.
 * Tüm auth ve veri işlemleri bu modül üzerinden .NET backend'e yönlendirilir.
 */

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5057';

interface ApiResponse<T = any> {
  data: T | null;
  error: string | null;
}

async function apiRequest<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
  try {
    const res = await fetch(`${API_URL}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });

    const body = await res.json();

    if (!res.ok) {
      return { data: null, error: body.message || 'Bir hata oluştu.' };
    }

    return { data: body as T, error: null };
  } catch (err: any) {
    // Backend çalışmıyorsa bu hatayı yakala
    if (err.message === 'Failed to fetch' || err.name === 'TypeError') {
      return { data: null, error: 'Sunucuya bağlanılamadı. Backend çalışıyor mu?' };
    }
    return { data: null, error: err.message || 'Bilinmeyen bir hata oluştu.' };
  }
}

// ────────────────────── AUTH ──────────────────────

export interface LoginResponse {
  user: { id: string; email: string; fullName: string };
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface RegisterResponse {
  user: { id: string; email: string; fullName: string };
  accessToken: string;
  refreshToken: string;
  message: string;
}

export async function login(email: string, password: string): Promise<ApiResponse<LoginResponse>> {
  return apiRequest<LoginResponse>('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
}

export async function register(fullName: string, email: string, password: string): Promise<ApiResponse<RegisterResponse>> {
  return apiRequest<RegisterResponse>('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify({ fullName, email, password }),
  });
}

export async function verifyToken(token: string) {
  return apiRequest('/api/auth/verify', {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
}

export async function getProfile(userId: string) {
  return apiRequest(`/api/auth/profile?userId=${userId}`);
}

// ────────────────────── BELGELER ──────────────────────

export async function getDocuments(userId: string) {
  return apiRequest(`/api/documents?userId=${userId}`);
}

export async function getDocumentById(id: string) {
  return apiRequest(`/api/documents/${id}`);
}

// ────────────────────── RAPORLAR ──────────────────────

export async function getMonthlySummary(userId: string, year?: number) {
  const params = new URLSearchParams({ userId });
  if (year) params.set('year', year.toString());
  return apiRequest(`/api/reports/monthly-summary?${params}`);
}

export async function getCategoryBreakdown(userId: string) {
  return apiRequest(`/api/reports/category-breakdown?userId=${userId}`);
}

export default {
  login,
  register,
  verifyToken,
  getProfile,
  getDocuments,
  getDocumentById,
  getMonthlySummary,
  getCategoryBreakdown,
};
