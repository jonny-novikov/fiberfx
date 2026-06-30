/**
 * The adapter between a handler's Result and a Fastify reply. Expected outcomes
 * (a missing row, a bad id) are values on the error arm; truly exceptional
 * failures throw and become a 500. The success arm is returned so Fastify
 * serializes it through the route's response schema.
 */
import type { FastifyReply } from "fastify";
import type { Result } from "@echo/core";

export interface ApiError {
  status: number;
  message: string;
}

export const notFound = (message: string): ApiError => ({ status: 404, message });
export const badRequest = (message: string): ApiError => ({ status: 400, message });

export async function send<T>(
  reply: FastifyReply,
  result: Result<T, ApiError>,
): Promise<T | FastifyReply> {
  return result.match(
    (value) => value,
    (e) => reply.code(e.status).send({ error: e.message }),
  );
}
