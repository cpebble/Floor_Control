const tests = {
  "Test making and deleting rooms": [
    ["/groups/test1", "DELETE", 404],
    ["/groups/test1", "POST", 201],
    ["/groups/test1", "DELETE", 200 ],
  ],
  "Test simple holding and releasing": [
    ["/groups/general/floor", "POST", 200, {"userId": "alice"}],
    ["/groups/general/floor/alice", "DELETE", 200],
    ["/groups/general/floor", "POST", 200, {"userId": "bob"}],
    ["/groups/general/floor", "POST", 200, {"userId": "bob"}],
    ["/groups/general/floor/bob", "DELETE", 200, {}]
  ],
  "Test user cannnot take room they aren't holding": [
    ["/groups/general/floor", "POST", 200, {"userId": "alice"}],
    ["/groups/general/floor", "POST", 409, {"userId": "bob"}],
    ["/groups/general/floor/bob", "DELETE", 403],
    ["/groups/general/floor/alice", "DELETE", 200],
    ["/groups/general/floor", "POST", 200, {"userId": "bob"}],
    ["/groups/general/floor/bob", "DELETE", 200, {}]
  ],
  "Test user take room with priority": [
    ["/groups/general/floor", "POST", 200, {"userId": "alice"}],
    ["/groups/general/floor", "POST", 200, {"userId": "bob", "priority": 10}],
    ["/groups/general/floor", "POST", 409, {"userId": "alice", "priority": 5}],
    ["/groups/general/floor/bob", "DELETE", 200],
  ]
}


const headers = {
  "Content-Type" : "application/json",
  "Accept" : "application/json"
};

async function makereq(url, opts) {
  let req = await fetch(url, opts);
  let body = await req.clone().json().catch(() => req.clone().text());
  return [ req, req.status, body ]
}

async function makepost(url, body) {
  let [resp, resp_status, resp_body] = await makereq(
      url, {method : "POST", headers : headers, body : JSON.stringify(body)});
  console.log(resp_status, resp_body);
}
async function makedelete(url, body) {
  let [resp, resp_status, resp_body] = await makereq(
      url, {method : "DELETE", headers : headers, body : JSON.stringify(body)});
  console.log(resp_status, resp_body);

}

async function assert_response(url = "http://localhost:4000", path, method, status, body = {}) {
  let resp, resp_status, resp_body;
  if (method != "GET") {
    [resp, resp_status, resp_body] = await makereq(url + path, {
      method: method,
      body: JSON.stringify(body),
      headers: headers
    });
  } else {
    [resp, resp_status, resp_body] = await makereq(url + path, {
      method: method,
      headers: headers
    });
  }
  if (resp_status != status) {
    throw new Error(`Error in ${path}: should be ${status} but was ${resp_status}. Body is ${JSON.stringify(resp_body)}`)
  }
}

async function run_tests(url) {
  // Ensure general exists since we're using it
  await assert_response(url, "/groups/general", "POST", 201, {}).catch(()=>{});
  let was_errors = false;
  for (let test in tests) {
    console.log(`Running test: ${test}`);
    let output = [];
    for (const t_args of tests[test]) {
      try {
        await assert_response(url, ...t_args);
        output.push(`${t_args[0]} - ${t_args[1]} - ${t_args[2]}`);
      }
      catch (e) {
        was_errors = true;
        output.push(e.message);
        for (const s of output){
          console.error(s);
        }
        break
      }
    }
  }
  if (was_errors) {
    throw Error("Unsuccessful tests")
  }
}


/// This function does a manual run through of the various endpoints
async function manual_test() {
  const url = "http://localhost:4000"
  let res = await fetch(url + "/groups")
  console.log(res.status, await res.json())
      // Create new room
      await makereq(url + "/groups/general", {
        method : "POST",
        headers : headers,
      });

  // Request the newly added room
  await makereq(url + "/groups/general/floor");

  await makepost(url + "/groups/general/floor", {"userId" : "User1"});
  await makepost(url + "/groups/general/floor", {"Other" : 2});
  await makepost(url + "/groups/general/floor", {"userId" : "User2"});
  await makedelete(url + "/groups/general/floor/User1");
  // Handle requesting with priority
  await makepost(url + "/groups/general/floor", {"userId" : "User1"});
  await makepost(url + "/groups/general/floor",
                 {"userId" : "User2", "priority" : 4});
  await makereq(url + "/groups/general/floor");
  await makepost(url + "/groups/general/floor", {"userId" : "User1"});

  // Delete room
  await makedelete(url + "/groups/general")
      // Cannot obtain
      await makepost(url + "/groups/general/floor", {"userId" : "User1"});
  // Remake
  await makepost(url + "/groups/general");
  // Can obtain
  await makepost(url + "/groups/general/floor", {"userId" : "User1"});
}

const { argv } = require('node:process');
let url;
if (argv.length < 3) {
    url = "http://localhost:4000/"
} else {
    url = new URL(argv[2]);
}
run_tests(url).then(() => console.log("Ran"))
