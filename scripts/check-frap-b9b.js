// AGENT-NOTE: B9b receipt helper; checks the declared sticker replay and a small projected lower bound.
const crypto = require('crypto');
const fs = require('fs');
const axes = [
  [-1, 0, 0], [1, 0, 0], [0, -1, 0], [0, 1, 0], [0, 0, -1], [0, 0, 1],
];
const slots = [];
for (let x = -1; x <= 1; x++) for (let y = -1; y <= 1; y++) for (let z = -1; z <= 1; z++) {
  for (const [nx, ny, nz] of axes) {
    if ((nx && x === nx) || (ny && y === ny) || (nz && z === nz)) slots.push({p: [x, y, z], n: [nx, ny, nz]});
  }
}
const key = (s) => `${s.p.join(',')}|${s.n.join(',')}`;
const slotIndex = new Map(slots.map((s, i) => [key(s), i]));
const corners = slots.map((s, i) => (Math.abs(s.p[0]) + Math.abs(s.p[1]) + Math.abs(s.p[2]) === 3 ? i : -1)).filter(i => i >= 0);
const cornerSlots = corners;
const transform = (token, v) => {
  const [x, y, z] = v;
  if (token === 'U') return [y, -x, z];
  if (token === 'D') return [-y, x, z];
  if (token === 'R') return [x, z, -y];
  if (token === 'L') return [x, -z, y];
  if (token === 'F') return [-z, y, x];
  if (token === 'B') return [z, y, -x];
  throw new Error(`unknown face ${token}`);
};
const faceAxis = {U: [2, 1], D: [2, -1], R: [0, 1], L: [0, -1], F: [1, 1], B: [1, -1]};
const quarter = (face) => {
  const perm = Array.from({length: slots.length}, (_, i) => i);
  const [axis, side] = faceAxis[face];
  for (let i = 0; i < slots.length; i++) {
    if (slots[i].p[axis] !== side) continue;
    const p = transform(face, slots[i].p);
    const n = transform(face, slots[i].n);
    perm[slotIndex.get(key({p, n}))] = i;
  }
  return perm;
};
const compose = (a, b) => a.map((src, dest) => b[src]);
const identity = Array.from({length: slots.length}, (_, i) => i);
const power = (p, n) => { let r = identity; for (let i = 0; i < n; i++) r = compose(r, p); return r; };
const perms = {};
for (const face of Object.keys(faceAxis)) {
  const q = quarter(face);
  perms[face] = q; perms[`${face}'`] = power(q, 3); perms[`${face}2`] = power(q, 2);
}
const apply = (state, token) => compose(state, perms[token]);
const parse = (word) => word.trim().split(/\s+/).filter(Boolean);
const inverseWord = (word) => parse(word).reverse().map((t) => t.endsWith("'") ? t.slice(0, -1) : t.endsWith('2') ? t : `${t}'`);
const stateDigest = (s) => crypto.createHash('sha256').update(JSON.stringify(s)).digest('hex');
const scramble = "R U R' U' F R U R' U' F'";
const solution = inverseWord(scramble).join(' ');
let state = identity;
const scrambleTrace = [{token: 'solved', sha256: stateDigest(state)}];
for (const token of parse(scramble)) { state = apply(state, token); scrambleTrace.push({token, sha256: stateDigest(state)}); }
const scrambled = state;
const inverseTrace = [];
for (const token of parse(solution)) { state = apply(state, token); inverseTrace.push({token, sha256: stateDigest(state)}); }
if (state.some((x, i) => x !== i)) throw new Error('inverse replay did not return to solved');
const cornerKey = (s) => cornerSlots.map((i) => s[i]).join(',');
const target = cornerKey(scrambled);
const projected = new Set([cornerKey(identity)]);
let frontier = [identity];
for (let depth = 1; depth <= 2; depth++) {
  const next = [];
  for (const s of frontier) for (const token of Object.keys(perms)) {
    const t = apply(s, token); const k = cornerKey(t);
    if (!projected.has(k)) { projected.add(k); next.push(t); }
  }
  frontier = next;
}
const lowerBound = projected.has(target) ? 0 : 3;
const cornerSources = cornerSlots.map((i) => {
  const source = slots[scrambled[i]].p;
  return source.join(',');
});
const cubieSlots = (boundaryCount) => {
  const first = new Map();
  for (let i = 0; i < slots.length; i++) {
    const count = slots[i].p.filter((x) => Math.abs(x) === 1).length;
    if (count !== boundaryCount) continue;
    const p = slots[i].p.join(',');
    if (!first.has(p)) first.set(p, i);
  }
  return [...first.values()];
};
const permutationParity = (destSlots) => {
  const positions = new Map(destSlots.map((i, n) => [slots[i].p.join(','), n]));
  const perm = destSlots.map((i) => positions.get(slots[scrambled[i]].p.join(',')));
  let inversions = 0;
  for (let i = 0; i < perm.length; i++) for (let j = i + 1; j < perm.length; j++) if (perm[i] > perm[j]) inversions++;
  return {perm, sign: inversions % 2 === 0 ? 1 : -1};
};
const cornerParity = permutationParity(cubieSlots(3));
const edgeParity = permutationParity(cubieSlots(2));
const result = {
  stickerSlots: slots.length,
  cornerStickerSlots: cornerSlots.length,
  scramble,
  solution,
  scrambleTrace,
  inverseTrace,
  replaySolved: state.every((x, i) => x === i),
  projectedStatesDepthLe2: projected.size,
  cornerProjectionLowerBound: lowerBound,
  cornerPermutationSign: cornerParity.sign,
  edgePermutationSign: edgeParity.sign,
  parityConstraintChecked: cornerParity.sign === edgeParity.sign,
  cornerSources,
};

const artifactPath = process.argv[2];
if (artifactPath) {
  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
  if (JSON.stringify(artifact.replay_log) !== JSON.stringify(result)) {
    throw new Error(`replay_log mismatch: ${artifactPath}`);
  }
}
console.log(JSON.stringify(result, null, 2));
