// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Field arithmetic over GF(2^255-19) — port of `fe.c`.

pub const Fe = [10]i32;


fn load3(in: [*]const u8) u64 {
    const result: u64 = @as(u64, in[0]);
    result |= @as(u64, in[1]) << 8;
    result |= @as(u64, in[2]) << 16;
    return result;
}

fn load4(in: [*]const u8) u64 {
    const result: u64 = @as(u64, in[0]);
    result |= @as(u64, in[1]) << 8;
    result |= @as(u64, in[2]) << 16;
    result |= @as(u64, in[3]) << 24;
    return result;
}











pub fn fe_0(h: *Fe) void {
    h[0] = 0;
    h[1] = 0;
    h[2] = 0;
    h[3] = 0;
    h[4] = 0;
    h[5] = 0;
    h[6] = 0;
    h[7] = 0;
    h[8] = 0;
    h[9] = 0;
}





pub fn fe_1(h: *Fe) void {
    h[0] = 1;
    h[1] = 0;
    h[2] = 0;
    h[3] = 0;
    h[4] = 0;
    h[5] = 0;
    h[6] = 0;
    h[7] = 0;
    h[8] = 0;
    h[9] = 0;
}





pub fn fe_add(h: *Fe, f: Fe, g: Fe) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    const g0: i32 = g[0];
    const g1: i32 = g[1];
    const g2: i32 = g[2];
    const g3: i32 = g[3];
    const g4: i32 = g[4];
    const g5: i32 = g[5];
    const g6: i32 = g[6];
    const g7: i32 = g[7];
    const g8: i32 = g[8];
    const g9: i32 = g[9];
    const h0: i32 = f0 + g0;
    const h1: i32 = f1 + g1;
    const h2: i32 = f2 + g2;
    const h3: i32 = f3 + g3;
    const h4: i32 = f4 + g4;
    const h5: i32 = f5 + g5;
    const h6: i32 = f6 + g6;
    const h7: i32 = f7 + g7;
    const h8: i32 = f8 + g8;
    const h9: i32 = f9 + g9;

    h[0] = h0;
    h[1] = h1;
    h[2] = h2;
    h[3] = h3;
    h[4] = h4;
    h[5] = h5;
    h[6] = h6;
    h[7] = h7;
    h[8] = h8;
    h[9] = h9;
}





pub fn fe_cmov(f: *Fe, g: Fe, b: u32) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    const g0: i32 = g[0];
    const g1: i32 = g[1];
    const g2: i32 = g[2];
    const g3: i32 = g[3];
    const g4: i32 = g[4];
    const g5: i32 = g[5];
    const g6: i32 = g[6];
    const g7: i32 = g[7];
    const g8: i32 = g[8];
    const g9: i32 = g[9];
    var x0: i32 = f0 ^ g0;
    var x1: i32 = f1 ^ g1;
    var x2: i32 = f2 ^ g2;
    var x3: i32 = f3 ^ g3;
    var x4: i32 = f4 ^ g4;
    var x5: i32 = f5 ^ g5;
    var x6: i32 = f6 ^ g6;
    var x7: i32 = f7 ^ g7;
    var x8: i32 = f8 ^ g8;
    var x9: i32 = f9 ^ g9;

    const mask: u32 = 0 -% b;
    const m: i32 = @bitCast(mask);
    x0 &= m;
    x1 &= m;
    x2 &= m;
    x3 &= m;
    x4 &= m;
    x5 &= m;
    x6 &= m;
    x7 &= m;
    x8 &= m;
    x9 &= m;

    f[0] = f0 ^ x0;
    f[1] = f1 ^ x1;
    f[2] = f2 ^ x2;
    f[3] = f3 ^ x3;
    f[4] = f4 ^ x4;
    f[5] = f5 ^ x5;
    f[6] = f6 ^ x6;
    f[7] = f7 ^ x7;
    f[8] = f8 ^ x8;
    f[9] = f9 ^ x9;
}



pub fn fe_cswap(f: *Fe, g: *Fe, b: u32) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    const g0: i32 = g[0];
    const g1: i32 = g[1];
    const g2: i32 = g[2];
    const g3: i32 = g[3];
    const g4: i32 = g[4];
    const g5: i32 = g[5];
    const g6: i32 = g[6];
    const g7: i32 = g[7];
    const g8: i32 = g[8];
    const g9: i32 = g[9];
    var x0: i32 = f0 ^ g0;
    var x1: i32 = f1 ^ g1;
    var x2: i32 = f2 ^ g2;
    var x3: i32 = f3 ^ g3;
    var x4: i32 = f4 ^ g4;
    var x5: i32 = f5 ^ g5;
    var x6: i32 = f6 ^ g6;
    var x7: i32 = f7 ^ g7;
    var x8: i32 = f8 ^ g8;
    var x9: i32 = f9 ^ g9;
    const mask: u32 = 0 -% b;
    const m: i32 = @bitCast(mask);
    x0 &= m;
    x1 &= m;
    x2 &= m;
    x3 &= m;
    x4 &= m;
    x5 &= m;
    x6 &= m;
    x7 &= m;
    x8 &= m;
    x9 &= m;
    f[0] = f0 ^ x0;
    f[1] = f1 ^ x1;
    f[2] = f2 ^ x2;
    f[3] = f3 ^ x3;
    f[4] = f4 ^ x4;
    f[5] = f5 ^ x5;
    f[6] = f6 ^ x6;
    f[7] = f7 ^ x7;
    f[8] = f8 ^ x8;
    f[9] = f9 ^ x9;
    g[0] = g0 ^ x0;
    g[1] = g1 ^ x1;
    g[2] = g2 ^ x2;
    g[3] = g3 ^ x3;
    g[4] = g4 ^ x4;
    g[5] = g5 ^ x5;
    g[6] = g6 ^ x6;
    g[7] = g7 ^ x7;
    g[8] = g8 ^ x8;
    g[9] = g9 ^ x9;
}





pub fn fe_copy(h: *Fe, f: Fe) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];

    h[0] = f0;
    h[1] = f1;
    h[2] = f2;
    h[3] = f3;
    h[4] = f4;
    h[5] = f5;
    h[6] = f6;
    h[7] = f7;
    h[8] = f8;
    h[9] = f9;
}





