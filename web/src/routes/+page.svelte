<script>
	import { getData } from '$lib/data.remote';

	const result = getData();
</script>

{#if result.loading}
	<p>Loading...</p>
{:else if result.ready}
	<pre>{JSON.stringify(result.current, null, 2)}</pre>
{:else if result.error}
	<p>Error: {result.error.message}</p>
{/if}

<button onclick={() => result.refresh()}>Refresh</button>
