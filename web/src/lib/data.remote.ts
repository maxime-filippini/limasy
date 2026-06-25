import { query } from '$app/server';
import { BACKEND_URL } from '$env/static/private';

export const getData = query(async () => {
	const res = await fetch(`${BACKEND_URL}/data`);
	if (!res.ok) throw new Error(`Backend returned ${res.status}`);
	return res.json() as Promise<{ data: number }>;
});
