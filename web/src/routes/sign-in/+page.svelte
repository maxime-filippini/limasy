<script lang="ts">
	import { signIn } from './data.remote';
</script>

<div class="flex min-h-screen items-center justify-center">
	<form {...signIn} class="flex w-full max-w-sm flex-col gap-4">
		<h1 class="text-xl font-semibold">Sign in</h1>

		<div class="flex flex-col gap-1">
			<label for="password" class="text-sm font-medium">Password</label>
			<input
				{...signIn.fields.password.as('password')}
				id="password"
				class="rounded border px-3 py-2 text-sm"
				placeholder="Enter password"
			/>
			{#each signIn.fields.password.issues() as issue}
				<p class="text-sm text-red-600">{issue.message}</p>
			{/each}
		</div>

		<button type="submit" class="rounded bg-black px-4 py-2 text-sm text-white hover:bg-zinc-800">
			Sign in
		</button>
	</form>
</div>
