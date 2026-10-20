import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://thebonnienettles.com',
  output: 'static',
  trailingSlash: 'never',
  build: { format: 'file' },
});
