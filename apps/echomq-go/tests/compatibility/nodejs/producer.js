// Node.js BullMQ producer for the compat_docker-tagged Go integration test
// (apps/echomq-go/tests/integration/nodejs_compat_docker_test.go).
//
// Behavior:
//   1. Connect to Redis at REDIS_HOST:REDIS_PORT (default redis:6379).
//   2. Enqueue a single job named "send-welcome-email" onto QUEUE_NAME
//      (default "compat-docker-queue").
//   3. Print "PRODUCED_JOB_ID=<id>" on stdout (Go test parses this).
//   4. Disconnect cleanly and exit 0 on success.
//
// BullMQ version: ^5.62.0 (matches FTR-009 protocol pin).

import { Queue } from 'bullmq';

const REDIS_HOST = process.env.REDIS_HOST || 'redis';
const REDIS_PORT = parseInt(process.env.REDIS_PORT || '6379', 10);
const QUEUE_NAME = process.env.QUEUE_NAME || 'compat-docker-queue';

const queue = new Queue(QUEUE_NAME, {
  connection: { host: REDIS_HOST, port: REDIS_PORT },
});

try {
  const job = await queue.add(
    'send-welcome-email',
    { to: 'compat@example.com', subject: 'Hello from Node.js BullMQ' },
    { attempts: 1 }
  );
  // eslint-disable-next-line no-console
  console.log(`PRODUCED_JOB_ID=${job.id}`);
} catch (err) {
  // eslint-disable-next-line no-console
  console.error(`PRODUCER_ERROR: ${err.message}`);
  process.exitCode = 1;
} finally {
  await queue.close();
}
