const headers = {
  "Content-Type" : "application/json",
  "Accept" : "application/json"
};

async function makereq(url, opts) {
  let post = await fetch(url, opts);
  try {
    console.log(post.status, await post.clone().json());
  } catch {
    console.log(post.status, await post.clone().text());
  }
  return post;
}
async function makepost(url, body) {
  let post = await fetch(
      url, {method : "POST", headers : headers, body : JSON.stringify(body)});
  try {
    console.log(post.status, await post.clone().json());
  } catch {
    console.log(post.status, await post.clone().text());
  }
  return post;
}
async function makedelete(url, body) {
  let post = await fetch(url, {method : "DELETE", headers : headers});
  try {
    console.log(post.status, await post.clone().json());
  } catch {
    console.log(post.status, await post.clone().text());
  }
  return post;
}

async function init() {
  const url = "http://localhost:4000"
  let res = await fetch(url + "/groups")
  // let js = await res.json
  console.log(res.status, await res.json())
      // Create new room
      await makereq(url + "/groups/general", {
        method : "POST",
        headers : headers,
      });

  // Request the newly added room
  await makereq(url + "/groups/general/floor");
  await makereq(url + "/groups/generals/floor");

  await makepost(url + "/groups/general/floor", {"userId" : "User1"});
  await makepost(url + "/groups/general/floor", {"Other" : 2});
  await makepost(url + "/groups/general/floor", {"userId" : "User2"});
  await makedelete(url + "/groups/general/floor/User1");
}

init().then(() => console.log("Ran"))
