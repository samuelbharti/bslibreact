// Check that the tarball npm would publish carries what the package needs and
// nothing it should not. The entry points live in dist-npm/, which is
// gitignored and only exists after a build, so a tarball built from a fresh
// checkout without one installs cleanly and then fails to resolve for every
// user. npm does not allow replacing a published version, which is why this is
// a check of its own rather than something noticed later.
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const pkg = JSON.parse(readFileSync(new URL("../package.json", import.meta.url), "utf8"));

// Every path the package's own "exports" and "types" point at has to be in the
// tarball, read from package.json rather than restated here so the two cannot
// drift apart.
const required = new Set();
for (const entry of Object.values(pkg.exports ?? {})) {
  for (const target of Object.values(entry)) {
    if (typeof target === "string") required.add(target.replace(/^\.\//, ""));
  }
}
required.add("LICENSE");
required.add("README.md");

// Nothing that only makes sense in the repository. tests/ is the one most
// likely to be swept in by a careless "files" edit.
const forbidden = [/^tests\//, /^\.github\//, /^docs\//, /^coverage\//, /\.test\.tsx?$/];

// npm pack is the authoritative answer to "what would ship", so this asks it
// rather than reimplementing the "files" globbing. On Windows npm is a .cmd,
// which node refuses to spawn without a shell (EINVAL, from the 2024 fix for
// argument injection through batch files), so that platform gets shell: true
// and the DEP0190 warning that comes with it. Every argument here is a
// literal, so there is nothing for a shell to interpolate. CI runs Linux and
// takes the plain path.
const isWindows = process.platform === "win32";
const listed = JSON.parse(
  execFileSync(isWindows ? "npm.cmd" : "npm", ["pack", "--dry-run", "--json"], {
    encoding: "utf8",
    cwd: fileURLToPath(new URL("..", import.meta.url)),
    shell: isWindows,
  }),
);
const files = listed[0].files.map((f) => f.path);

const missing = [...required].filter((p) => !files.includes(p));
const leaked = files.filter((p) => forbidden.some((re) => re.test(p)));

for (const p of missing) console.error(`missing from the tarball: ${p}`);
for (const p of leaked) console.error(`should not be published: ${p}`);

if (missing.length || leaked.length) {
  console.error(`\n${files.length} files checked, ${missing.length} missing, ${leaked.length} leaked`);
  process.exit(1);
}

console.log(`tarball ok: ${files.length} files, every entry point present`);
