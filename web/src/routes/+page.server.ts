import { env } from '$env/dynamic/private';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ request }) => {
	const backendOrigin = new URL(env.BACKEND_URL).origin;
	const res = await fetch(`${env.BACKEND_URL}/data`, {
		headers: {
			cookie: request.headers.get('cookie') ?? '',
			origin: backendOrigin
		}
	});

	if (!res.ok) throw new Error(`Backend returned ${res.status}`);

	return (await res.json()) as { query_result: string[] };
};
