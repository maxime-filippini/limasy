import { fail, redirect } from '@sveltejs/kit';
import { resolve } from '$app/paths';
import { env } from '$env/dynamic/private';
import type { Actions } from './$types';

export const actions: Actions = {
	default: async ({ request, cookies }) => {
		const data = await request.formData();
		const user = data.get('user') as string | null;
		const password = data.get('password') as string | null;

		if (!user) return fail(422, { errors: { user: 'User is required' } });
		if (!password) return fail(422, { errors: { password: 'Password is required' } });

		const res = await fetch(`${env.BACKEND_URL}/sign-in`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user, password })
		});

		if (res.status === 401) {
			return fail(401, { errors: { password: 'Incorrect password' } });
		}

		if (!res.ok) {
			return fail(500, { errors: { form: 'Something went wrong, please try again' } });
		}

		const setCookieHeader = res.headers.get('set-cookie');
		if (setCookieHeader) {
			const eqIdx = setCookieHeader.indexOf('=');
			const name = setCookieHeader.slice(0, eqIdx).trim();
			const value = setCookieHeader.slice(eqIdx + 1, setCookieHeader.indexOf(';')).trim();
			cookies.set(name, value, { path: '/', maxAge: 60 * 60 * 24, httpOnly: true, sameSite: 'lax' });
		}

		redirect(303, resolve('/'));
	}
};
