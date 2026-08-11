#!/usr/bin/env node
"use strict";

const http = require("http");
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname);
const repoRoot = path.resolve(__dirname, "..");
const port = Number(process.env.PORT || 5180);

const contentTargets = [
  path.join(repoRoot, "content", "content.json"),
  path.join(repoRoot, "admin", "content", "content.json"),
  path.join(repoRoot, "LanguageRoulette", "Resources", "content", "content.json")
];

const mime = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png"
};

function send(res, status, body, type) {
  res.writeHead(status, {
    "Content-Type": type || "text/plain; charset=utf-8",
    "Cache-Control": "no-store"
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

function saveContent(rawBuffer) {
  const text = rawBuffer.toString("utf8");
  const parsed = JSON.parse(text);
  const pretty = `${JSON.stringify(parsed, null, 2)}\n`;
  contentTargets.forEach((target) => {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, pretty, "utf8");
  });
  return contentTargets;
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);

    if (req.method === "POST" && url.pathname === "/api/save-content") {
      const body = await readBody(req);
      const saved = saveContent(body);
      return send(res, 200, JSON.stringify({ ok: true, saved }), "application/json; charset=utf-8");
    }

    if (req.method !== "GET" && req.method !== "HEAD") {
      return send(res, 405, "Method not allowed");
    }

    let pathname = decodeURIComponent(url.pathname);
    if (pathname === "/") pathname = "/index.html";
    const filePath = path.normalize(path.join(root, pathname));
    if (!filePath.startsWith(root)) {
      return send(res, 403, "Forbidden");
    }
    if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      return send(res, 404, "Not found");
    }
    const ext = path.extname(filePath).toLowerCase();
    const data = fs.readFileSync(filePath);
    return send(res, 200, data, mime[ext] || "application/octet-stream");
  } catch (error) {
    return send(res, 500, error.message || "Server error");
  }
});

server.listen(port, () => {
  console.log(`Language Roulette admin running at http://localhost:${port}`);
  console.log("Save writes:");
  contentTargets.forEach((target) => console.log(` - ${target}`));
});
