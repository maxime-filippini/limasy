<script lang="ts">
	let { data } = $props();
</script>

<div class="p-8">
	<h1 class="mb-4 text-xl font-semibold">Dashboard</h1>
	<pre class="rounded bg-zinc-100 p-4 text-sm">{JSON.stringify(data.query_result, null, 2)}</pre>
</div>
