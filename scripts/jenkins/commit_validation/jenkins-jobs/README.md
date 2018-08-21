# Jenkinsfile CV Jobs


## Motivation

Implementing Jenkins jobs in a Jenkinsfile allows them to be treated as code -
reviewed, blamed, reverted etc. It also keeps the job configs in one place,
hopefully reducing the tendency for them to diverge in subtle ways.

## Pipeline

#### Jenkinsfile

The Pipeline defined in
`scripts/jenkins/commit_validation/jenkins-jobs/Jenkinsfile` is a Groovy
translation of `scripts/jenkins/commit_validation/single-project-gerrit` and
`scripts/jenkins/commit_validation/single-project-clang-static-analyzer`.

#### Configuration

##### Shared

The files in
`scripts/jenkins/commit_validation/jenkins-jobs/config/common/` hold the
environment variables used to configure a given job across _all_ projects.
These are the equivalent of the EnvInject parameters in the traditional
Jenkins jobs.

These files must define and return a groovy closure:

```
return {
FOO="some_value"
BAR=45
}
```

Therefore, all values must be valid Groovy literals - unquoted string-like
values will not be interpreted as strings:

```
return {
FOO=some_value // not valid if some_value is not a defined variable
BAR="bar"
BAZ=BAR // is valid as BAR has been defined
}
```

These files are expected to contain values common to all projects
(`kv_engine`, `couchstore` etc.) - for example
`scripts/jenkins/commit_validation/jenkins-jobs/config/common/ASan-UBSan.groovy`
may contain

```
return {
...
ASAN_OPTIONS="abort_on_error=true disable_coredump=0 use_madv_dontdump=1"
...
}
```

which will be applied when any `ASan-UBSan` job is run - unless overridden in
a project specific file.

[Groovy String
Interpolation](http://docs.groovy-lang.org/2.5.1/html/documentation/#_string_interpolation)
can be used in these variables in a manner very similar to Bash parameter
substitution. Any environment variable can be used.

```
return {
...
PATH="${PATH}:/usr/lib/llvm-3.9/bin/"
...
}
```


##### Project Specific

Files in `scripts/jenkins/commit_validation/jenkins-jobs/config/${JOB_NAME}/`
can be used to extend or override the values for a specific job. E.g.,

`scripts/jenkins/commit_validation/jenkins-jobs/config/kv_engine/ASan-UBSan.groovy`
will only be applied to the `ASan-UBSan` job for `kv_engine`, and can contain
variables specific to that job, e.g.,

```
return {
...
TESTS_EXCLUDE="memcached-breakpad-test-segfault|...|ep-engine-persistence-unit-tests.rocksdb"
PATH="${PATH}:/path/to/something/"
...
}
```

This would override `TESTS_EXCLUDE` (if it were set in a `common` config) and
append to the end of `PATH` (not overriding what was set in the `common`
config).

#### Job Names

Currently, the pipeline determines which config file to load based on the job
name.

The Multibranch job name must be of the following form:

```
project_name.job_name[.anything] e.g.,

kv_engine.ASan-UBSan
couchstore.threadsanitizer
```

The job name corresponds
to the config file which will be loaded:

`kv_engine.ASan-UBSan` will load
`scripts/jenkins/commit_validation/jenkins-jobs/config/common/ASan-UBSan.groovy`
and
`scripts/jenkins/commit_validation/jenkins-jobs/config/kv_engine/ASan-UBSan.groovy`,
as will `kv_engine.ASan-UBSan.some_testing_variant`.

Anything after the second `.` will be ignored; each job must have a unique
name so this permits multiple jobs for the same project and job type - for
example a test job with some changes.

```
kv_engine.ASan-UBSan.with-some-change
couchstore.threadsanitizer.DJR
```

It is noted that this is not a neat way of achieving this, but 

## Setting Up New Jobs

 - Create a new __Multibranch Pipeline__ Job
 - Set the name as described above
 - Add Branch Source, Git
     - Project Repository : `https://github.com/couchbase/build.git`
 - Build Configuration
    - Script Path:
      `scripts/jenkins/commit_validation/jenkins-jobs/Jenkinsfile`
- Scan Multibranch Pipeline Triggers
    - Periodically if not otherwise run
        - Interval : `1 Hour`

_or_, copy an existing Pipeline job

## Branches

Multibranch Pipeline jobs will create new sub-jobs for each branch in the
given repository in which the given Jenkinsfile exists. Therefore, when
branching no new jobs need to be created manually.

The jobs each scan the repository at the interval defined in their config. A
scan can also be manually triggered by clicking `Scan Multibranch Pipeline
Now` on the job page.

## Miscellaneous

- Multibranch Projects can be "disabled" by changing the Jenkinsfile path to
  anything non-existent.

- Setting the `SILENT` constant in the Jenkinsfile makes all jobs using the
  pipeline report "informational" votes to Gerrit; if a silent job fails, it
  does not cause the overall Verified vote to fail.
    - This may be useful when testing new jobs running this Jenkinsfile from a
      forked repo e.g., if the new job isn't working quite right while testing
      it won't cause every patch to receive a -1 Verification.
