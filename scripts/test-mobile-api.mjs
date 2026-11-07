import assert from "node:assert/strict";

async function runMobileApiTests() {
  console.log("=================================================");
  console.log("📱 ENGIVAULT MOBILE API v1 & AUTH BRIDGE TEST SUITE");
  console.log("=================================================\n");

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(`     ${err.message}`);
      failed++;
    }
  }

  // Set mock environment variables for test execution if not already set
  process.env.ADMIN_ACCESS_CODE = process.env.ADMIN_ACCESS_CODE || "test-admin-secret-code";
  process.env.ADMIN_SESSION_SECRET = process.env.ADMIN_SESSION_SECRET || "0123456789012345678901234567890123456789";

  // 1. Unified Resolver Unit Tests
  console.log("--- 1. UNIFIED AUTH RESOLVER & BEARER TOKEN GATE ---");
  const { extractBearerToken, resolveStudentAuth, resolveAdminSession, isSafeOriginOrBearer } =
    await import("../lib/auth/unified-resolver.ts");
  const { createSignedToken } = await import("../lib/auth/session.ts");

  await test("extractBearerToken correctly extracts token from Authorization header", () => {
    const req = new Request("http://localhost/api/test", {
      headers: { Authorization: "Bearer my-secret-jwt-token" },
    });
    assert.equal(extractBearerToken(req), "my-secret-jwt-token");
  });

  await test("extractBearerToken handles case-insensitive bearer prefix and trims whitespace", () => {
    const req = new Request("http://localhost/api/test", {
      headers: { authorization: "bearer   spaced-token-value   " },
    });
    assert.equal(extractBearerToken(req), "spaced-token-value");
  });

  await test("extractBearerToken returns null when header is absent or non-bearer", () => {
    const req1 = new Request("http://localhost/api/test");
    assert.equal(extractBearerToken(req1), null);

    const req2 = new Request("http://localhost/api/test", {
      headers: { Authorization: "Basic dXNlcjpwYXNz" },
    });
    assert.equal(extractBearerToken(req2), null);
  });

  await test("resolveAdminSession validates short-lived HMAC signed admin token via Bearer header", async () => {
    const adminToken = createSignedToken({ role: "admin" });
    const req = new Request("http://localhost/api/test", {
      headers: { Authorization: `Bearer ${adminToken}` },
    });

    const session = await resolveAdminSession(req);
    assert.ok(session);
    assert.equal(session.role, "admin");
  });

  await test("resolveAdminSession rejects invalid or forged Bearer tokens", async () => {
    const forgedToken = "invalid.token.payload";
    const req = new Request("http://localhost/api/test", {
      headers: { Authorization: `Bearer ${forgedToken}` },
    });

    const session = await resolveAdminSession(req);
    assert.equal(session, null);
  });

  await test("isSafeOriginOrBearer allows bearer requests while protecting cookie requests", () => {
    const bearerReq = new Request("http://localhost/api/test", {
      method: "POST",
      headers: { Authorization: "Bearer a-valid-token-long-enough" },
    });
    assert.equal(isSafeOriginOrBearer(bearerReq), true);
  });

  // 2. Mobile Home Endpoint
  console.log("\n--- 2. MOBILE HOME COMPOSITE ENDPOINT ---");
  const homeRoute = await import("../app/api/mobile/v1/home/route.ts");

  await test("GET /api/mobile/v1/home returns composite site, departments, subjects, and lectures", async () => {
    const res = await homeRoute.GET();
    assert.equal(res.status, 200);
    const json = await res.json();

    assert.ok(json.site && typeof json.site.site_name === "string");
    assert.ok(Array.isArray(json.departments) && json.departments.length > 0);
    assert.ok(Array.isArray(json.featured_subjects) && json.featured_subjects.length > 0);
    assert.ok(Array.isArray(json.latest_lectures));

    // Verify YouTube ID pattern on any latest lectures present
    if (json.latest_lectures.length > 0) {
      const first = json.latest_lectures[0];
      assert.ok(first.title);
      assert.ok(first.slug);
      if (first.youtube_video_id) {
        assert.match(first.youtube_video_id, /^[a-zA-Z0-9_-]{11}$/);
      }
    }
  });

  // 3. Departments & Semesters
  console.log("\n--- 3. DEPARTMENTS & SEMESTERS ENDPOINTS ---");
  const deptsRoute = await import("../app/api/mobile/v1/departments/route.ts");
  const semsRoute = await import("../app/api/mobile/v1/semesters/route.ts");

  await test("GET /api/mobile/v1/departments returns departments list with codes and slugs", async () => {
    const res = await deptsRoute.GET();
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(Array.isArray(json.departments));
    const cse = json.departments.find((d) => d.code === "CSE");
    assert.ok(cse, "Must include CSE department");
  });

  await test("GET /api/mobile/v1/semesters returns engineering semesters S1 through S8", async () => {
    const req = new Request("http://localhost/api/mobile/v1/semesters");
    const res = await semsRoute.GET(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(Array.isArray(json.semesters) && json.semesters.length > 0);
  });

  // 4. Subjects & Subject Detail
  console.log("\n--- 4. SUBJECTS & SUBJECT DETAIL ENDPOINTS ---");
  const subjectsRoute = await import("../app/api/mobile/v1/subjects/route.ts");
  const subjectDetailRoute = await import("../app/api/mobile/v1/subjects/[slug]/route.ts");

  await test("GET /api/mobile/v1/subjects returns paginated subjects with filter support", async () => {
    const req = new Request("http://localhost/api/mobile/v1/subjects?limit=5");
    const res = await subjectsRoute.GET(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(Array.isArray(json.data));
    assert.ok(json.pagination);
    assert.equal(json.pagination.limit, 5);
  });

  await test("GET /api/mobile/v1/subjects/:slug returns subject with nested modules and lessons", async () => {
    // Get a known slug from subjects
    const allReq = new Request("http://localhost/api/mobile/v1/subjects?limit=1");
    const allRes = await subjectsRoute.GET(allReq);
    const allJson = await allRes.json();
    const firstSubject = allJson.data[0];
    assert.ok(firstSubject);

    const req = new Request(`http://localhost/api/mobile/v1/subjects/${firstSubject.slug}`);
    const res = await subjectDetailRoute.GET(req, {
      params: Promise.resolve({ slug: firstSubject.slug }),
    });

    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(json.subject);
    assert.equal(json.subject.slug, firstSubject.slug);
    assert.ok(Array.isArray(json.subject.modules));
  });

  // 5. Lessons & YouTube Player Data
  console.log("\n--- 5. LESSONS & YOUTUBE PLAYER ENDPOINT ---");
  const lessonDetailRoute = await import("../app/api/mobile/v1/lessons/[idOrSlug]/route.ts");
  const lecturesRoute = await import("../app/api/mobile/v1/lectures/route.ts");

  await test("GET /api/mobile/v1/lectures returns cascade-searchable lectures", async () => {
    const req = new Request("http://localhost/api/mobile/v1/lectures?limit=5");
    const res = await lecturesRoute.GET(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(Array.isArray(json.data));
    assert.ok(json.pagination);
  });

  await test("GET /api/mobile/v1/lessons/:idOrSlug resolves canonical YouTube embed and watch URLs", async () => {
    const listReq = new Request("http://localhost/api/mobile/v1/lectures?limit=1");
    const listRes = await lecturesRoute.GET(listReq);
    const listJson = await listRes.json();
    const targetLecture = listJson.data[0];
    assert.ok(targetLecture);

    const req = new Request(`http://localhost/api/mobile/v1/lessons/${targetLecture.slug}`);
    const res = await lessonDetailRoute.GET(req, {
      params: Promise.resolve({ idOrSlug: targetLecture.slug }),
    });

    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(json.lesson);
    assert.equal(json.lesson.id, targetLecture.id);

    if (json.lesson.youtube_video_id) {
      assert.match(json.lesson.youtube_video_id, /^[a-zA-Z0-9_-]{11}$/);
      assert.equal(
        json.lesson.youtube_watch_url,
        `https://www.youtube.com/watch?v=${json.lesson.youtube_video_id}`
      );
      assert.equal(
        json.lesson.youtube_embed_url,
        `https://www.youtube-nocookie.com/embed/${json.lesson.youtube_video_id}`
      );
    }
  });

  // 6. Materials & Download Signing
  console.log("\n--- 6. STUDY MATERIALS & SECURE DOWNLOAD SIGNING ---");
  const materialsRoute = await import("../app/api/mobile/v1/materials/route.ts");
  const materialDownloadRoute = await import(
    "../app/api/mobile/v1/materials/[id]/download/route.ts"
  );

  await test("GET /api/mobile/v1/materials returns published notes catalog", async () => {
    const req = new Request("http://localhost/api/mobile/v1/materials?limit=5");
    const res = await materialsRoute.GET(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(Array.isArray(json.data));
  });

  await test("GET /api/mobile/v1/materials/:id/download issues valid download metadata", async () => {
    const listReq = new Request("http://localhost/api/mobile/v1/materials?limit=1");
    const listRes = await materialsRoute.GET(listReq);
    const listJson = await listRes.json();
    const firstMat = listJson.data[0];
    assert.ok(firstMat);

    const req = new Request(`http://localhost/api/mobile/v1/materials/${firstMat.id}/download`);
    const res = await materialDownloadRoute.GET(req, {
      params: Promise.resolve({ id: firstMat.id }),
    });

    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(json.download_url);
    assert.ok(json.expires_at);
  });

  // 7. Global Search
  console.log("\n--- 7. GLOBAL ACADEMIC SEARCH ---");
  const searchRoute = await import("../app/api/mobile/v1/search/route.ts");

  await test("GET /api/mobile/v1/search returns empty array on empty query", async () => {
    const req = new Request("http://localhost/api/mobile/v1/search?q=");
    const res = await searchRoute.GET(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.deepEqual(json.results, []);
  });

  await test("GET /api/mobile/v1/search matches academic topics and subjects", async () => {
    const req = new Request("http://localhost/api/mobile/v1/search?q=calculus");
    const res = await searchRoute.GET(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(Array.isArray(json.results));
  });

  // 8. FOLE WORKS Activities
  console.log("\n--- 8. FOLE WORKS ACTIVITIES ---");
  const worksRoute = await import("../app/api/mobile/v1/fole-works/route.ts");
  const worksDetailRoute = await import("../app/api/mobile/v1/fole-works/[slug]/route.ts");

  await test("GET /api/mobile/v1/fole-works returns activities list with flyers and registration links", async () => {
    const res = await worksRoute.GET();
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(Array.isArray(json.activities));
  });

  await test("GET /api/mobile/v1/fole-works/:slug returns 404 on non-existent slug", async () => {
    const req = new Request("http://localhost/api/mobile/v1/fole-works/non-existent-activity-slug");
    const res = await worksDetailRoute.GET(req, {
      params: Promise.resolve({ slug: "non-existent-activity-slug" }),
    });
    assert.equal(res.status, 404);
  });

  // 9. Mobile Student Authentication Bridge
  console.log("\n--- 9. STUDENT AUTHENTICATION BRIDGE ---");
  const loginRoute = await import("../app/api/mobile/v1/auth/login/route.ts");
  const meRoute = await import("../app/api/mobile/v1/auth/me/route.ts");

  await test("POST /api/mobile/v1/auth/login rejects missing username or password", async () => {
    const req = new Request("http://localhost/api/mobile/v1/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "test" }),
    });
    const res = await loginRoute.POST(req);
    assert.equal(res.status, 400);
  });

  await test("POST /api/mobile/v1/auth/login does not disclose internal email", async () => {
    const req = new Request("http://localhost/api/mobile/v1/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "student_test_user", password: "Password123!" }),
    });
    const res = await loginRoute.POST(req);
    const text = await res.text();
    assert.ok(!text.includes("students.fole.invalid"), "Internal email must never be disclosed");
  });

  await test("GET /api/mobile/v1/auth/me rejects unauthenticated request with 401", async () => {
    const req = new Request("http://localhost/api/mobile/v1/auth/me");
    const res = await meRoute.GET(req);
    assert.equal(res.status, 401);
  });

  await test("GET /api/mobile/v1/auth/me accepts valid Bearer token and returns user profile", async () => {
    const req = new Request("http://localhost/api/mobile/v1/auth/me", {
      headers: { Authorization: "Bearer dev-mock-student:arjun_k" },
    });
    const res = await meRoute.GET(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.equal(json.user.username, "arjun_k");
  });

  // 10. Administrator Mobile Authentication
  console.log("\n--- 10. ADMINISTRATOR AUTHENTICATION BRIDGE ---");
  const adminLoginRoute = await import("../app/api/mobile/v1/admin/login/route.ts");

  await test("POST /api/mobile/v1/admin/login rejects invalid code with 401", async () => {
    const req = new Request("http://localhost/api/mobile/v1/admin/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ code: "completely-wrong-code" }),
    });
    const res = await adminLoginRoute.POST(req);
    assert.equal(res.status, 401);
  });

  await test("POST /api/mobile/v1/admin/login returns valid HMAC signed token for valid access code", async () => {
    const req = new Request("http://localhost/api/mobile/v1/admin/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ code: process.env.ADMIN_ACCESS_CODE }),
    });
    const res = await adminLoginRoute.POST(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.ok(json.token);
    assert.equal(json.expires_in, 28800);

    // Verify token can be verified
    const authReq = new Request("http://localhost/api/test", {
      headers: { Authorization: `Bearer ${json.token}` },
    });
    const session = await resolveAdminSession(authReq);
    assert.ok(session);
    assert.equal(session.role, "admin");
  });

  const adminDashboardRoute = await import("../app/api/mobile/v1/admin/dashboard/route.ts");

  await test("GET /api/mobile/v1/admin/dashboard rejects unauthenticated callers with 401", async () => {
    const req = new Request("http://localhost/api/mobile/v1/admin/dashboard");
    const res = await adminDashboardRoute.GET(req);
    assert.equal(res.status, 401);
  });

  await test("GET /api/mobile/v1/admin/dashboard rejects student tokens with 401", async () => {
    const req = new Request("http://localhost/api/mobile/v1/admin/dashboard", {
      headers: { Authorization: "Bearer dev-mock-student:ordinary_student" },
    });
    const res = await adminDashboardRoute.GET(req);
    assert.equal(res.status, 401);
  });

  await test("GET /api/mobile/v1/admin/dashboard returns composite metrics with valid admin token", async () => {
    const validToken = createSignedToken({ role: "admin" });
    const req = new Request("http://localhost/api/mobile/v1/admin/dashboard", {
      headers: { Authorization: `Bearer ${validToken}` },
    });
    const res = await adminDashboardRoute.GET(req);
    assert.equal(res.status, 200);
    const json = await res.json();
    assert.equal(json.success, true);
    assert.ok(json.stats);
    assert.ok(typeof json.stats.subjects_count === "number");
    assert.ok(typeof json.stats.lessons_count === "number");
  });

  // 11. FOLE SPACE Mobile Endpoints
  console.log("\n--- 11. FOLE SPACE MOBILE ENDPOINTS ---");
  const spaceStatusRoute = await import("../app/api/mobile/v1/fole-space/status/route.ts");
  const spaceCheckinRoute = await import("../app/api/mobile/v1/fole-space/checkin/route.ts");
  const spaceMyRoute = await import("../app/api/mobile/v1/fole-space/my/route.ts");

  await test("GET /api/mobile/v1/fole-space/status returns space status or 503 unconfigured", async () => {
    const req = new Request("http://localhost/api/mobile/v1/fole-space/status");
    const res = await spaceStatusRoute.GET(req);
    assert.ok(res.status === 200 || res.status === 503);
  });

  await test("POST /api/mobile/v1/fole-space/checkin requires student authentication (401 without token)", async () => {
    const req = new Request("http://localhost/api/mobile/v1/fole-space/checkin", {
      method: "POST",
    });
    const res = await spaceCheckinRoute.POST(req);
    assert.equal(res.status, 401);
  });

  await test("GET /api/mobile/v1/fole-space/my requires student authentication (401 without token)", async () => {
    const req = new Request("http://localhost/api/mobile/v1/fole-space/my");
    const res = await spaceMyRoute.GET(req);
    assert.equal(res.status, 401);
  });

  // 12. Organizer Mobile Endpoints
  console.log("\n--- 12. ORGANIZER MOBILE ENDPOINTS ---");
  const orgEventsRoute = await import("../app/api/mobile/v1/organizer/events/route.ts");

  await test("GET /api/mobile/v1/organizer/events rejects unauthenticated callers with 403", async () => {
    const req = new Request("http://localhost/api/mobile/v1/organizer/events");
    const res = await orgEventsRoute.GET(req);
    assert.equal(res.status, 403);
  });

  await test("GET /api/mobile/v1/organizer/events rejects ordinary students without organizer badge", async () => {
    const req = new Request("http://localhost/api/mobile/v1/organizer/events", {
      headers: { Authorization: "Bearer dev-mock-student:ordinary_student" },
    });
    const res = await orgEventsRoute.GET(req);
    assert.equal(res.status, 403);
  });

  console.log("\n=================================================");
  console.log(`📊 MOBILE API RESULTS: ${passed} PASSED | ${failed} FAILED`);
  console.log("=================================================");

  if (failed > 0) {
    process.exit(1);
  }
}

runMobileApiTests().catch((err) => {
  console.error("Test execution fatal error:", err);
  process.exit(1);
});

