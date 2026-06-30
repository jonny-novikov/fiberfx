import { buildApp } from "./app.js";
import { loadEnv } from "./env.js";

const env = loadEnv();

const app = await buildApp(env);

try {
  await app.listen({ port: env.PORT, host: env.HOST });
  app.log.info(`Codemojex API on http://${env.HOST}:${env.PORT} — docs at /docs`);
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
