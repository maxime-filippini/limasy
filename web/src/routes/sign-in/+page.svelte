<script lang="ts">
	import { signIn } from './data.remote';
</script>

<div class="flex min-h-screen items-center justify-center">
	<form {...signIn} class="flex w-full max-w-sm flex-col gap-4">
		<h1 class="text-xl font-semibold">Sign in</h1>

		<div class="flex flex-col gap-1">
			<label for="user" class="text-sm font-medium">User</label>
			<select
				id="user"
				name={signIn.fields.user.as('text').name}
				class="rounded border px-3 py-2 text-sm"
			>
				<option value="monika" selected={signIn.fields.user.as('text').value === 'monika'}
					>Monika</option
				>
				<option value="maxime" selected={signIn.fields.user.as('text').value === 'maxime'}
					>Maxime</option
				>
			</select>
			{#each signIn.fields.user.issues() as issue}
				<p class="text-sm text-red-600">{issue.message}</p>
			{/each}
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
