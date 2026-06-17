// queue_impl.go — addJobToQueue: first command
return q.redisClient.HSet(ctx, key, fields).Err()

// queue_impl.go — enqueueJob: second, separate command
return q.redisClient.LPush(ctx, q.keyBuilder.Wait(), job.ID).Err()
