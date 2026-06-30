import Fastify from "fastify";
import cors from "@fastify/cors";
import sensible from "@fastify/sensible";
import swagger from "@fastify/swagger";
import swaggerUi from "@fastify/swagger-ui";
import {
  serializerCompiler,
  validatorCompiler,
  jsonSchemaTransform,
  type ZodTypeProvider,
} from "fastify-type-provider-zod";
import dbPlugin from "./plugins/db.js";
import { routes } from "./routes/index.js";
import type { Env } from "./env.js";

/** Build the Fastify app: zod type provider, the platform plugins, and the /api routes. */
export async function buildApp(env: Env) {
  const app = Fastify({ logger: { level: env.LOG_LEVEL } }).withTypeProvider<ZodTypeProvider>();

  // zod drives both request validation and response serialization.
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  await app.register(sensible);
  await app.register(cors, { origin: true });

  await app.register(swagger, {
    openapi: { info: { title: "Codemojex API", version: "0.1.0" } },
    transform: jsonSchemaTransform,
  });
  await app.register(swaggerUi, { routePrefix: "/docs" });

  await app.register(dbPlugin, { databaseUrl: env.DATABASE_URL });
  await app.register(routes, { prefix: "/api" });

  return app;
}