pub fn fe_frombytes(h: *Fe, s: [*]const u8) void {
    var h0: i64 = load4(s);
    var h1: i64 = load3(s + 4) << 6;
    var h2: i64 = load3(s + 7) << 5;
    var h3: i64 = load3(s + 10) << 3;
    var h4: i64 = load3(s + 13) << 2;
    var h5: i64 = load4(s + 16);
    var h6: i64 = load3(s + 20) << 7;
    var h7: i64 = load3(s + 23) << 5;
    var h8: i64 = load3(s + 26) << 4;
    var h9: i64 = (load3(s + 29) & 8388607) << 2;
    var carry0: i64 = undefined;
    var carry1: i64 = undefined;
    var carry2: i64 = undefined;
    var carry3: i64 = undefined;
    var carry4: i64 = undefined;
    var carry5: i64 = undefined;
    var carry6: i64 = undefined;
    var carry7: i64 = undefined;
    var carry8: i64 = undefined;
    var carry9: i64 = undefined;

    carry9 = (h9 + @as(i64, 1 << 24)) >> 25;
    h0 += carry9 * 19;
    h9 -= carry9 << 25;
    carry1 = (h1 + @as(i64, 1 << 24)) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry3 = (h3 + @as(i64, 1 << 24)) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry5 = (h5 + @as(i64, 1 << 24)) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;
    carry7 = (h7 + @as(i64, 1 << 24)) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;
    carry0 = (h0 + @as(i64, 1 << 25)) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry2 = (h2 + @as(i64, 1 << 25)) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry4 = (h4 + @as(i64, 1 << 25)) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry6 = (h6 + @as(i64, 1 << 25)) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;
    carry8 = (h8 + @as(i64, 1 << 25)) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;

    h[0] = @as(i32, @intCast(h0));
    h[1] = @as(i32, @intCast(h1));
    h[2] = @as(i32, @intCast(h2));
    h[3] = @as(i32, @intCast(h3));
    h[4] = @as(i32, @intCast(h4));
    h[5] = @as(i32, @intCast(h5));
    h[6] = @as(i32, @intCast(h6));
    h[7] = @as(i32, @intCast(h7));
    h[8] = @as(i32, @intCast(h8));
    h[9] = @as(i32, @intCast(h9));
}



pub fn fe_invert(out: *Fe, z: Fe) void {
    var t0: Fe = undefined;
    var t1: Fe = undefined;
    var t2: Fe = undefined;
    var t3: Fe = undefined;
    fe_sq(&t0, z);

    

    fe_sq(&t1, t0);

    for (0..1) |_| {
        fe_sq(&t1, t1);
    }

    fe_mul(&t1, z, t1);
    fe_mul(&t0, t0, t1);
    fe_sq(&t2, t0);

    

    fe_mul(&t1, t1, t2);
    fe_sq(&t2, t1);

    for (0..4) |_| {
        fe_sq(&t2, t2);
    }

    fe_mul(&t1, t2, t1);
    fe_sq(&t2, t1);

    for (0..9) |_| {
        fe_sq(&t2, t2);
    }

    fe_mul(&t2, t2, t1);
    fe_sq(&t3, t2);

    for (0..19) |_| {
        fe_sq(&t3, t3);
    }

    fe_mul(&t2, t3, t2);
    fe_sq(&t2, t2);

    for (0..9) |_| {
        fe_sq(&t2, t2);
    }

    fe_mul(&t1, t2, t1);
    fe_sq(&t2, t1);

    for (0..49) |_| {
        fe_sq(&t2, t2);
    }

    fe_mul(&t2, t2, t1);
    fe_sq(&t3, t2);

    for (0..99) |_| {
        fe_sq(&t3, t3);
    }

    fe_mul(&t2, t3, t2);
    fe_sq(&t2, t2);

    for (0..49) |_| {
        fe_sq(&t2, t2);
    }

    fe_mul(&t1, t2, t1);
    fe_sq(&t1, t1);

    for (0..4) |_| {
        fe_sq(&t1, t1);
    }

    fe_mul(out, t1, t0);
}





pub fn fe_isnegative(f: Fe) i32 {
    var s: [32]u8 = undefined;
    fe_tobytes(s[0..], f);
    return s[0] & 1;
}





pub fn fe_isnonzero(f: Fe) i32 {
    var s: [32]u8 = undefined;
    fe_tobytes(s[0..], f);
    const r: u8 = s[0];
    r |= s[1];
    r |= s[2];
    r |= s[3];
    r |= s[4];
    r |= s[5];
    r |= s[6];
    r |= s[7];
    r |= s[8];
    r |= s[9];
    r |= s[10];
    r |= s[11];
    r |= s[12];
    r |= s[13];
    r |= s[14];
    r |= s[15];
    r |= s[16];
    r |= s[17];
    r |= s[18];
    r |= s[19];
    r |= s[20];
    r |= s[21];
    r |= s[22];
    r |= s[23];
    r |= s[24];
    r |= s[25];
    r |= s[26];
    r |= s[27];
    r |= s[28];
    r |= s[29];
    r |= s[30];
    r |= s[31];
    return if (r != 0) 1 else 0;
}







