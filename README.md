[![Build Status](https://travis-ci.org/cloudfoundry-incubator/pat.svg?branch=master)](https://travis-ci.org/cloudfoundry-incubator/pat)

PAT (Performance Acceptance Tests)
==================================
The goal of this project is to create a super-simple load generation/performance testing framework for quickly
and easily running load against Cloud Foundry. The tool has both a command line UI, for running quickly during
a build and a web UI for tracking longer-running tests.

This fork is specifically to support performance testing of CF on vSphere. The modifications we've made to get it working introduce some quirks, only some of which are covered here - the particular details of how this should be used are in the test plan this fork was created to support.

Clone and Setting up to run locally
==================================
These steps are to setup this project and have it run locally on your system. This includes a number of
requirements for Go and the dependent libraries. This fork requires a bit of a git/go hack to get running, or at least I am not clever/leisured enough to make it work without said hack.

1) Ensure that [Go](http://golang.org/) version 1.2.x-64bit has been installed on the system

2) Setup the GOPATH

    export GOPATH=~/go
    export PATH=$GOPATH/bin:$PATH

3) Install [gocart](https://github.com/vito/gocart)

    go get github.com/vito/gocart

4) Download PAT and install the necessary dependencies


    go get github.com/cloudfoundry-incubator/pat
      *(Ignore any warnings about "no buildable Go source files")
      *(Ignore errors in src/github.com/cloudfoundry-incubator/pat/workloads/gcf.go")
    cd $GOPATH/src/github.com/cloudfoundry-incubator/pat
    gocart

5) Now the hack: convert your PAT to this fork (you might have to be sort of `--force`ful with the pull if it doesn't work on the first try):
    
```
git remote set-url origin git@github.com:pivotal-cf-experimental/pat
git pull
```

6) Install the [CF CLI](https://github.com/cloudfoundry/cli). (Follow the link for instructions.)

7) Symlink the cf cli as `gcf` from somewhere on your path. I have to look the syntax up every time, so here's a little reminder:
`ln -s /path/to/file /path/to/symlink`.

Running PAT
=================================

## Running with the included script
This fork includes a simple bash script, `set-and-run-PATs.sh`, that handles the `cf` logistics - creating a valid destination, ensuring an adequite quota, and cleaning up after the run. 

1) It expects a local binary, so after you've done the go setup above, do a `go build`. If you have to tinker with the source code, make sure to `go build` after, which will replace the `pat` binary the script uses. This script - and in fact, this entire tool - is location sensitive. Don't move it, and don't run the script from anywhere but this directory. If you do, it will fail to find its assets and possibly silently spew `output/csvs` directories in your PWD, which is rude.

2) set PATUSER to "admin" and PATPSWD to the password from the credentials tab of Ops Manager.

3) Make sure your config file is setup for your run. (`local-config.yml` is a good basis to build from.)

4) Run PATs!

```
./set-and-run-PATs.sh '<your api here>' local-config.yml
```

5) Collect output - output lands in the output/csvs dir as a procedurally named csv file. This directory cannot tolerate the presence of other files, so if you want to rename your output, move it somewhere else.

## Running Manually

1) Go through the "Setting up PAT to run locally" section

2) Make sure that you have targeted a Cloud Foundry environment using the gcf tool

    gcf login


3) Change into the top level of this project

    cd $GOPATH/src/github.com/cloudfoundry-incubator/pat

4) Execute the command line

    go run main.go -workload=gcf:push


### Example command-line usage (using a compiled binary from `go build` to illustrate):

    pat -h   # will output all of the command line options if installed the recommended way

    pat -concurrency=5 -iterations=5  # This will start 5 concurrent threads all pushing 1 application

    pat -concurrency=5 -iterations=1  # This will only spawn a single concurrent thread instead of the 5 you requested because you are only pushing a single application

    pat -concurrency=1..5 -concurrency:timeBetweenSteps=10  -iterations=5 # This will ramp from 1 to 5 workers, adding a worker every 10 seconds.

    pat -silent  # If you don't want all the fancy output to be shown (results can be found in a CSV)

    pat -list-workloads  # Lists the available workloads

    pat -workload=gcf:push,gcf:push,..  # Select the workload operations you want to run (See "Workload options" below)

    pat -workload=dummy  # Run the tool with a dummy operation (not against a CF environment)

    pat -config=config/template.yml  # Include a configuration template specifying any number of command line arguments. (See "Using a Configuration file" section below).

    pat -rest:target=http://api.xyz.abc.net \
        -rest:username=testuser1@xyz.com \
        -rest:password=PASSWORD \
        -rest:space=xyz_space  \
        -workload=rest:target,rest:login,rest:push,rest:push \
        -concurrency=5 -iterations=20 -interval=10 # Use the REST API to make operation requests instead of gcf

