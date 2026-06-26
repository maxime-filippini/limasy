import { redirect } from '@sveltejs/kit';
import { resolve as resolvePath } from '$app/paths';
import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
	if (event.route.id?.startsWith('/sign-in')) {
		return resolve(event);
	}

	const session = event.cookies.get('limasy-auth');
	if (!session) {
		redirect(303, resolvePath('/sign-in'));
	}

	return resolve(event);
};