pub fn fe_mul(h: *Fe, f: Fe, g: Fe) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    const g0: i32 = g[0];
    const g1: i32 = g[1];
    const g2: i32 = g[2];
    const g3: i32 = g[3];
    const g4: i32 = g[4];
    const g5: i32 = g[5];
    const g6: i32 = g[6];
    const g7: i32 = g[7];
    const g8: i32 = g[8];
    const g9: i32 = g[9];
    const g1_19: i32 = 19 * g1;
    const g2_19: i32 = 19 * g2;
    const g3_19: i32 = 19 * g3;
    const g4_19: i32 = 19 * g4;
    const g5_19: i32 = 19 * g5;
    const g6_19: i32 = 19 * g6;
    const g7_19: i32 = 19 * g7;
    const g8_19: i32 = 19 * g8;
    const g9_19: i32 = 19 * g9;
    const f1_2: i32 = 2 * f1;
    const f3_2: i32 = 2 * f3;
    const f5_2: i32 = 2 * f5;
    const f7_2: i32 = 2 * f7;
    const f9_2: i32 = 2 * f9;
    const f0g0: i64 = f0   * @as(i64, g0);
    const f0g1: i64 = f0   * @as(i64, g1);
    const f0g2: i64 = f0   * @as(i64, g2);
    const f0g3: i64 = f0   * @as(i64, g3);
    const f0g4: i64 = f0   * @as(i64, g4);
    const f0g5: i64 = f0   * @as(i64, g5);
    const f0g6: i64 = f0   * @as(i64, g6);
    const f0g7: i64 = f0   * @as(i64, g7);
    const f0g8: i64 = f0   * @as(i64, g8);
    const f0g9: i64 = f0   * @as(i64, g9);
    const f1g0: i64 = f1   * @as(i64, g0);
    const f1g1_2: i64 = f1_2 * @as(i64, g1);
    const f1g2: i64 = f1   * @as(i64, g2);
    const f1g3_2: i64 = f1_2 * @as(i64, g3);
    const f1g4: i64 = f1   * @as(i64, g4);
    const f1g5_2: i64 = f1_2 * @as(i64, g5);
    const f1g6: i64 = f1   * @as(i64, g6);
    const f1g7_2: i64 = f1_2 * @as(i64, g7);
    const f1g8: i64 = f1   * @as(i64, g8);
    const f1g9_38: i64 = f1_2 * @as(i64, g9_19);
    const f2g0: i64 = f2   * @as(i64, g0);
    const f2g1: i64 = f2   * @as(i64, g1);
    const f2g2: i64 = f2   * @as(i64, g2);
    const f2g3: i64 = f2   * @as(i64, g3);
    const f2g4: i64 = f2   * @as(i64, g4);
    const f2g5: i64 = f2   * @as(i64, g5);
    const f2g6: i64 = f2   * @as(i64, g6);
    const f2g7: i64 = f2   * @as(i64, g7);
    const f2g8_19: i64 = f2   * @as(i64, g8_19);
    const f2g9_19: i64 = f2   * @as(i64, g9_19);
    const f3g0: i64 = f3   * @as(i64, g0);
    const f3g1_2: i64 = f3_2 * @as(i64, g1);
    const f3g2: i64 = f3   * @as(i64, g2);
    const f3g3_2: i64 = f3_2 * @as(i64, g3);
    const f3g4: i64 = f3   * @as(i64, g4);
    const f3g5_2: i64 = f3_2 * @as(i64, g5);
    const f3g6: i64 = f3   * @as(i64, g6);
    const f3g7_38: i64 = f3_2 * @as(i64, g7_19);
    const f3g8_19: i64 = f3   * @as(i64, g8_19);
    const f3g9_38: i64 = f3_2 * @as(i64, g9_19);
    const f4g0: i64 = f4   * @as(i64, g0);
    const f4g1: i64 = f4   * @as(i64, g1);
    const f4g2: i64 = f4   * @as(i64, g2);
    const f4g3: i64 = f4   * @as(i64, g3);
    const f4g4: i64 = f4   * @as(i64, g4);
    const f4g5: i64 = f4   * @as(i64, g5);
    const f4g6_19: i64 = f4   * @as(i64, g6_19);
    const f4g7_19: i64 = f4   * @as(i64, g7_19);
    const f4g8_19: i64 = f4   * @as(i64, g8_19);
    const f4g9_19: i64 = f4   * @as(i64, g9_19);
    const f5g0: i64 = f5   * @as(i64, g0);
    const f5g1_2: i64 = f5_2 * @as(i64, g1);
    const f5g2: i64 = f5   * @as(i64, g2);
    const f5g3_2: i64 = f5_2 * @as(i64, g3);
    const f5g4: i64 = f5   * @as(i64, g4);
    const f5g5_38: i64 = f5_2 * @as(i64, g5_19);
    const f5g6_19: i64 = f5   * @as(i64, g6_19);
    const f5g7_38: i64 = f5_2 * @as(i64, g7_19);
    const f5g8_19: i64 = f5   * @as(i64, g8_19);
    const f5g9_38: i64 = f5_2 * @as(i64, g9_19);
    const f6g0: i64 = f6   * @as(i64, g0);
    const f6g1: i64 = f6   * @as(i64, g1);
    const f6g2: i64 = f6   * @as(i64, g2);
    const f6g3: i64 = f6   * @as(i64, g3);
    const f6g4_19: i64 = f6   * @as(i64, g4_19);
    const f6g5_19: i64 = f6   * @as(i64, g5_19);
    const f6g6_19: i64 = f6   * @as(i64, g6_19);
    const f6g7_19: i64 = f6   * @as(i64, g7_19);
    const f6g8_19: i64 = f6   * @as(i64, g8_19);
    const f6g9_19: i64 = f6   * @as(i64, g9_19);
    const f7g0: i64 = f7   * @as(i64, g0);
    const f7g1_2: i64 = f7_2 * @as(i64, g1);
    const f7g2: i64 = f7   * @as(i64, g2);
    const f7g3_38: i64 = f7_2 * @as(i64, g3_19);
    const f7g4_19: i64 = f7   * @as(i64, g4_19);
    const f7g5_38: i64 = f7_2 * @as(i64, g5_19);
    const f7g6_19: i64 = f7   * @as(i64, g6_19);
    const f7g7_38: i64 = f7_2 * @as(i64, g7_19);
    const f7g8_19: i64 = f7   * @as(i64, g8_19);
    const f7g9_38: i64 = f7_2 * @as(i64, g9_19);
    const f8g0: i64 = f8   * @as(i64, g0);
    const f8g1: i64 = f8   * @as(i64, g1);
    const f8g2_19: i64 = f8   * @as(i64, g2_19);
    const f8g3_19: i64 = f8   * @as(i64, g3_19);
    const f8g4_19: i64 = f8   * @as(i64, g4_19);
    const f8g5_19: i64 = f8   * @as(i64, g5_19);
    const f8g6_19: i64 = f8   * @as(i64, g6_19);
    const f8g7_19: i64 = f8   * @as(i64, g7_19);
    const f8g8_19: i64 = f8   * @as(i64, g8_19);
    const f8g9_19: i64 = f8   * @as(i64, g9_19);
    const f9g0: i64 = f9   * @as(i64, g0);
    const f9g1_38: i64 = f9_2 * @as(i64, g1_19);
    const f9g2_19: i64 = f9   * @as(i64, g2_19);
    const f9g3_38: i64 = f9_2 * @as(i64, g3_19);
    const f9g4_19: i64 = f9   * @as(i64, g4_19);
    const f9g5_38: i64 = f9_2 * @as(i64, g5_19);
    const f9g6_19: i64 = f9   * @as(i64, g6_19);
    const f9g7_38: i64 = f9_2 * @as(i64, g7_19);
    const f9g8_19: i64 = f9   * @as(i64, g8_19);
    const f9g9_38: i64 = f9_2 * @as(i64, g9_19);
    var h0: i64 = f0g0 + f1g9_38 + f2g8_19 + f3g7_38 + f4g6_19 + f5g5_38 + f6g4_19 + f7g3_38 + f8g2_19 + f9g1_38;
    var h1: i64 = f0g1 + f1g0   + f2g9_19 + f3g8_19 + f4g7_19 + f5g6_19 + f6g5_19 + f7g4_19 + f8g3_19 + f9g2_19;
    var h2: i64 = f0g2 + f1g1_2 + f2g0   + f3g9_38 + f4g8_19 + f5g7_38 + f6g6_19 + f7g5_38 + f8g4_19 + f9g3_38;
    var h3: i64 = f0g3 + f1g2   + f2g1   + f3g0   + f4g9_19 + f5g8_19 + f6g7_19 + f7g6_19 + f8g5_19 + f9g4_19;
    var h4: i64 = f0g4 + f1g3_2 + f2g2   + f3g1_2 + f4g0   + f5g9_38 + f6g8_19 + f7g7_38 + f8g6_19 + f9g5_38;
    var h5: i64 = f0g5 + f1g4   + f2g3   + f3g2   + f4g1   + f5g0   + f6g9_19 + f7g8_19 + f8g7_19 + f9g6_19;
    var h6: i64 = f0g6 + f1g5_2 + f2g4   + f3g3_2 + f4g2   + f5g1_2 + f6g0   + f7g9_38 + f8g8_19 + f9g7_38;
    var h7: i64 = f0g7 + f1g6   + f2g5   + f3g4   + f4g3   + f5g2   + f6g1   + f7g0   + f8g9_19 + f9g8_19;
    var h8: i64 = f0g8 + f1g7_2 + f2g6   + f3g5_2 + f4g4   + f5g3_2 + f6g2   + f7g1_2 + f8g0   + f9g9_38;
    var h9: i64 = f0g9 + f1g8   + f2g7   + f3g6   + f4g5   + f5g4   + f6g3   + f7g2   + f8g1   + f9g0   ;
    var carry0: i64 = undefined;
    var carry1: i64 = undefined;
    var carry2: i64 = undefined;
    var carry3: i64 = undefined;
    var carry4: i64 = undefined;
    var carry5: i64 = undefined;
    var carry6: i64 = undefined;
    var carry7: i64 = undefined;
    var carry8: i64 = undefined;
    var carry9: i64 = undefined;

    carry0 = (h0 + @as(i64, 1 << 25)) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry4 = (h4 + @as(i64, 1 << 25)) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;

    carry1 = (h1 + @as(i64, 1 << 24)) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry5 = (h5 + @as(i64, 1 << 24)) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;

    carry2 = (h2 + @as(i64, 1 << 25)) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry6 = (h6 + @as(i64, 1 << 25)) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;

    carry3 = (h3 + @as(i64, 1 << 24)) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry7 = (h7 + @as(i64, 1 << 24)) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;

    carry4 = (h4 + @as(i64, 1 << 25)) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry8 = (h8 + @as(i64, 1 << 25)) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;

    carry9 = (h9 + @as(i64, 1 << 24)) >> 25;
    h0 += carry9 * 19;
    h9 -= carry9 << 25;

    carry0 = (h0 + @as(i64, 1 << 25)) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;

    h[0] = @as(i32, @intCast(h0));
    h[1] = @as(i32, @intCast(h1));
    h[2] = @as(i32, @intCast(h2));
    h[3] = @as(i32, @intCast(h3));
    h[4] = @as(i32, @intCast(h4));
    h[5] = @as(i32, @intCast(h5));
    h[6] = @as(i32, @intCast(h6));
    h[7] = @as(i32, @intCast(h7));
    h[8] = @as(i32, @intCast(h8));
    h[9] = @as(i32, @intCast(h9));
}




