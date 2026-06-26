import { form, getRequestEvent } from '$app/server';
import { invalid, redirect } from '@sveltejs/kit';
import { resolve } from '$app/paths';
import { env } from '$env/dynamic/private';
import * as v from 'valibot';

export const signIn = form(
	v.object({
		user: v.pipe(v.string(), v.nonEmpty('User is required')),
		password: v.pipe(v.string(), v.nonEmpty('Password is required'))
	}),
	async ({ user, password }, issue) => {
		const res = await fetch(`${env.BACKEND_URL}/sign-in`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user, password })
		});

		if (res.status === 401) {
			invalid(issue.password('Incorrect password'));
		}

		if (!res.ok) {
			invalid('Something went wrong, please try again');
		}

		const { session } = await res.json();
		const { cookies } = getRequestEvent();
		cookies.set('limasy-auth', session, { path: '/', maxAge: 60 * 60 * 24, httpOnly: true, sameSite: 'lax' });

		redirect(303, resolve('/'));
	}
);
