const RATE_LIMIT_MS = 2_000;
const OFFLINE_MS = 30_000;
const AWAY_MS = 300_000;
const INVITE_TTL_MS = 3600_000;
const RL = new Map();

function rl(ip) {
  const n = Date.now();
  const l = RL.get(ip) || 0;
  if (n - l < RATE_LIMIT_MS) return false;
  RL.set(ip, n); return true;
}

function json(b, s = 200) {
  return new Response(JSON.stringify(b), {
    status: s,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  });
}

function err(m, s = 400) { return json({ error: m }, s); }

function opts() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,PATCH,DELETE,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}

function uuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = Math.random() * 16 | 0;
    return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
  });
}

function gid() { return 'grp_' + uuid().replace(/-/g, '').substring(0, 12); }

function genCode() {
  const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let r = '';
  for (let i = 0; i < 6; i++) r += c[Math.floor(Math.random() * c.length)];
  return r;
}

function presence(updatedAt) {
  if (!updatedAt) return 'offline';
  const age = Date.now() - new Date(updatedAt).getTime();
  if (age < OFFLINE_MS) return 'online';
  if (age < AWAY_MS) return 'away';
  return 'offline';
}

function packMember(u, l) {
  return {
    id: u.id,
    display_name: u.display_name || 'Unknown',
    avatar_url: u.avatar_url,
    latitude: l?.latitude ?? null,
    longitude: l?.longitude ?? null,
    speed: l?.speed ?? 0,
    heading: l?.heading ?? 0,
    battery: l?.battery ?? null,
    activity: l?.activity || 'Stationary',
    is_moving: !!l?.is_moving,
    presence: presence(l?.updated_at),
    last_seen: l?.updated_at ?? null,
  };
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return opts();

    const url = new URL(request.url);
    const db = env.DB;
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    const path = url.pathname;

    // ── Health ──────────────────────────
    if (path === '/health' && request.method === 'GET') {
      const { count } = await db.prepare('SELECT COUNT(*) as count FROM locations WHERE is_online = 1').first();
      return json({ status: 'ok', online: count });
    }

    // ══════════════════════════════════════
    //  USERS
    // ══════════════════════════════════════

    // POST /users/register
    if (path === '/users/register' && request.method === 'POST') {
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { device_id, display_name } = body;
      if (!device_id) return err('device_id required');

      let user = await db.prepare('SELECT * FROM users WHERE device_id = ?').bind(device_id).first();
      if (user) return json({ user_id: user.id, existing: true, display_name: user.display_name });

      const uid = uuid();
      const now = new Date().toISOString();
      await db.prepare('INSERT INTO users (id, display_name, device_id, created_at) VALUES (?, ?, ?, ?)')
        .bind(uid, display_name || null, device_id, now).run();

      // Auto-create personal group
      const g = gid();
      const gname = display_name ? `${display_name}'s Space` : 'My Space';
      await db.prepare('INSERT INTO groups_t (id, name, owner_id, created_at) VALUES (?, ?, ?, ?)')
        .bind(g, gname, uid, now).run();
      await db.prepare('INSERT INTO group_members (group_id, user_id, role, joined_at) VALUES (?, ?, ?, ?)')
        .bind(g, uid, 'owner', now).run();

      return json({ user_id: uid, existing: false, group_id: g, group_name: gname });
    }

    // GET /users/me?user_id=
    if (path === '/users/me' && request.method === 'GET') {
      const uid = url.searchParams.get('user_id');
      if (!uid) return err('user_id required');
      const u = await db.prepare('SELECT * FROM users WHERE id = ?').bind(uid).first();
      if (!u) return err('user not found', 404);
      return json({ id: u.id, display_name: u.display_name, avatar_url: u.avatar_url, device_id: u.device_id, created_at: u.created_at });
    }

    // PATCH /users/profile
    if (path === '/users/profile' && request.method === 'PATCH') {
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { user_id, display_name, avatar_url } = body;
      if (!user_id) return err('user_id required');
      if (display_name != null) await db.prepare('UPDATE users SET display_name = ? WHERE id = ?').bind(display_name, user_id).run();
      if (avatar_url != null) await db.prepare('UPDATE users SET avatar_url = ? WHERE id = ?').bind(avatar_url, user_id).run();
      return json({ status: 'ok' });
    }

    // ══════════════════════════════════════
    //  GROUPS
    // ══════════════════════════════════════

    // POST /groups/create
    if (path === '/groups/create' && request.method === 'POST') {
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { user_id, name } = body;
      if (!user_id || !name) return err('user_id and name required');

      const g = gid();
      const now = new Date().toISOString();
      await db.prepare('INSERT INTO groups_t (id, name, owner_id, created_at) VALUES (?, ?, ?, ?)')
        .bind(g, name, user_id, now).run();
      await db.prepare('INSERT INTO group_members (group_id, user_id, role, joined_at) VALUES (?, ?, ?, ?)')
        .bind(g, user_id, 'owner', now).run();
      await db.prepare('INSERT OR IGNORE INTO locations (user_id, group_id, latitude, longitude, updated_at) VALUES (?, ?, 0, 0, ?)')
        .bind(user_id, g, now).run();

      return json({ group_id: g, name, owner_id: user_id, created_at: now });
    }

    // GET /groups?user_id=
    if (path === '/groups' && request.method === 'GET') {
      const uid = url.searchParams.get('user_id');
      if (!uid) return err('user_id required');

      const rows = await db.prepare(`
        SELECT g.*, gm.role, gm.joined_at,
          (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count
        FROM groups_t g
        JOIN group_members gm ON g.id = gm.group_id
        WHERE gm.user_id = ?
        ORDER BY g.created_at DESC
      `).bind(uid).all();

      return json({ groups: rows.results.map(r => ({
        id: r.id, name: r.name, owner_id: r.owner_id,
        role: r.role, member_count: r.member_count,
        created_at: r.created_at, joined_at: r.joined_at,
      }))});
    }

    // GET /groups/:id
    const groupMatch = path.match(/^\/groups\/([a-z0-9_]+)$/);
    if (groupMatch && request.method === 'GET') {
      const g = await db.prepare('SELECT * FROM groups_t WHERE id = ?').bind(groupMatch[1]).first();
      if (!g) return err('group not found', 404);
      const { count } = await db.prepare('SELECT COUNT(*) as count FROM group_members WHERE group_id = ?').bind(g.id).first();
      return json({ id: g.id, name: g.name, owner_id: g.owner_id, member_count: count, created_at: g.created_at });
    }

    // DELETE /groups/:id
    if (groupMatch && request.method === 'DELETE') {
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { user_id } = body;
      if (!user_id) return err('user_id required');
      const g = await db.prepare('SELECT * FROM groups_t WHERE id = ? AND owner_id = ?').bind(groupMatch[1], user_id).first();
      if (!g) return err('not found or not owner', 404);
      await db.prepare('DELETE FROM locations WHERE group_id = ?').bind(g.id).run();
      await db.prepare('DELETE FROM invites WHERE group_id = ?').bind(g.id).run();
      await db.prepare('DELETE FROM group_members WHERE group_id = ?').bind(g.id).run();
      await db.prepare('DELETE FROM groups_t WHERE id = ?').bind(g.id).run();
      return json({ status: 'deleted' });
    }

    // ══════════════════════════════════════
    //  MEMBERS
    // ══════════════════════════════════════

    // GET /groups/:id/members
    const membersMatch = path.match(/^\/groups\/([a-z0-9_]+)\/members$/);
    if (membersMatch && request.method === 'GET') {
      const members = await db.prepare(`
        SELECT u.id, u.display_name, u.avatar_url,
          l.latitude, l.longitude, l.speed, l.heading, l.battery,
          l.activity, l.is_moving, l.updated_at as last_seen,
          gm.role, gm.joined_at
        FROM group_members gm
        JOIN users u ON u.id = gm.user_id
        LEFT JOIN locations l ON l.user_id = gm.user_id AND l.group_id = gm.group_id
        WHERE gm.group_id = ?
      `).bind(membersMatch[1]).all();

      return json({
        members: members.results.map(m => ({
          id: m.id,
          display_name: m.display_name || 'Unknown',
          avatar_url: m.avatar_url,
          role: m.role,
          latitude: m.latitude ?? null,
          longitude: m.longitude ?? null,
          speed: m.speed ?? 0,
          heading: m.heading ?? 0,
          battery: m.battery ?? null,
          activity: m.activity || 'Stationary',
          is_moving: !!m.is_moving,
          presence: presence(m.last_seen),
          last_seen: m.last_seen ?? null,
          joined_at: m.joined_at,
        })),
      });
    }

    // POST /groups/:id/leave
    const leaveMatch = path.match(/^\/groups\/([a-z0-9_]+)\/leave$/);
    if (leaveMatch && request.method === 'POST') {
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { user_id } = body;
      if (!user_id) return err('user_id required');
      await db.prepare('DELETE FROM locations WHERE user_id = ? AND group_id = ?').bind(user_id, leaveMatch[1]).run();
      await db.prepare('DELETE FROM group_members WHERE user_id = ? AND group_id = ?').bind(user_id, leaveMatch[1]).run();
      return json({ status: 'left' });
    }

    // POST /groups/:id/remove
    const removeMatch = path.match(/^\/groups\/([a-z0-9_]+)\/remove$/);
    if (removeMatch && request.method === 'POST') {
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { user_id, target_id } = body;
      if (!user_id || !target_id) return err('user_id and target_id required');
      const isOwner = await db.prepare('SELECT id FROM groups_t WHERE id = ? AND owner_id = ?').bind(removeMatch[1], user_id).first();
      if (!isOwner) return err('only owner can remove members', 403);
      await db.prepare('DELETE FROM locations WHERE user_id = ? AND group_id = ?').bind(target_id, removeMatch[1]).run();
      await db.prepare('DELETE FROM group_members WHERE user_id = ? AND group_id = ?').bind(target_id, removeMatch[1]).run();
      return json({ status: 'removed' });
    }

    // ══════════════════════════════════════
    //  INVITES
    // ══════════════════════════════════════

    // POST /invite/create
    if (path === '/invite/create' && request.method === 'POST') {
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { group_id, user_id } = body;
      if (!group_id || !user_id) return err('group_id and user_id required');

      const member = await db.prepare('SELECT role FROM group_members WHERE group_id = ? AND user_id = ?')
        .bind(group_id, user_id).first();
      if (!member || (member.role !== 'owner' && member.role !== 'admin')) return err('not authorized', 403);

      let code;
      for (let i = 0; i < 10; i++) { code = genCode(); const e = await db.prepare('SELECT code FROM invites WHERE code = ? AND expires_at > datetime("now")').bind(code).first(); if (!e) break; }
      const expires = new Date(Date.now() + INVITE_TTL_MS).toISOString();
      await db.prepare('INSERT INTO invites (code, group_id, expires_at, created_at) VALUES (?, ?, ?, ?)')
        .bind(code, group_id, expires, new Date().toISOString()).run();

      return json({ code, group_id, expires_in: INVITE_TTL_MS / 1000 });
    }

    // POST /invite/join
    if (path === '/invite/join' && request.method === 'POST') {
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { code, user_id, display_name } = body;
      if (!code || !user_id) return err('code and user_id required');

      const invite = await db.prepare(
        'SELECT * FROM invites WHERE code = ? AND expires_at > datetime("now") AND used = 0'
      ).bind(code.toUpperCase()).first();
      if (!invite) return err('invalid or expired code');

      const already = await db.prepare('SELECT * FROM group_members WHERE group_id = ? AND user_id = ?')
        .bind(invite.group_id, user_id).first();
      if (already) return err('already a member');

      const now = new Date().toISOString();
      await db.prepare('INSERT INTO group_members (group_id, user_id, role, joined_at) VALUES (?, ?, ?, ?)')
        .bind(invite.group_id, user_id, 'member', now).run();
      await db.prepare('INSERT OR IGNORE INTO locations (user_id, group_id, latitude, longitude, updated_at) VALUES (?, ?, 0, 0, ?)')
        .bind(user_id, invite.group_id, now).run();
      await db.prepare('UPDATE invites SET used = 1 WHERE code = ?').bind(code.toUpperCase()).run();

      if (display_name) await db.prepare('UPDATE users SET display_name = ? WHERE id = ?').bind(display_name, user_id).run();

      const group = await db.prepare('SELECT * FROM groups_t WHERE id = ?').bind(invite.group_id).first();
      return json({ status: 'joined', group_id: group.id, group_name: group.name });
    }

    // GET /invite/:code
    const inviteMatch = path.match(/^\/invite\/([A-Z0-9]+)$/);
    if (inviteMatch && request.method === 'GET') {
      const invite = await db.prepare(
        'SELECT i.*, g.name as group_name FROM invites i JOIN groups_t g ON g.id = i.group_id WHERE i.code = ? AND i.expires_at > datetime("now") AND i.used = 0'
      ).bind(inviteMatch[1]).first();
      if (!invite) return err('invalid or expired code');
      const { count } = await db.prepare('SELECT COUNT(*) as count FROM group_members WHERE group_id = ?').bind(invite.group_id).first();
      return json({ code: invite.code, group_id: invite.group_id, group_name: invite.group_name, member_count: count });
    }

    // ══════════════════════════════════════
    //  LOCATIONS
    // ══════════════════════════════════════

    // POST /location
    if (path === '/location' && request.method === 'POST') {
      if (!rl(ip)) return err('rate limited', 429);
      let body;
      try { body = await request.json(); } catch { return err('invalid json'); }
      const { user_id, group_id, latitude, longitude, altitude, speed, heading, battery, activity } = body;
      if (!user_id || !group_id || latitude == null || longitude == null) return err('user_id, group_id, latitude, longitude required');

      const now = new Date().toISOString();
      const moving = (speed || 0) > 1;

      await db.prepare(`
        INSERT INTO locations (user_id, group_id, latitude, longitude, altitude, speed, heading, battery, activity, is_online, is_moving, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
        ON CONFLICT(user_id, group_id) DO UPDATE SET
          latitude = excluded.latitude, longitude = excluded.longitude,
          altitude = excluded.altitude, speed = excluded.speed, heading = excluded.heading,
          battery = excluded.battery, activity = excluded.activity,
          is_online = 1, is_moving = excluded.is_moving, updated_at = excluded.updated_at
      `).bind(user_id, group_id, latitude, longitude, altitude ?? 0, speed ?? 0, heading ?? 0,
        battery ?? 100, activity ?? 'Stationary', moving ? 1 : 0, now).run();

      return json({ status: 'ok', updated_at: now });
    }

    // GET /groups/:id/locations
    const locsMatch = path.match(/^\/groups\/([a-z0-9_]+)\/locations$/);
    if (locsMatch && request.method === 'GET') {
      const rows = await db.prepare(`
        SELECT l.*, u.display_name, u.avatar_url
        FROM locations l
        JOIN users u ON u.id = l.user_id
        WHERE l.group_id = ?
        ORDER BY l.updated_at DESC
      `).bind(locsMatch[1]).all();

      return json({ locations: rows.results.map(l => ({
        user_id: l.user_id, display_name: l.display_name || 'Unknown', avatar_url: l.avatar_url,
        latitude: l.latitude, longitude: l.longitude,
        altitude: l.altitude, speed: l.speed, heading: l.heading,
        battery: l.battery, activity: l.activity, is_online: !!l.is_online, is_moving: !!l.is_moving,
        presence: presence(l.updated_at), last_seen: l.updated_at,
      }))});
    }

    // GET /groups/:id/member/:userId
    const memberLocMatch = path.match(/^\/groups\/([a-z0-9_]+)\/member\/(.+)$/);
    if (memberLocMatch && request.method === 'GET') {
      const l = await db.prepare(`
        SELECT l.*, u.display_name, u.avatar_url
        FROM locations l JOIN users u ON u.id = l.user_id
        WHERE l.group_id = ? AND l.user_id = ?
      `).bind(memberLocMatch[1], memberLocMatch[2]).first();

      if (!l) return json({ member: null });
      return json({
        member: {
          user_id: l.user_id, display_name: l.display_name || 'Unknown', avatar_url: l.avatar_url,
          latitude: l.latitude, longitude: l.longitude,
          altitude: l.altitude, speed: l.speed, heading: l.heading,
          battery: l.battery, activity: l.activity, is_online: !!l.is_online, is_moving: !!l.is_moving,
          presence: presence(l.updated_at), last_seen: l.updated_at,
        },
      });
    }

    return err('not found', 404);
  },
};