pub fn fe_mul121666(h: *Fe, f: Fe) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    var h0: i64 = f0 * @as(i64, 121666);
    var h1: i64 = f1 * @as(i64, 121666);
    var h2: i64 = f2 * @as(i64, 121666);
    var h3: i64 = f3 * @as(i64, 121666);
    var h4: i64 = f4 * @as(i64, 121666);
    var h5: i64 = f5 * @as(i64, 121666);
    var h6: i64 = f6 * @as(i64, 121666);
    var h7: i64 = f7 * @as(i64, 121666);
    var h8: i64 = f8 * @as(i64, 121666);
    var h9: i64 = f9 * @as(i64, 121666);
    var carry0: i64 = undefined;
    var carry1: i64 = undefined;
    var carry2: i64 = undefined;
    var carry3: i64 = undefined;
    var carry4: i64 = undefined;
    var carry5: i64 = undefined;
    var carry6: i64 = undefined;
    var carry7: i64 = undefined;
    var carry8: i64 = undefined;
    var carry9: i64 = undefined;

    carry9 = (h9 + @as(i64, 1<<24)) >> 25; h0 += carry9 * 19; h9 -= carry9 << 25;
    carry1 = (h1 + @as(i64, 1<<24)) >> 25; h2 += carry1; h1 -= carry1 << 25;
    carry3 = (h3 + @as(i64, 1<<24)) >> 25; h4 += carry3; h3 -= carry3 << 25;
    carry5 = (h5 + @as(i64, 1<<24)) >> 25; h6 += carry5; h5 -= carry5 << 25;
    carry7 = (h7 + @as(i64, 1<<24)) >> 25; h8 += carry7; h7 -= carry7 << 25;

    carry0 = (h0 + @as(i64, 1<<25)) >> 26; h1 += carry0; h0 -= carry0 << 26;
    carry2 = (h2 + @as(i64, 1<<25)) >> 26; h3 += carry2; h2 -= carry2 << 26;
    carry4 = (h4 + @as(i64, 1<<25)) >> 26; h5 += carry4; h4 -= carry4 << 26;
    carry6 = (h6 + @as(i64, 1<<25)) >> 26; h7 += carry6; h6 -= carry6 << 26;
    carry8 = (h8 + @as(i64, 1<<25)) >> 26; h9 += carry8; h8 -= carry8 << 26;

    h[0] = @as(i32, @intCast(h0));
    h[1] = @as(i32, @intCast(h1));
    h[2] = @as(i32, @intCast(h2));
    h[3] = @as(i32, @intCast(h3));
    h[4] = @as(i32, @intCast(h4));
    h[5] = @as(i32, @intCast(h5));
    h[6] = @as(i32, @intCast(h6));
    h[7] = @as(i32, @intCast(h7));
    h[8] = @as(i32, @intCast(h8));
    h[9] = @as(i32, @intCast(h9));
}




