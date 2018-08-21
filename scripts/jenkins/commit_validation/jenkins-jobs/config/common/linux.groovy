return {
CMAKE_ARGS="-DCOUCHBASE_KV_COMMIT_VALIDATION=1 -DPHOSPHOR_DISABLE=ON -DBUILD_ENTERPRISE=1"

// 2017-05-26: ubuntu16.04 machines are currently 4 cores with 8GB RAM
// - constrain parallelism so we don't swap (too much)...
PARALLELISM=6
TEST_PARALLELISM=3
TESTS_EXCLUDE="memcached-spdlogger-test"
}
