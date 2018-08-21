return {
CMAKE_ARGS="-DCOUCHBASE_KV_COMMIT_VALIDATION=1"
CMAKE_GENERATOR="Ninja"
TESTS_EXCLUDE="memcached-spdlogger-test|memcached_testapp.*.TransportProtocols/GetSetSnappyOnOffTest"
}
