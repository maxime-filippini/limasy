import { redirect } from '@sveltejs/kit';
import { base } from '$app/paths';
import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
	if (event.url.pathname.startsWith(`${base}/sign-in`)) {
		return resolve(event);
	}

	const session = event.cookies.get('limasy-auth');
	if (!session) {
		redirect(303, `${base}/sign-in`);
	}

	return resolve(event);
};