pub fn fe_neg(h: *Fe, f: Fe) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    const h0: i32 = -f0;
    const h1: i32 = -f1;
    const h2: i32 = -f2;
    const h3: i32 = -f3;
    const h4: i32 = -f4;
    const h5: i32 = -f5;
    const h6: i32 = -f6;
    const h7: i32 = -f7;
    const h8: i32 = -f8;
    const h9: i32 = -f9;

    h[0] = h0;
    h[1] = h1;
    h[2] = h2;
    h[3] = h3;
    h[4] = h4;
    h[5] = h5;
    h[6] = h6;
    h[7] = h7;
    h[8] = h8;
    h[9] = h9;
}


pub fn fe_pow22523(out: *Fe, z: Fe) void {
    var t0: Fe = undefined;
    var t1: Fe = undefined;
    var t2: Fe = undefined;
    fe_sq(&t0, z);

    

    fe_sq(&t1, t0);

    for (0..1) |_| {
        fe_sq(&t1, t1);
    }

    fe_mul(&t1, z, t1);
    fe_mul(&t0, t0, t1);
    fe_sq(&t0, t0);

    

    fe_mul(&t0, t1, t0);
    fe_sq(&t1, t0);

    for (0..4) |_| {
        fe_sq(&t1, t1);
    }

    fe_mul(&t0, t1, t0);
    fe_sq(&t1, t0);

    for (0..9) |_| {
        fe_sq(&t1, t1);
    }

    fe_mul(&t1, t1, t0);
    fe_sq(&t2, t1);

    for (0..19) |_| {
        fe_sq(&t2, t2);
    }

    fe_mul(&t1, t2, t1);
    fe_sq(&t1, t1);

    for (0..9) |_| {
        fe_sq(&t1, t1);
    }

    fe_mul(&t0, t1, t0);
    fe_sq(&t1, t0);

    for (0..49) |_| {
        fe_sq(&t1, t1);
    }

    fe_mul(&t1, t1, t0);
    fe_sq(&t2, t1);

    for (0..99) |_| {
        fe_sq(&t2, t2);
    }

    fe_mul(&t1, t2, t1);
    fe_sq(&t1, t1);

    for (0..49) |_| {
        fe_sq(&t1, t1);
    }

    fe_mul(&t0, t1, t0);
    fe_sq(&t0, t0);

    for (0..1) |_| {
        fe_sq(&t0, t0);
    }

    fe_mul(out, t0, z);
    return;
}






