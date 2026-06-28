// typecheck_negative.ts — the measurement is the compile error.
// `npx tsc --noEmit` must report exactly one error, on the last line: a
// BrandedId<'USR'> is not assignable to BrandedId<'CRS'>. The cross-entity
// id bug — pass a user id where a course id belongs — dies in CI, before
// any process starts.
import { literal } from './branded_id.ts';
import type { BrandedId } from './branded_id.ts';

const userId: BrandedId<'USR'> = literal('USR0KHTOWnGLuC');

const courseTitle = (id: BrandedId<'CRS'>): string => `course ${id}`;

courseTitle(userId);
