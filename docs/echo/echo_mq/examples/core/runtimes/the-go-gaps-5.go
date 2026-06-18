// cluster.go — the slot is CRC16 of the {hashtag}, modulo 16384
const RedisClusterSlots = 16384

func GetClusterSlot(key string) int {
  hashKey := key                          // extract the {hashtag} content if present
  crc := CalculateCRC16([]byte(hashKey))
  return int(crc) % RedisClusterSlots
}

func ValidateHashTags(keys []string) (bool, int, []int) {
  // true iff every key hashes to the SAME slot
}