pub fn fe_sq(h: *Fe, f: Fe) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    const f0_2: i32 = 2 * f0;
    const f1_2: i32 = 2 * f1;
    const f2_2: i32 = 2 * f2;
    const f3_2: i32 = 2 * f3;
    const f4_2: i32 = 2 * f4;
    const f5_2: i32 = 2 * f5;
    const f6_2: i32 = 2 * f6;
    const f7_2: i32 = 2 * f7;
    const f5_38: i32 = 38 * f5;
    const f6_19: i32 = 19 * f6;
    const f7_38: i32 = 38 * f7;
    const f8_19: i32 = 19 * f8;
    const f9_38: i32 = 38 * f9;
    const f0f0: i64 = f0   * @as(i64, f0);
    const f0f1_2: i64 = f0_2 * @as(i64, f1);
    const f0f2_2: i64 = f0_2 * @as(i64, f2);
    const f0f3_2: i64 = f0_2 * @as(i64, f3);
    const f0f4_2: i64 = f0_2 * @as(i64, f4);
    const f0f5_2: i64 = f0_2 * @as(i64, f5);
    const f0f6_2: i64 = f0_2 * @as(i64, f6);
    const f0f7_2: i64 = f0_2 * @as(i64, f7);
    const f0f8_2: i64 = f0_2 * @as(i64, f8);
    const f0f9_2: i64 = f0_2 * @as(i64, f9);
    const f1f1_2: i64 = f1_2 * @as(i64, f1);
    const f1f2_2: i64 = f1_2 * @as(i64, f2);
    const f1f3_4: i64 = f1_2 * @as(i64, f3_2);
    const f1f4_2: i64 = f1_2 * @as(i64, f4);
    const f1f5_4: i64 = f1_2 * @as(i64, f5_2);
    const f1f6_2: i64 = f1_2 * @as(i64, f6);
    const f1f7_4: i64 = f1_2 * @as(i64, f7_2);
    const f1f8_2: i64 = f1_2 * @as(i64, f8);
    const f1f9_76: i64 = f1_2 * @as(i64, f9_38);
    const f2f2: i64 = f2   * @as(i64, f2);
    const f2f3_2: i64 = f2_2 * @as(i64, f3);
    const f2f4_2: i64 = f2_2 * @as(i64, f4);
    const f2f5_2: i64 = f2_2 * @as(i64, f5);
    const f2f6_2: i64 = f2_2 * @as(i64, f6);
    const f2f7_2: i64 = f2_2 * @as(i64, f7);
    const f2f8_38: i64 = f2_2 * @as(i64, f8_19);
    const f2f9_38: i64 = f2   * @as(i64, f9_38);
    const f3f3_2: i64 = f3_2 * @as(i64, f3);
    const f3f4_2: i64 = f3_2 * @as(i64, f4);
    const f3f5_4: i64 = f3_2 * @as(i64, f5_2);
    const f3f6_2: i64 = f3_2 * @as(i64, f6);
    const f3f7_76: i64 = f3_2 * @as(i64, f7_38);
    const f3f8_38: i64 = f3_2 * @as(i64, f8_19);
    const f3f9_76: i64 = f3_2 * @as(i64, f9_38);
    const f4f4: i64 = f4   * @as(i64, f4);
    const f4f5_2: i64 = f4_2 * @as(i64, f5);
    const f4f6_38: i64 = f4_2 * @as(i64, f6_19);
    const f4f7_38: i64 = f4   * @as(i64, f7_38);
    const f4f8_38: i64 = f4_2 * @as(i64, f8_19);
    const f4f9_38: i64 = f4   * @as(i64, f9_38);
    const f5f5_38: i64 = f5   * @as(i64, f5_38);
    const f5f6_38: i64 = f5_2 * @as(i64, f6_19);
    const f5f7_76: i64 = f5_2 * @as(i64, f7_38);
    const f5f8_38: i64 = f5_2 * @as(i64, f8_19);
    const f5f9_76: i64 = f5_2 * @as(i64, f9_38);
    const f6f6_19: i64 = f6   * @as(i64, f6_19);
    const f6f7_38: i64 = f6   * @as(i64, f7_38);
    const f6f8_38: i64 = f6_2 * @as(i64, f8_19);
    const f6f9_38: i64 = f6   * @as(i64, f9_38);
    const f7f7_38: i64 = f7   * @as(i64, f7_38);
    const f7f8_38: i64 = f7_2 * @as(i64, f8_19);
    const f7f9_76: i64 = f7_2 * @as(i64, f9_38);
    const f8f8_19: i64 = f8   * @as(i64, f8_19);
    const f8f9_38: i64 = f8   * @as(i64, f9_38);
    const f9f9_38: i64 = f9   * @as(i64, f9_38);
    var h0: i64 = f0f0  + f1f9_76 + f2f8_38 + f3f7_76 + f4f6_38 + f5f5_38;
    var h1: i64 = f0f1_2 + f2f9_38 + f3f8_38 + f4f7_38 + f5f6_38;
    var h2: i64 = f0f2_2 + f1f1_2 + f3f9_76 + f4f8_38 + f5f7_76 + f6f6_19;
    var h3: i64 = f0f3_2 + f1f2_2 + f4f9_38 + f5f8_38 + f6f7_38;
    var h4: i64 = f0f4_2 + f1f3_4 + f2f2   + f5f9_76 + f6f8_38 + f7f7_38;
    var h5: i64 = f0f5_2 + f1f4_2 + f2f3_2 + f6f9_38 + f7f8_38;
    var h6: i64 = f0f6_2 + f1f5_4 + f2f4_2 + f3f3_2 + f7f9_76 + f8f8_19;
    var h7: i64 = f0f7_2 + f1f6_2 + f2f5_2 + f3f4_2 + f8f9_38;
    var h8: i64 = f0f8_2 + f1f7_4 + f2f6_2 + f3f5_4 + f4f4   + f9f9_38;
    var h9: i64 = f0f9_2 + f1f8_2 + f2f7_2 + f3f6_2 + f4f5_2;
    var carry0: i64 = undefined;
    var carry1: i64 = undefined;
    var carry2: i64 = undefined;
    var carry3: i64 = undefined;
    var carry4: i64 = undefined;
    var carry5: i64 = undefined;
    var carry6: i64 = undefined;
    var carry7: i64 = undefined;
    var carry8: i64 = undefined;
    var carry9: i64 = undefined;
    carry0 = (h0 + @as(i64, 1 << 25)) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry4 = (h4 + @as(i64, 1 << 25)) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry1 = (h1 + @as(i64, 1 << 24)) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry5 = (h5 + @as(i64, 1 << 24)) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;
    carry2 = (h2 + @as(i64, 1 << 25)) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry6 = (h6 + @as(i64, 1 << 25)) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;
    carry3 = (h3 + @as(i64, 1 << 24)) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry7 = (h7 + @as(i64, 1 << 24)) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;
    carry4 = (h4 + @as(i64, 1 << 25)) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry8 = (h8 + @as(i64, 1 << 25)) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;
    carry9 = (h9 + @as(i64, 1 << 24)) >> 25;
    h0 += carry9 * 19;
    h9 -= carry9 << 25;
    carry0 = (h0 + @as(i64, 1 << 25)) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    h[0] = @as(i32, @intCast(h0));
    h[1] = @as(i32, @intCast(h1));
    h[2] = @as(i32, @intCast(h2));
    h[3] = @as(i32, @intCast(h3));
    h[4] = @as(i32, @intCast(h4));
    h[5] = @as(i32, @intCast(h5));
    h[6] = @as(i32, @intCast(h6));
    h[7] = @as(i32, @intCast(h7));
    h[8] = @as(i32, @intCast(h8));
    h[9] = @as(i32, @intCast(h9));
}






