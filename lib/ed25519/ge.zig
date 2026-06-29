//! Group arithmetic on Curve25519 — port of `ge.c` (sign path).

const fe = @import("fe.zig");
const Fe = fe.Fe;
const precomp = @import("precomp_data.zig");

pub const GeP2 = struct { X: Fe, Y: Fe, Z: Fe };
pub const GeP3 = struct { X: Fe, Y: Fe, Z: Fe, T: Fe };
pub const GeP1P1 = struct { X: Fe, Y: Fe, Z: Fe, T: Fe };
pub const GePrecomp = precomp.GePrecomp;

fn ge_madd(r: *GeP1P1, p: *const GeP3, q: *const GePrecomp) void {
    var t0: Fe = undefined;
    fe.fe_add(&r.X, p.Y, p.X);
    fe.fe_sub(&r.Y, p.Y, p.X);
    fe.fe_mul(&r.Z, r.X, q.yplusx);
    fe.fe_mul(&r.Y, r.Y, q.yminusx);
    fe.fe_mul(&r.T, q.xy2d, p.T);
    fe.fe_add(&t0, p.Z, p.Z);
    fe.fe_sub(&r.X, r.Z, r.Y);
    fe.fe_add(&r.Y, r.Z, r.Y);
    fe.fe_add(&r.Z, t0, r.T);
    fe.fe_sub(&r.T, t0, r.T);
}

fn ge_p1p1_to_p2(r: *GeP2, p: *const GeP1P1) void {
    fe.fe_mul(&r.X, p.X, p.T);
    fe.fe_mul(&r.Y, p.Y, p.Z);
    fe.fe_mul(&r.Z, p.Z, p.T);
}

fn ge_p1p1_to_p3(r: *GeP3, p: *const GeP1P1) void {
    fe.fe_mul(&r.X, p.X, p.T);
    fe.fe_mul(&r.Y, p.Y, p.Z);
    fe.fe_mul(&r.Z, p.Z, p.T);
    fe.fe_mul(&r.T, p.X, p.Y);
}

fn ge_p2_dbl(r: *GeP1P1, p: *const GeP2) void {
    var t0: Fe = undefined;
    fe.fe_sq(&r.X, p.X);
    fe.fe_sq(&r.Z, p.Y);
    fe.fe_sq2(&r.T, p.Z);
    fe.fe_add(&r.Y, p.X, p.Y);
    fe.fe_sq(&t0, r.Y);
    fe.fe_add(&r.Y, r.Z, r.X);
    fe.fe_sub(&r.Z, r.Z, r.X);
    fe.fe_sub(&r.X, t0, r.Y);
    fe.fe_sub(&r.T, r.T, r.Z);
}

fn ge_p3_0(h: *GeP3) void {
    fe.fe_0(&h.X);
    fe.fe_1(&h.Y);
    fe.fe_1(&h.Z);
    fe.fe_0(&h.T);
}

fn ge_p3_dbl(r: *GeP1P1, p: *const GeP3) void {
    var q: GeP2 = undefined;
    ge_p3_to_p2(&q, p);
    ge_p2_dbl(r, &q);
}

fn ge_p3_to_p2(r: *GeP2, p: *const GeP3) void {
    fe.fe_copy(&r.X, p.X);
    fe.fe_copy(&r.Y, p.Y);
    fe.fe_copy(&r.Z, p.Z);
}

pub fn ge_p3_tobytes(s: []u8, h: *const GeP3) void {
    var recip: Fe = undefined;
    var x: Fe = undefined;
    var y: Fe = undefined;
    fe.fe_invert(&recip, h.Z);
    fe.fe_mul(&x, h.X, recip);
    fe.fe_mul(&y, h.Y, recip);
    fe.fe_tobytes(s, y);
    s[31] ^= @as(u8, @intCast(fe.fe_isnegative(x))) << 7;
}

fn equal(b: i8, c: i8) u8 {
    const ub: u8 = @intCast(b);
    const uc: u8 = @intCast(c);
    const x = ub ^ uc;
    var y: u64 = x;
    y -%= 1;
    y >>= 63;
    return @truncate(y);
}

fn negative(b: i8) u8 {
    var x: u64 = @bitCast(@as(i64, b));
    x >>= 63;
    return @truncate(x);
}

fn cmov(t: *GePrecomp, u: *const GePrecomp, b: u8) void {
    fe.fe_cmov(&t.yplusx, u.yplusx, b);
    fe.fe_cmov(&t.yminusx, u.yminusx, b);
    fe.fe_cmov(&t.xy2d, u.xy2d, b);
}

fn select(t: *GePrecomp, pos: usize, b: i8) void {
    var minust: GePrecomp = undefined;
    const bnegative = negative(b);
    const babs: u8 = @intCast(b -% @as(i8, @intCast((@as(u8, @intCast(-%bnegative)) & @as(u8, @intCast(b))) << 1)));
    fe.fe_1(&t.yplusx);
    fe.fe_1(&t.yminusx);
    fe.fe_0(&t.xy2d);
    cmov(t, &precomp.base[pos][0], equal(@intCast(babs), 1));
    cmov(t, &precomp.base[pos][1], equal(@intCast(babs), 2));
    cmov(t, &precomp.base[pos][2], equal(@intCast(babs), 3));
    cmov(t, &precomp.base[pos][3], equal(@intCast(babs), 4));
    cmov(t, &precomp.base[pos][4], equal(@intCast(babs), 5));
    cmov(t, &precomp.base[pos][5], equal(@intCast(babs), 6));
    cmov(t, &precomp.base[pos][6], equal(@intCast(babs), 7));
    cmov(t, &precomp.base[pos][7], equal(@intCast(babs), 8));
    fe.fe_copy(&minust.yplusx, t.yminusx);
    fe.fe_copy(&minust.yminusx, t.yplusx);
    fe.fe_neg(&minust.xy2d, t.xy2d);
    cmov(t, &minust, bnegative);
}

pub fn ge_scalarmult_base(h: *GeP3, a: [*]const u8) void {
    var e: [64]i8 = undefined;
    var carry: i8 = 0;
    var r: GeP1P1 = undefined;
    var s: GeP2 = undefined;
    var t: GePrecomp = undefined;

    for (0..32) |i| {
        e[2 * i + 0] = @intCast((a[i] >> 0) & 15);
        e[2 * i + 1] = @intCast((a[i] >> 4) & 15);
    }

    for (0..63) |i| {
        e[i] += carry;
        carry = e[i] + 8;
        carry >>= 4;
        e[i] -= carry << 4;
    }
    e[63] += carry;

    ge_p3_0(h);

    var i: usize = 1;
    while (i < 64) : (i += 2) {
        select(&t, i / 2, e[i]);
        ge_madd(&r, h, &t);
        ge_p1p1_to_p3(h, &r);
    }

    ge_p3_dbl(&r, h);
    ge_p1p1_to_p2(&s, &r);
    ge_p2_dbl(&r, &s);
    ge_p1p1_to_p2(&s, &r);
    ge_p2_dbl(&r, &s);
    ge_p1p1_to_p2(&s, &r);
    ge_p2_dbl(&r, &s);
    ge_p1p1_to_p3(h, &r);

    i = 0;
    while (i < 64) : (i += 2) {
        select(&t, i / 2, e[i]);
        ge_madd(&r, h, &t);
        ge_p1p1_to_p3(h, &r);
    }
}
