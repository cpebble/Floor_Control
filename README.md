# Japi - it stands for Json api

This project simulates a Floor Control server, and is written in Elixir and
Phoenix.

To run the server in debug mode, use `mix phx.server`. A server will run and
listen on port 4000.

To build and run a production environment, use one of the provided docker
compose files

- `docker-compose.yml` spawns the server listening on port 80 on the host
- `docker-compose.traefik.yml` spawns the server behind an existing `traefik`
  reverse proxy

# Main components

## `Japi.Groups` /lib/japi/groups.ex

`Japi.Groups` is spawned with the server and is itself a `Supervisor`. It
contains the API for creating and working with groups, shown below.

| Function          | Description                                              |
| ----------------- | -------------------------------------------------------- |
| `start_group/1`   | Start a group with the name as parameter                 |
| `start_groups/1`  | Helper function to start multiple groups at once         |
| `delete_group/1`  | Delete a group by name                                   |
| `list_groups/0`   | Returns a list of the known groups                       |
| `get_group/1`     | Lookup a Group by name                                   |
| `check_group/1`   | A cheaper call that only checks if a group exists        |
| `hold_group/3`    | Request by a user to hold a group with optional priority |
| `release_group/2` | Request by a user to release a group                     |

Internally, the module has a few moving parts. At the bottom are `Agent`s, in
the module `Japi.Groups.Group :: Agent`. This is the low-level Group that
contains info on whether the group is being held, and at which priority.

Above that is the `Japi.Groups.Server :: GenServer`, which handles most of the
logic keeping track of which groups are currently active. It handles spawning
and destroying groups, and forwards requests to hold a floor to the relevant
group. It has an internal state, a `MapSet` of known rooms. It uses this to keep
track of which rooms exist, to allow for cheaper informational operations(ex. we
would like to know if group "general" exists without having to query the
registry or leave the process)

At the top is `Japi.Groups :: Supervisor` which spawns the aforementioned
modules, as well as a `DynamicSupervisor` and a `Registry`. It is intended to be
the interface for working with groups in case the lower-level implementation is
changed.

## `JapiWeb.GroupController` /lib/japi_web/controllers/group_controller.ex

This is the main controller for creating, querying and deleting groups. It
implements the requests found in the spec as the tag `Group Control`


## `JapiWeb.FloorController` /lib/japi_web/controllers/floor_controller.ex

This controller handles the requests to hold and release a floor, in the spec
`Floor Control`. 

The private plug `check_valid_group/2` ensures that a valid `groupId` is passed
along with every request, or terminates early. The functions `request/2` and
`release/2` handle users wanting to hold or release a given group. Note, `request/2`
passes the request along to `handle_hold_request/4`, as a cheap way to handle
priority as an optional parameter.

# Testing

Currently, there is a simple test runner in `openrooms.js`, written in
Javascript. This isn't intended as an exhaustive test suite, but to show off
how to use the API. It is also helpful when making changes, to confirm nothing
has broken.

To invoke it use

    node openrooms.js [url]

Where `url` defaults to `http://localhost:4000`. An example run looks very
boring
```
# node openrooms.js http://localhost:3000
Running test: Test making and deleting rooms
Running test: Test simple holding and releasing
Running test: Test user cannnot take room they aren't holding
Running test: Test user take room with priority
Ran
```