pub fn fe_sq2(h: *Fe, f: Fe) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    const f0_2: i32 = 2 * f0;
    const f1_2: i32 = 2 * f1;
    const f2_2: i32 = 2 * f2;
    const f3_2: i32 = 2 * f3;
    const f4_2: i32 = 2 * f4;
    const f5_2: i32 = 2 * f5;
    const f6_2: i32 = 2 * f6;
    const f7_2: i32 = 2 * f7;
    const f5_38: i32 = 38 * f5;
    const f6_19: i32 = 19 * f6;
    const f7_38: i32 = 38 * f7;
    const f8_19: i32 = 19 * f8;
    const f9_38: i32 = 38 * f9;
    const f0f0: i64 = f0   * @as(i64, f0);
    const f0f1_2: i64 = f0_2 * @as(i64, f1);
    const f0f2_2: i64 = f0_2 * @as(i64, f2);
    const f0f3_2: i64 = f0_2 * @as(i64, f3);
    const f0f4_2: i64 = f0_2 * @as(i64, f4);
    const f0f5_2: i64 = f0_2 * @as(i64, f5);
    const f0f6_2: i64 = f0_2 * @as(i64, f6);
    const f0f7_2: i64 = f0_2 * @as(i64, f7);
    const f0f8_2: i64 = f0_2 * @as(i64, f8);
    const f0f9_2: i64 = f0_2 * @as(i64, f9);
    const f1f1_2: i64 = f1_2 * @as(i64, f1);
    const f1f2_2: i64 = f1_2 * @as(i64, f2);
    const f1f3_4: i64 = f1_2 * @as(i64, f3_2);
    const f1f4_2: i64 = f1_2 * @as(i64, f4);
    const f1f5_4: i64 = f1_2 * @as(i64, f5_2);
    const f1f6_2: i64 = f1_2 * @as(i64, f6);
    const f1f7_4: i64 = f1_2 * @as(i64, f7_2);
    const f1f8_2: i64 = f1_2 * @as(i64, f8);
    const f1f9_76: i64 = f1_2 * @as(i64, f9_38);
    const f2f2: i64 = f2   * @as(i64, f2);
    const f2f3_2: i64 = f2_2 * @as(i64, f3);
    const f2f4_2: i64 = f2_2 * @as(i64, f4);
    const f2f5_2: i64 = f2_2 * @as(i64, f5);
    const f2f6_2: i64 = f2_2 * @as(i64, f6);
    const f2f7_2: i64 = f2_2 * @as(i64, f7);
    const f2f8_38: i64 = f2_2 * @as(i64, f8_19);
    const f2f9_38: i64 = f2   * @as(i64, f9_38);
    const f3f3_2: i64 = f3_2 * @as(i64, f3);
    const f3f4_2: i64 = f3_2 * @as(i64, f4);
    const f3f5_4: i64 = f3_2 * @as(i64, f5_2);
    const f3f6_2: i64 = f3_2 * @as(i64, f6);
    const f3f7_76: i64 = f3_2 * @as(i64, f7_38);
    const f3f8_38: i64 = f3_2 * @as(i64, f8_19);
    const f3f9_76: i64 = f3_2 * @as(i64, f9_38);
    const f4f4: i64 = f4   * @as(i64, f4);
    const f4f5_2: i64 = f4_2 * @as(i64, f5);
    const f4f6_38: i64 = f4_2 * @as(i64, f6_19);
    const f4f7_38: i64 = f4   * @as(i64, f7_38);
    const f4f8_38: i64 = f4_2 * @as(i64, f8_19);
    const f4f9_38: i64 = f4   * @as(i64, f9_38);
    const f5f5_38: i64 = f5   * @as(i64, f5_38);
    const f5f6_38: i64 = f5_2 * @as(i64, f6_19);
    const f5f7_76: i64 = f5_2 * @as(i64, f7_38);
    const f5f8_38: i64 = f5_2 * @as(i64, f8_19);
    const f5f9_76: i64 = f5_2 * @as(i64, f9_38);
    const f6f6_19: i64 = f6   * @as(i64, f6_19);
    const f6f7_38: i64 = f6   * @as(i64, f7_38);
    const f6f8_38: i64 = f6_2 * @as(i64, f8_19);
    const f6f9_38: i64 = f6   * @as(i64, f9_38);
    const f7f7_38: i64 = f7   * @as(i64, f7_38);
    const f7f8_38: i64 = f7_2 * @as(i64, f8_19);
    const f7f9_76: i64 = f7_2 * @as(i64, f9_38);
    const f8f8_19: i64 = f8   * @as(i64, f8_19);
    const f8f9_38: i64 = f8   * @as(i64, f9_38);
    const f9f9_38: i64 = f9   * @as(i64, f9_38);
    var h0: i64 = f0f0  + f1f9_76 + f2f8_38 + f3f7_76 + f4f6_38 + f5f5_38;
    var h1: i64 = f0f1_2 + f2f9_38 + f3f8_38 + f4f7_38 + f5f6_38;
    var h2: i64 = f0f2_2 + f1f1_2 + f3f9_76 + f4f8_38 + f5f7_76 + f6f6_19;
    var h3: i64 = f0f3_2 + f1f2_2 + f4f9_38 + f5f8_38 + f6f7_38;
    var h4: i64 = f0f4_2 + f1f3_4 + f2f2   + f5f9_76 + f6f8_38 + f7f7_38;
    var h5: i64 = f0f5_2 + f1f4_2 + f2f3_2 + f6f9_38 + f7f8_38;
    var h6: i64 = f0f6_2 + f1f5_4 + f2f4_2 + f3f3_2 + f7f9_76 + f8f8_19;
    var h7: i64 = f0f7_2 + f1f6_2 + f2f5_2 + f3f4_2 + f8f9_38;
    var h8: i64 = f0f8_2 + f1f7_4 + f2f6_2 + f3f5_4 + f4f4   + f9f9_38;
    var h9: i64 = f0f9_2 + f1f8_2 + f2f7_2 + f3f6_2 + f4f5_2;
    var carry0: i64 = undefined;
    var carry1: i64 = undefined;
    var carry2: i64 = undefined;
    var carry3: i64 = undefined;
    var carry4: i64 = undefined;
    var carry5: i64 = undefined;
    var carry6: i64 = undefined;
    var carry7: i64 = undefined;
    var carry8: i64 = undefined;
    var carry9: i64 = undefined;
    h0 += h0;
    h1 += h1;
    h2 += h2;
    h3 += h3;
    h4 += h4;
    h5 += h5;
    h6 += h6;
    h7 += h7;
    h8 += h8;
    h9 += h9;
    carry0 = (h0 + @as(i64, 1 << 25)) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry4 = (h4 + @as(i64, 1 << 25)) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry1 = (h1 + @as(i64, 1 << 24)) >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry5 = (h5 + @as(i64, 1 << 24)) >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;
    carry2 = (h2 + @as(i64, 1 << 25)) >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry6 = (h6 + @as(i64, 1 << 25)) >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;
    carry3 = (h3 + @as(i64, 1 << 24)) >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry7 = (h7 + @as(i64, 1 << 24)) >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;
    carry4 = (h4 + @as(i64, 1 << 25)) >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry8 = (h8 + @as(i64, 1 << 25)) >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;
    carry9 = (h9 + @as(i64, 1 << 24)) >> 25;
    h0 += carry9 * 19;
    h9 -= carry9 << 25;
    carry0 = (h0 + @as(i64, 1 << 25)) >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    h[0] = @as(i32, @intCast(h0));
    h[1] = @as(i32, @intCast(h1));
    h[2] = @as(i32, @intCast(h2));
    h[3] = @as(i32, @intCast(h3));
    h[4] = @as(i32, @intCast(h4));
    h[5] = @as(i32, @intCast(h5));
    h[6] = @as(i32, @intCast(h6));
    h[7] = @as(i32, @intCast(h7));
    h[8] = @as(i32, @intCast(h8));
    h[9] = @as(i32, @intCast(h9));
}




pub fn fe_sub(h: *Fe, f: Fe, g: Fe) void {
    const f0: i32 = f[0];
    const f1: i32 = f[1];
    const f2: i32 = f[2];
    const f3: i32 = f[3];
    const f4: i32 = f[4];
    const f5: i32 = f[5];
    const f6: i32 = f[6];
    const f7: i32 = f[7];
    const f8: i32 = f[8];
    const f9: i32 = f[9];
    const g0: i32 = g[0];
    const g1: i32 = g[1];
    const g2: i32 = g[2];
    const g3: i32 = g[3];
    const g4: i32 = g[4];
    const g5: i32 = g[5];
    const g6: i32 = g[6];
    const g7: i32 = g[7];
    const g8: i32 = g[8];
    const g9: i32 = g[9];
    const h0: i32 = f0 - g0;
    const h1: i32 = f1 - g1;
    const h2: i32 = f2 - g2;
    const h3: i32 = f3 - g3;
    const h4: i32 = f4 - g4;
    const h5: i32 = f5 - g5;
    const h6: i32 = f6 - g6;
    const h7: i32 = f7 - g7;
    const h8: i32 = f8 - g8;
    const h9: i32 = f9 - g9;

    h[0] = h0;
    h[1] = h1;
    h[2] = h2;
    h[3] = h3;
    h[4] = h4;
    h[5] = h5;
    h[6] = h6;
    h[7] = h7;
    h[8] = h8;
    h[9] = h9;
}





