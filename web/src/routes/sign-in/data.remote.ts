import { form } from '$app/server';
import { invalid, redirect } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';
import * as v from 'valibot';

export const signIn = form(
	v.object({ password: v.pipe(v.string(), v.nonEmpty('Password is required')) }),
	async ({ password }, issue) => {
		const res = await fetch(`${env.BACKEND_URL}/sign-in`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(password)
		});

		if (res.status === 401) {
			invalid(issue.password('Incorrect password'));
		}

		if (!res.ok) {
			invalid('Something went wrong, please try again');
		}

		redirect(303, '/');
	}
);