### Workload options
The `workload` option specified a comma-separated list of workloads to be used in the test.
The following options are available:

- `rest:target` - sets the CF target. Mandatory to include before any other rest operations are listed.
- `rest:login` - performs a login to the REST api. This option requires `rest:target` to be included in the list of workloads.
- `rest:push` - pushes a simple Ruby application using the REST api. This option requires both `rest:target` and `rest:login` to be included in the list of workloads.
- `gcf:push` - pushes a simple Ruby application using the CF command-line
- `gcf:spring` - pushes the spring-music app. The app paramaters can be modified by changing its manifest.yml.
- `dummy` - an empty workload that can be used when a CF environment is not available.
- `dummyWithErrors` - an empty workload that generates errors. This can be used when a CF environment is not available.

### Required arguments
Certain `workload` options require one or more arguments to be defined
The following are a list of arguments

- `-rest:target` - The Cloud Foundry URL PAT should target to. Mandatory if workload option `rest:target` is used.
- `-rest:username` - Username for workload option `rest:login`. PAT supports multi credentials, for example, if you supply  `-rest:username=user1,user2,user3`, PAT will loop through the list and use a different credential at each iteration. This argument is mandatory for workload option `rest:login`.
- `-rest:password` - Similar to `-rest:username`, used to define the password for workload option `rest:login`.

Using Redis to create a cluster of PAT workers
=====================================

Pat supports shipping workload to multiple instances using redis. This simple example starts four pat instances on the local computer which all communicate to run a workload.

    cd $GOPATH/src/github.com/cloudfoundry-incubator/pat
    redis-server redis/redis.conf # start up with in-memory only db config, good for testing, replace with a real config and change ports for real use
    VCAP_APP_PORT=8080 go run main.go -use-redis-worker=true -server -redis-port=63798 -redis-host=127.0.0.1 -redis-password=p4ssw0rd -use-redis-store # instance 1
    VCAP_APP_PORT=8081 go run main.go -use-redis-worker=true -server -redis-port=63798 -redis-host=127.0.0.1 -redis-password=p4ssw0rd -use-redis-store # instance 2
    VCAP_APP_PORT=8082 go run main.go -use-redis-worker=true -server -redis-port=63798 -redis-host=127.0.0.1 -redis-password=p4ssw0rd -use-redis-store # instance 3
    VCAP_APP_PORT=8083 go run main.go -use-redis-worker=true -server -redis-port=63798 -redis-host=127.0.0.1 -redis-password=p4ssw0rd -use-redis-store # instance 4


Using a Configuration file
=====================================
PAT offers the ability to configure your command line arguments using a configuration file. There is an example in the root of the project
directory called config-template.yml, but I recommend you look at the stripped down local-config.yml instead. To use your own custom yaml configuration file, provide the path to the configuration file. Any setting specified as a command line argument overrides the equivalent setting contained in the config file.

Example:

    pat -config=config-template.yml -iterations=2 # set iterations to 2 overriding whatever the config file says

Error Codes
=====================================
In the event of an error during execution, the text of the error along with an error code will be returned to the user. Codes are as follows:

    10: Error parsing input
    20: Error in executing the workload

Contributing
===================================
To contribute to this project, you will first need to go through the "Setting up PAT to run locally" section. This
project will be maintained through the use of standard pull requests. When issuing a pull request, make sure to
include sufficient testing through the ginkgo package (see below) to go along with any code changes. The tests
should document functionality and provide an example of how to use it.

1) Go through the "Setting up PAT to run locally" section

2) Install [ginkgo] (http://onsi.github.io/ginkgo/#getting_ginkgo)

        go install github.com/onsi/ginkgo/ginkgo

3) Write and test your code following the ginkgo standards

4) Install Prerequisites:

 - *Redis*: e.g. `brew install redis` (using [HomeBrew](https://github.com/Homebrew/homebrew) on OSX)

5) Run all tests within the repository (note: this hacky fork hasn't actually ever had these tests run, so they might not pass)

        ginkgo -r

Known Limitations / TODOs etc.
=====================================
 - Numerous :)
 - Unlikely to support Windows/Internet Explorer (certainly hasn't been tested on them)
 - Current feature set is a first-pass to get to something useful, contributions very welcome
 - Lots of stuff kept in memory and not flushed out
 - Creates lots of apps, does not delete them. We normally make sure we're targetted at a 'pats' space and just cf delete-space the space after to get rid of everything.
 - Only supports basic operations so far (push via gcf, target + login + push via rest api)
 - GCF workloads assume single already-logged-in-and-targetted user
 - Some of the features in the example configuration just don't work.