pub fn fe_tobytes(s: []u8, h: Fe) void {
    var h0: i32 = h[0];
    var h1: i32 = h[1];
    var h2: i32 = h[2];
    var h3: i32 = h[3];
    var h4: i32 = h[4];
    var h5: i32 = h[5];
    var h6: i32 = h[6];
    var h7: i32 = h[7];
    var h8: i32 = h[8];
    var h9: i32 = h[9];
    var q: i32 = undefined;
    var carry0: i32 = undefined;
    var carry1: i32 = undefined;
    var carry2: i32 = undefined;
    var carry3: i32 = undefined;
    var carry4: i32 = undefined;
    var carry5: i32 = undefined;
    var carry6: i32 = undefined;
    var carry7: i32 = undefined;
    var carry8: i32 = undefined;
    var carry9: i32 = undefined;
    q = (19 * h9 + (1 << 24)) >> 25;
    q = (h0 + q) >> 26;
    q = (h1 + q) >> 25;
    q = (h2 + q) >> 26;
    q = (h3 + q) >> 25;
    q = (h4 + q) >> 26;
    q = (h5 + q) >> 25;
    q = (h6 + q) >> 26;
    q = (h7 + q) >> 25;
    q = (h8 + q) >> 26;
    q = (h9 + q) >> 25;

    h0 += 19 * q;

    carry0 = h0 >> 26;
    h1 += carry0;
    h0 -= carry0 << 26;
    carry1 = h1 >> 25;
    h2 += carry1;
    h1 -= carry1 << 25;
    carry2 = h2 >> 26;
    h3 += carry2;
    h2 -= carry2 << 26;
    carry3 = h3 >> 25;
    h4 += carry3;
    h3 -= carry3 << 25;
    carry4 = h4 >> 26;
    h5 += carry4;
    h4 -= carry4 << 26;
    carry5 = h5 >> 25;
    h6 += carry5;
    h5 -= carry5 << 25;
    carry6 = h6 >> 26;
    h7 += carry6;
    h6 -= carry6 << 26;
    carry7 = h7 >> 25;
    h8 += carry7;
    h7 -= carry7 << 25;
    carry8 = h8 >> 26;
    h9 += carry8;
    h8 -= carry8 << 26;
    carry9 = h9 >> 25;
    h9 -= carry9 << 25;



    s[0] = @as(u8, @truncate(@as(u32, @bitCast(h0)) >> 0));
    s[1] = @as(u8, @truncate(@as(u32, @bitCast(h0)) >> 8));
    s[2] = @as(u8, @truncate(@as(u32, @bitCast(h0)) >> 16));
    s[3] = @as(u8, @truncate((@as(u32, @bitCast(h0)) >> 24) | (@as(u32, @bitCast(h1)) << 2)));
    s[4] = @as(u8, @truncate(@as(u32, @bitCast(h1)) >> 6));
    s[5] = @as(u8, @truncate(@as(u32, @bitCast(h1)) >> 14));
    s[6] = @as(u8, @truncate((@as(u32, @bitCast(h1)) >> 22) | (@as(u32, @bitCast(h2)) << 3)));
    s[7] = @as(u8, @truncate(@as(u32, @bitCast(h2)) >> 5));
    s[8] = @as(u8, @truncate(@as(u32, @bitCast(h2)) >> 13));
    s[9] = @as(u8, @truncate((@as(u32, @bitCast(h2)) >> 21) | (@as(u32, @bitCast(h3)) << 5)));
    s[10] = @as(u8, @truncate(@as(u32, @bitCast(h3)) >> 3));
    s[11] = @as(u8, @truncate(@as(u32, @bitCast(h3)) >> 11));
    s[12] = @as(u8, @truncate((@as(u32, @bitCast(h3)) >> 19) | (@as(u32, @bitCast(h4)) << 6)));
    s[13] = @as(u8, @truncate(@as(u32, @bitCast(h4)) >> 2));
    s[14] = @as(u8, @truncate(@as(u32, @bitCast(h4)) >> 10));
    s[15] = @as(u8, @truncate(@as(u32, @bitCast(h4)) >> 18));
    s[16] = @as(u8, @truncate(@as(u32, @bitCast(h5)) >> 0));
    s[17] = @as(u8, @truncate(@as(u32, @bitCast(h5)) >> 8));
    s[18] = @as(u8, @truncate(@as(u32, @bitCast(h5)) >> 16));
    s[19] = @as(u8, @truncate((@as(u32, @bitCast(h5)) >> 24) | (@as(u32, @bitCast(h6)) << 1)));
    s[20] = @as(u8, @truncate(@as(u32, @bitCast(h6)) >> 7));
    s[21] = @as(u8, @truncate(@as(u32, @bitCast(h6)) >> 15));
    s[22] = @as(u8, @truncate((@as(u32, @bitCast(h6)) >> 23) | (@as(u32, @bitCast(h7)) << 3)));
    s[23] = @as(u8, @truncate(@as(u32, @bitCast(h7)) >> 5));
    s[24] = @as(u8, @truncate(@as(u32, @bitCast(h7)) >> 13));
    s[25] = @as(u8, @truncate((@as(u32, @bitCast(h7)) >> 21) | (@as(u32, @bitCast(h8)) << 4)));
    s[26] = @as(u8, @truncate(@as(u32, @bitCast(h8)) >> 4));
    s[27] = @as(u8, @truncate(@as(u32, @bitCast(h8)) >> 12));
    s[28] = @as(u8, @truncate((@as(u32, @bitCast(h8)) >> 20) | (@as(u32, @bitCast(h9)) << 6)));
    s[29] = @as(u8, @truncate(@as(u32, @bitCast(h9)) >> 2));
    s[30] = @as(u8, @truncate(@as(u32, @bitCast(h9)) >> 10));
    s[31] = @as(u8, @truncate(@as(u32, @bitCast(h9)) >> 18));
}

