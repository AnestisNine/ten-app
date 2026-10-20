import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Test files share one Postgres database, so they run one at a time.
    fileParallelism: false,
    testTimeout: 30_000,
    hookTimeout: 60_000,
  },
});
