import { env } from '$env/dynamic/private';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ request }) => {
	const res = await fetch(`${env.BACKEND_URL}/data`, {
		headers: { cookie: request.headers.get('cookie') ?? '' }
	});

	if (!res.ok) throw new Error(`Backend returned ${res.status}`);

	return (await res.json()) as { query_result: string[] };
};
