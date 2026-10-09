// Fake website for uptime monitors. Switch modes with:
//   npx wrangler kv key put --binding=STATE mode <mode> --remote
// Modes: up | down | slow | flaky | eu-down | broken
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export default {
  async fetch(req, env) {
    const mode = (await env.STATE.get("mode")) || "up";
    const cf = req.cf || {};

    // Shows which tool checks from where, and how often (`npx wrangler tail`)
    console.log(JSON.stringify({ ua: req.headers.get("user-agent"), colo: cf.colo, country: cf.country, mode }));

    switch (mode) {
      case "down":
        return new Response("boom", { status: 500 });
      case "slow":
        await sleep(15000);
        break;
      case "flaky":
        if (Math.random() < 0.3) return new Response("blip", { status: 503 });
        break;
      case "eu-down":
        if (cf.continent === "EU") return new Response("regional outage", { status: 503 });
        break;
      case "broken":
        return new Response("<h1>Database connection error</h1>", { status: 200, headers: { "content-type": "text/html" } });
    }
    return new Response("<h1>OK steadyfox testbed</h1>", { status: 200, headers: { "content-type": "text/html" } });
  },

  // Cron Trigger: starts the fake job every 15 minutes (GitHub's own schedule is unreliable)
  async scheduled(event, env) {
    if (!env.GH_TOKEN) return;
    const res = await fetch("https://api.github.com/repos/cloud18dev/steadyfox-testbed/actions/workflows/fake-job.yml/dispatches", {
      method: "POST",
      headers: { authorization: `Bearer ${env.GH_TOKEN}`, accept: "application/vnd.github+json", "user-agent": "steadyfox-testbed" },
      body: JSON.stringify({ ref: "main" }),
    });
    if (!res.ok) throw new Error(`dispatch failed: ${res.status} ${await res.text()}`);
  },
};
