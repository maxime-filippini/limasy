import { query } from '$app/server';
import { env } from '$env/dynamic/private';

export const getData = query(async () => {
	const res = await fetch(`${env.BACKEND_URL}/data`);
	if (!res.ok) throw new Error(`Backend returned ${res.status}`);
	return res.json() as Promise<{ data: number }>;
});
