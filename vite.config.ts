import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
const apiPort = Number(process.env.API_PORT || process.env.PORT || 3001);
const webPort = Number(process.env.VITE_PORT || 5173);
export default defineConfig({ plugins: [react()], server: { host: '0.0.0.0', port: webPort, strictPort: true, proxy: { '/api': `http://localhost:${apiPort}` } } });
