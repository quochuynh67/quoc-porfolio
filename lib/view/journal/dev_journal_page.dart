import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../media_tool/video_editor/domain/shader_catalog.dart';
import '../media_tool/video_editor/presentation/gl_transition_view.dart';

class JournalArticle {
  const JournalArticle({
    required this.title,
    required this.summary,
    required this.category,
    required this.tags,
    required this.readTime,
    required this.date,
    required this.icon,
    required this.content,
    this.heroImage,
    this.heroCaption,
    this.featured = false,
    this.interactiveShaderGallery = false,
  });

  final String title;
  final String summary;
  final String category;
  final List<String> tags;
  final String readTime;
  final String date;
  final IconData icon;
  final List<(String, String)> content;
  final String? heroImage;
  final String? heroCaption;
  final bool featured;
  final bool interactiveShaderGallery;
}

const _articles = <JournalArticle>[
  JournalArticle(
    title: 'Vibe coding nhưng vẫn giữ chất lượng kỹ thuật',
    summary:
        'Workflow dùng AI để tăng tốc mà không giao toàn bộ tư duy, bảo mật và chất lượng cho AI.',
    category: 'Vibe Coding',
    tags: ['AI workflow', 'Review', 'Quality'],
    readTime: '8 phút đọc',
    date: '25 Thg 11, 2026',
    icon: Icons.auto_awesome_rounded,
    featured: true,
    content: [
      (
        'AI là pair programmer, không phải người chịu trách nhiệm',
        'Tôi dùng AI để khám phá giải pháp, tạo bản nháp và làm các phần lặp lại. Quyết định kiến trúc, dữ liệu, bảo mật và trải nghiệm cuối cùng vẫn phải do lập trình viên sở hữu.'
      ),
      (
        'Workflow tôi đang sử dụng',
        'Bắt đầu bằng mục tiêu và ràng buộc rõ ràng. Cho AI đọc context tối thiểu cần thiết, yêu cầu thay đổi nhỏ, chạy analyzer và build, sau đó review diff trước khi commit. Với logic quan trọng, luôn kiểm thử bằng dữ liệu thật.'
      ),
      (
        'Những lỗi AI thường tạo ra',
        'AI dễ tạo code chạy được nhưng khó mở rộng, lặp logic, để lộ key, giả định package API hoặc bỏ qua trạng thái loading/error. Checklist review cần bao phủ các điểm này thay vì chỉ nhìn UI đẹp.'
      ),
      (
        'Bài học lớn nhất',
        'Tốc độ chỉ có giá trị khi thay đổi vẫn kiểm chứng được. Một phiên vibe coding tốt phải kết thúc bằng source dễ hiểu, build xanh và một người có thể giải thích tại sao giải pháp đó đúng.'
      ),
    ],
  ),
  JournalArticle(
    title: 'Superpowers: biến AI coding thành một quy trình kỹ thuật',
    summary:
        'Ghi chép học Superpowers từ con số 0: cách bắt đầu dự án mới, feature mới và một bài thực hành cụ thể với 67Talk.',
    category: 'Vibe Coding',
    tags: ['Superpowers', 'Agent Skills', 'TDD', 'Planning', '67Talk'],
    readTime: '48 phút đọc',
    date: '26 Thg 11, 2026',
    icon: Icons.bolt_rounded,
    featured: true,
    content: [
      (
        'Superpowers là gì?',
        'Superpowers không phải model AI mới hay bộ prompt để “code nhanh hơn”. Đây là framework agent skills kết hợp một phương pháp phát triển phần mềm. Nó yêu cầu coding agent khám phá nhu cầu, trình bày thiết kế, lập kế hoạch, dùng TDD, review và xác minh thay vì nhận yêu cầu rồi viết code ngay.\n\nWorkflow chính thức gồm brainstorming → worktree → writing plans → executing plans hoặc subagent-driven development → TDD → code review → finishing branch. Triết lý xuyên suốt là hệ thống thay cho ứng biến, đơn giản thay cho phức tạp và bằng chứng thay cho tuyên bố.\n\nNguồn chính thức: [obra/superpowers](https://github.com/obra/superpowers) và [Basic workflow](https://github.com/obra/superpowers#the-basic-workflow).'
      ),
      (
        'Vì sao vibe coding thường thất bại?',
        'AI có thể tạo một màn hình đẹp trong vài phút nhưng bỏ sót những câu quyết định chất lượng: ai sử dụng, lỗi được phục hồi thế nào, dữ liệu thuộc tenant nào, hành động nào cần xác nhận và test nào chứng minh feature đúng. Khi prompt mơ hồ, agent tự lấp khoảng trống bằng giả định.\n\nSuperpowers đặt các gates rõ ràng: chưa hiểu nhu cầu thì chưa design; chưa duyệt design thì chưa plan; chưa thấy failing test thì chưa viết production code; chưa có fresh verification thì chưa tuyên bố hoàn thành. Quy trình chậm hơn vài phút đầu nhưng giảm rất nhiều vòng lặp sửa sai.'
      ),
      (
        'Một ghi chú trung thực trước khi bắt đầu',
        'Tại thời điểm viết bài, tôi đang học Superpowers và chưa áp dụng toàn bộ workflow này vào một dự án production hoàn chỉnh. Những phần về workflow được tổng hợp từ repository/tài liệu chính thức; ví dụ 67Talk là bài thực hành đề xuất dựa trên cấu trúc dự án hiện có, không phải case study tuyên bố đã triển khai thành công.\n\nTôi chọn cách ghi lại quá trình học vì nó giúp phân biệt ba thứ: điều dự án Superpowers thực sự yêu cầu, điều tôi hiểu sau khi đọc, và điều chỉ có thể kết luận sau khi tự áp dụng. Người đọc nên xem bài này như một lab có hướng dẫn, rồi kiểm chứng bằng feature nhỏ của chính mình.'
      ),
      (
        'Cài đặt và kiểm tra lần đầu',
        'Trong Codex App, Superpowers có trên plugin marketplace: mở Plugins ở sidebar, tìm Superpowers trong nhóm Coding và cài đặt. Mỗi coding harness có cơ chế cài riêng; cài trong Codex không tự động cài cho Claude Code hay Cursor. Sau khi cài, nên mở một chat mới để bootstrap/skills được nạp đầy đủ.\n\nBài test đơn giản không phải “hãy viết app todo”, mà là yêu cầu agent bắt đầu một sản phẩm còn mơ hồ. Nếu plugin hoạt động đúng, agent phải kích hoạt brainstorming trước khi viết code. Ví dụ: “Tôi muốn làm app ghi chi tiêu cho gia đình.” Agent nên hỏi mục tiêu/người dùng hoặc đề xuất design để duyệt, không lập tức tạo Flutter project.\n\nHướng dẫn cài đặt luôn có thể thay đổi, vì vậy hãy kiểm tra mục [Codex App installation](https://github.com/obra/superpowers#codex-app) trong repository chính thức.'
      ),
      (
        'Start from scratch — Dự án mới bắt đầu thế nào?',
        'Giả sử ta bắt đầu ứng dụng Flutter “Pocket Expense”: nhập khoản chi, phân loại và xem tổng theo tháng. Đừng chạy `flutter create` ngay. Hãy đi theo các artefacts sau:\n\n1. Product intent: ai dùng, vấn đề gì, thành công được đo thế nào.\n2. Brainstorming conversation: scope MVP, dữ liệu, offline/online, platform, privacy.\n3. Approved design: user flow, screens, state, storage, error cases và non-goals.\n4. Implementation plan: task nhỏ, file/interface/test/command rõ ràng.\n5. Isolated worktree và baseline verification.\n6. TDD từng vertical slice.\n7. Review, full verification và quyết định merge/deploy.\n\n```text\nTôi muốn bắt đầu một ứng dụng Flutter quản lý chi tiêu gia đình từ con số 0.\nMục tiêu MVP: thêm khoản chi trong dưới 10 giây và xem tổng theo tháng.\nHãy dùng brainstorming. Đừng tạo project hay code trước khi chúng ta duyệt design.\nSau khi hiểu nhu cầu, hãy đề xuất 2 kiến trúc phù hợp cho offline-first, nêu trade-off và đề xuất một lựa chọn.\n```\n\nKết thúc brainstorming, bạn nên có design document chứ chưa cần code. Sau khi duyệt design, yêu cầu writing-plans tạo plan. Chỉ đến bước execution mới tạo Flutter project, dependencies và test đầu tiên.'
      ),
      (
        'Ví dụ vertical slice đầu tiên cho dự án mới',
        'Vertical slice đầu tiên nên nhỏ nhưng chạy end-to-end: người dùng nhập số tiền + danh mục, bấm Save, dữ liệu được validate và xuất hiện trong danh sách. Chưa cần đăng nhập, cloud sync, chart, AI phân loại hay 20 theme.\n\nTDD có thể bắt đầu từ domain thay vì UI:\n\n```dart\ntest(\'rejects an expense with a non-positive amount\', () {\n  expect(\n    () => Expense.create(amount: 0, category: "Food"),\n    throwsA(isA<InvalidExpense>()),\n  );\n});\n```\n\nSau khi test fail đúng lý do, tạo model tối thiểu để pass. Tiếp theo test repository local, controller state rồi widget form. Mỗi vòng Red–Green–Refactor tạo một phần behavior có bằng chứng. Khi slice chạy được trên thiết bị, mới chọn slice kế tiếp như monthly total.'
      ),
      (
        'Feature mới trong dự án có sẵn bắt đầu thế nào?',
        'Khác biệt lớn nhất là phải đọc trước khi hỏi. Agent cần map code hiện tại, test pattern, data flow và recent changes; không được dùng sở thích kiến trúc chung để thay convention của dự án.\n\n```text\nTrong 67Talk, tôi muốn thêm AI handoff summary.\nTrước tiên chỉ đọc và giải thích luồng handoff hiện tại từ widget → backend → queue → agent workspace.\nLiệt kê file, event và database object liên quan; chỉ ra test hiện có gần nhất.\nSau đó dùng brainstorming để xác định behavior còn thiếu. Chưa sửa code.\n```\n\nSau khi agent trình bày current state, bạn sửa các hiểu lầm trước. Rồi duyệt design, lập plan, tạo worktree và chạy baseline tests. Quy tắc quan trọng: feature mới phải khớp hệ thống đang tồn tại; dự án không nên bị “viết lại âm thầm” chỉ vì agent quen framework khác.'
      ),
      (
        'Superpowers mang lại lợi ích gì?',
        '- Giảm xây sai thứ: brainstorming làm rõ outcome và non-goals trước khi tốn code.\n- Giảm context drift: design/spec/plan là bộ nhớ bên ngoài để agent không đổi hướng giữa chừng.\n- Dễ review: task nhỏ, interface rõ và commit thường xuyên giúp biết thay đổi nào gây lỗi.\n- Test đáng tin hơn: bắt buộc nhìn test fail trước, tránh test viết sau chỉ xác nhận implementation.\n- Debug ít đoán: root cause, evidence và hypothesis thay cho nhiều bản vá cùng lúc.\n- Dễ giao việc: subagent nhận task self-contained, không cần toàn bộ lịch sử chat.\n- Handoff tốt hơn: người khác có thể đọc spec, plan, tests và tiếp tục công việc.\n- Báo cáo trung thực hơn: verification output hỗ trợ tuyên bố thay vì “có vẻ đã ổn”.\n\nLợi ích lớn nhất không phải nhiều code hơn mỗi giờ. Đó là tăng tỷ lệ thay đổi đúng, có thể giải thích và có thể kiểm chứng.'
      ),
      (
        'Chi phí và giới hạn cần biết',
        'Quy trình tạo thêm design docs, plans, tests, review rounds và token usage. Với thay đổi nhỏ, dùng toàn bộ ceremony sẽ chậm và gây mệt. Subagents cũng có thể lặp context hoặc tạo conflict nếu task boundaries kém. TDD không giúp nếu test sai; review không giúp nếu reviewer chỉ lặp lại giả định của implementer.\n\nCách học phù hợp là bắt đầu với một feature 1–2 giờ, không phải dự án lớn. Áp dụng bốn skill trước: brainstorming, writing-plans, TDD và verification. Khi đã quen mới thêm worktrees, systematic debugging và subagent-driven development.'
      ),
      (
        'Lộ trình học 7 ngày thực tế',
        '- Ngày 1: cài plugin, đọc Basic Workflow và chạy một brainstorming không code.\n- Ngày 2: viết design cho app nhỏ, tập nói rõ non-goals và failure cases.\n- Ngày 3: chuyển design thành plan có file/interface/test/command.\n- Ngày 4: làm một domain behavior bằng Red–Green–Refactor.\n- Ngày 5: cố tình tạo bug nhỏ và dùng bốn phase systematic debugging.\n- Ngày 6: chạy verification ladder, ghi evidence và limitation.\n- Ngày 7: làm lại một feature nhỏ trong dự án thật, so sánh số lần rework với cách cũ.\n\nSau tuần đầu, câu hỏi không còn là “Superpowers có hay không?” mà là: gate nào thực sự giảm lỗi cho loại công việc của bạn, gate nào cần rút gọn, và evidence nào team của bạn cần trước khi merge.'
      ),
      (
        'Dự án xuyên suốt: AI handoff summary cho 67Talk',
        'Ta xây một feature cụ thể: khi AI Agent chuyển conversation cho human agent, hệ thống tạo summary gồm vấn đề của visitor, facts đã xác minh, tools đã gọi và bước đề xuất tiếp theo. Nhân viên nhận chat không phải đọc lại toàn bộ lịch sử.\n\nAcceptance criteria:\n\n- Summary chỉ đọc message của đúng company và conversation.\n- Không đưa internal note hoặc secret tool result ra ngoài.\n- Provider lỗi không được chặn handoff; UI dùng fallback summary.\n- Message mới tới khi đang generate không được publish summary cũ.\n- Nhân viên xem được nguồn facts và transcript gốc.\n- Audit log ghi model, config version, latency và token usage.'
      ),
      (
        'Beginner — Brainstorming trước khi code',
        'Skill brainstorming yêu cầu đọc context/code hiện tại trước, sau đó chỉ hỏi điều thật sự thay đổi sản phẩm. Với feature này, agent phải đọc handoff flow, conversation store, Supabase Edge Function và realtime events của 67Talk trước khi hỏi.\n\nCâu hỏi tốt: “Summary được tạo trước khi conversation vào queue hay sau khi nhân viên nhận?” Câu trả lời thay đổi latency và ownership. Câu hỏi kém: “Dùng React hay Flutter?” vì codebase đã trả lời React/TypeScript.\n\nThiết kế hợp lý: handoff không chờ AI; database tạo summary job bất đồng bộ; UI hiển thị Preparing summary; realtime event cập nhật khi xong. Provider chậm sẽ không cản visitor gặp người thật. Đọc thêm [brainstorming skill](https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md).'
      ),
      (
        'Beginner — Prompt thực hành và design gate',
        '```text\nTôi muốn thêm AI handoff summary vào 67Talk.\nTrước khi code, hãy đọc handoff flow, ai_reply_outbox, conversation store và realtime subscription.\nDùng brainstorming để nêu các quyết định còn thiếu, đề xuất hai phương án kèm trade-off, rồi viết design ngắn để tôi duyệt.\nKhông triển khai trước khi design được chấp thuận.\n```\n\nOutput cần kiểm chứng được: user journey, data flow, state, failure modes, security boundary và quyết định đã duyệt. Một đoạn mô tả “thêm API rồi gọi từ UI” chưa phải design.'
      ),
      (
        'Beginner — Writing Plans đủ chi tiết để thi hành',
        'Plan không phải checklist “làm backend, làm UI, test”. Nó phải đủ rõ cho engineer chưa biết codebase: file chính xác, interface, failing test, command chạy và expected result. Mỗi task là deliverable có thể review độc lập.\n\n```markdown\n### Task 1: Create handoff summary job\nFiles:\n- Create: supabase/migrations/..._handoff_summary_jobs.sql\n- Test: supabase/tests/handoff_summary_jobs.test.sql\nInterface:\n- Produces: enqueue_handoff_summary(conversation_id bigint)\nSteps:\n1. Write a failing tenant-isolation test.\n2. Run it and verify the expected failure.\n3. Add table, RLS and enqueue function.\n4. Run focused test, then full database suite.\n5. Commit.\n```\n\nSuperpowers đề xuất plan có Goal, Architecture, Tech Stack, Spec, global constraints và review focus. Xem [writing-plans](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md).'
      ),
      (
        'Intermediate — TDD Red–Green–Refactor',
        'Luật cứng của skill TDD là không có production code trước failing test. RED phải được chạy và fail đúng lý do. Nếu test pass ngay, nó đang kiểm behavior cũ hoặc không kiểm điều bạn tưởng. GREEN là implementation tối thiểu; REFACTOR chỉ bắt đầu khi test xanh.\n\n```typescript\nit(\'excludes internal notes from handoff context\', () => {\n  const messages = [\n    visitor(\'My order is late\'),\n    internalNote(\'VIP; offer voucher\'),\n    agent(\'I am checking it now\'),\n  ];\n  const context = buildHandoffContext(messages);\n  expect(context).toContain(\'My order is late\');\n  expect(context).not.toContain(\'offer voucher\');\n});\n```\n\nSau khi thấy test fail vì internal note bị đưa vào context, code tối thiểu là filter đúng visibility. Không tiện tay thêm caching, retry hay abstraction chưa được test yêu cầu. Đó là YAGNI. Xem [TDD skill](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md).'
      ),
      (
        'Intermediate — Debugging dựa trên bằng chứng',
        'Giả sử cùng một handoff summary xuất hiện hai lần. Cách sửa triệu chứng là debounce UI. Systematic debugging bắt đầu bằng root cause investigation.\n\n- Investigation: tái hiện; log job id tại trigger, Edge Function claim và realtime publish.\n- Pattern analysis: so với ai_reply_outbox đang giới hạn một active job mỗi conversation.\n- Hypothesis: hai trigger cùng enqueue khi handoff đổi status và assigned_agent_id.\n- Implementation: failing integration test; unique active-job constraint/idempotency key tại nguồn; chạy focused và full suite.\n\n> Debounce UI không ngăn hai provider calls, không hoàn token và không bảo vệ client khác.\n\nNếu ba lần fix thất bại, skill yêu cầu dừng và xem lại kiến trúc thay vì chồng bản vá thứ tư. Xem [systematic-debugging](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md).'
      ),
      (
        'Intermediate — Verification trước khi nói “đã xong”',
        'Fresh evidence phải nằm trong phiên làm việc hiện tại. Verification ladder cho feature ví dụ:\n\n- Unit test cho context builder.\n- Database/RLS test cho tenant isolation và idempotency.\n- Edge Function integration test cho provider failure và stale job.\n- Frontend test cho loading, completed và fallback state.\n- Full npm test, lint và production build.\n- Manual flow visitor → AI → handoff → queue → agent opens conversation.\n\nNếu full suite có test đỏ không liên quan, phải báo rõ tên test. Không được im lặng và tuyên bố toàn bộ xanh. Đọc [verification-before-completion](https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md).'
      ),
      (
        'Advanced — Worktree và Subagent-driven Development',
        'Worktree cô lập feature khỏi nhánh chính và giữ baseline tests rõ ràng. Sau khi spec/plan ổn, mỗi task có thể giao một subagent mới để tránh context pollution. Mỗi task qua hai gate: spec compliance trước, code quality sau.\n\n```bash\ngit worktree add ../67talk-handoff-summary -b feature/handoff-summary\ncd ../67talk-handoff-summary\nnpm install\nnpm test\n```\n\nTask decomposition hợp lý:\n\n1. Database: schema, RLS, enqueue/idempotency.\n2. AI runtime: context, prompt, settlement, stale protection.\n3. Realtime contract: event schema/publication.\n4. Agent UI: summary card, citations, fallback/loading.\n5. E2E/evals: golden conversations, provider failure, race conditions.\n\nKhông chạy song song tasks cùng sửa một file hoặc dùng interface chưa chốt. Xem [subagent-driven-development](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md).'
      ),
      (
        'Advanced — Evals cho feature AI',
        'TDD kiểm code; evals kiểm chất lượng model. Với handoff summary, tạo dataset conversation đã ẩn danh cùng expected facts và forbidden facts. Đo factual coverage, hallucination, PII/internal-note leakage, latency, token cost và tỷ lệ human phải sửa.\n\n```yaml\ncase: delayed_order_urgent\nexpected_facts:\n  - order NS1042 is delayed\n  - visitor needs it tomorrow\nforbidden:\n  - internal VIP note\n  - full phone number\nexpected_next_action: check urgent pickup or replacement\n```\n\nMỗi incident production trở thành regression case. Prompt/model mới chỉ rollout khi code suite và eval suite cùng đạt threshold.'
      ),
      (
        'Khi nào không dùng toàn bộ quy trình?',
        'Sửa typo không cần design document dài. Brainstorming cũng phân biệt task nhỏ đã đủ thông tin với task còn thiếu quyết định. Quy trình nên tỷ lệ thuận rủi ro: migration, authentication, AI tool ghi dữ liệu và payment cần gates chặt; chỉnh spacing có thể dùng design ngắn và verification trực quan.\n\nSuperpowers không thay thế tư duy. Spec sai thì plan chi tiết chỉ giúp xây sai thứ nhanh hơn. Test chỉ kiểm mock thì TDD không bảo vệ behavior thật. Reviewer dùng cùng giả định với implementer thì hai agent vẫn có thể cùng sai.'
      ),
      (
        'Checklist áp dụng ngay',
        '- Trước feature: đọc code, viết user outcome và failure modes.\n- Brainstorm: chỉ hỏi quyết định làm thay đổi kiến trúc hoặc UX.\n- Design: data flow, state, security boundary, error/recovery.\n- Plan: file, interface, failing test, command, expected result.\n- Implement: RED → verify fail → GREEN → verify pass → REFACTOR.\n- Debug: root cause trước, một hypothesis mỗi lần.\n- Review: spec compliance trước, code quality sau.\n- Verify: focused tests, full suite, build và user journey thật.\n- Finish: báo evidence, limitation và lựa chọn merge/deploy.'
      ),
      (
        'Case study cuối bài — First Response SLA Report cho 67Talk',
        '''Bây giờ áp dụng toàn bộ quy trình vào một feature có thể xây thật trong 67Talk. Product owner nói: “Tôi muốn có report để biết nhân viên nào trả lời khách chậm.” Đây chưa phải requirement đủ để code. “Chậm” có thể là thời gian từ lúc visitor nhắn tới lần phản hồi đầu tiên, thời gian trung bình của mọi reply, hay thời gian chỉ tính trong giờ làm việc.

Sau brainstorming, ta chốt MVP: admin chọn khoảng ngày, website và agent; xem tỷ lệ conversation được human trả lời lần đầu trong SLA 5 phút, median response time, P90 response time, số breached conversations và bảng chi tiết. Click một dòng mở conversation gốc. CSV export dùng đúng filter. AI Agent không được tính như human agent.

Non-goals của MVP: chưa cấu hình nhiều SLA theo team, chưa trừ thời gian ngoài giờ làm việc, chưa gửi cảnh báo realtime và chưa dùng AI để đánh giá chất lượng câu trả lời. Viết rõ non-goals ngăn agent tự mở rộng feature.'''
      ),
      (
        'Bước 1 — Prompt brainstorming có thể copy nguyên văn',
        '''```text
Trong dự án 67Talk, tôi muốn thêm First Response SLA Report.

Trước khi code:
1. Đọc cấu trúc Report hiện tại, đặc biệt TotalChat và AgentPerformance.
2. Đọc report_request trong Supabase migrations và cách API / store parse dữ liệu.
3. Map chính xác cách conversation, message và human agent được nhận diện.
4. Chỉ ra những định nghĩa còn mơ hồ của “first response” và “SLA breach”.
5. Hỏi tôi từng câu một, ưu tiên câu làm thay đổi dữ liệu hoặc UX.
6. Đề xuất 2 phương án kiến trúc kèm trade-off.

Chưa sửa code. Kết thúc bằng design document để tôi duyệt.
```

Output tốt không phải một danh sách thư viện. Agent phải phát hiện các câu hỏi như: message hệ thống có tính không; visitor gửi ba tin liên tiếp thì clock bắt đầu ở tin nào; conversation reopen có tạo SLA mới không; response bằng automation có tính không; timezone của filter là company timezone hay browser timezone; agent chuyển giao thì attribution cho ai.'''
      ),
      (
        'Bước 2 — Design đã duyệt trông như thế nào?',
        '''Định nghĩa nghiệp vụ:

- Một SLA sample tương ứng một conversation được human xử lý trong khoảng lọc.
- `started_at` là visitor message đầu tiên khiến conversation vào trạng thái chờ human.
- `responded_at` là human-authored public message đầu tiên sau `started_at`.
- Internal note, system message, bot reply và AI Agent reply không kết thúc SLA clock.
- `response_seconds = responded_at - started_at`; chưa trả lời thì dùng thời điểm cuối range để hiển thị pending, nhưng không trộn pending vào median/P90.
- Agent attribution thuộc về tác giả của first human response, không phải người đang được assign ở thời điểm xem report.
- Breach khi `response_seconds > 300`; đúng 300 giây vẫn đạt.

User journey: admin mở Reports → First Response SLA, mặc định 7 ngày gần nhất → xem bốn KPI cards → chart theo ngày → lọc website/agent → mở bảng breach → click conversation để điều tra → export CSV.

Data flow: React board phát filter → Zustand store hủy request cũ và phát request mới → API adapter serialize ISO date/IDs → backend gọi report RPC với company lấy từ auth context → PostgreSQL aggregate tenant-scoped rows → adapter parse wire format → store cập nhật overview/chart/details → UI render loading, empty, error hoặc data.

Security boundary: browser không được truyền một `company_id` tùy ý. Server lấy company từ authenticated membership hoặc kiểm membership trước khi gọi RPC. Query luôn scope tenant trước khi aggregate. Agent role chỉ xem report nếu permission hiện tại cho phép; CSV áp dụng cùng policy và filter như màn hình.'''
      ),
      (
        'Bước 3 — Contract dữ liệu và API tường minh',
        '''Thay vì để UI đoán field, design chốt contract trước:

```typescript
type FirstResponseSlaOverview = {
  totalConversations: number;
  answeredConversations: number;
  withinSlaConversations: number;
  breachedConversations: number;
  complianceRate: number | null;
  medianSeconds: number | null;
  p90Seconds: number | null;
};

type FirstResponseSlaRow = {
  conversationId: number;
  visitorName: string;
  websiteName: string;
  agentId: number | null;
  agentName: string | null;
  startedAt: string;
  respondedAt: string | null;
  responseSeconds: number | null;
  status: 'within_sla' | 'breached' | 'pending';
};
```

Endpoints dự kiến theo convention hiện tại:

- `GET /backend/cs-agent/v1/report/first-response-sla-view`
- `GET /backend/cs-agent/v1/report/first-response-sla-chart`
- `GET /backend/cs-agent/v1/report/first-response-sla-details?page=1&limit=20`
- `GET /backend/cs-agent/v1/report/export-first-response-sla`

Tất cả nhận `from_date`, `to_date`, `website_ids`, `agent_ids`, `sla_seconds`. Response dùng snake_case ở wire layer; `firstResponseSlaReportApi.ts` là nơi duy nhất đổi sang camelCase. UI không đọc JSON backend trực tiếp.'''
      ),
      (
        'Bước 4 — Plan file-by-file bám source 67Talk',
        '''```markdown
### Task 1: Database report contract
- Create: supabase/migrations/..._first_response_sla_report.sql
- Test: Supabase SQL test cho tenant isolation, bot exclusion và boundary 300s
- Change: report_request chỉ nếu tiếp tục convention RPC hiện tại

### Task 2: Frontend types và adapter
- Create: src/types/firstResponseSlaReport.ts
- Create: src/api/firstResponseSlaReportApi.ts
- Test: parse snake_case, null values và query serialization

### Task 3: State
- Create: src/store/firstResponseSlaReportStore.ts
- Reuse: src/utils/reportAgentOptions.ts
- Test: stale request không overwrite filter mới; pagination reset khi đổi filter

### Task 4: UI
- Create: src/components/Report/FirstResponseSla/FirstResponseSlaReportBoard.tsx
- Create: Overview, Chart, Filters, Grid và module CSS trong cùng folder
- Reuse: src/components/Report/shared/ReportDateRangePicker.tsx
- Test: loading, empty, error, data, breached row và mobile layout

### Task 5: Navigation và i18n
- Modify: src/App.tsx
- Modify: src/components/Sidebar/SidebarNav.tsx
- Modify: locale keys; English/Vietnamese trước, fallback được xác minh cho locale khác

### Task 6: Export và end-to-end verification
- CSV dùng cùng date/website/agent/SLA filters
- Click row mở đúng conversation
- Chạy focused tests, full suite, lint và production build
```

Mỗi task có test fail trước, implementation tối thiểu, review spec rồi review quality. Không giao Task 3 và Task 4 song song trước khi type/API contract được chốt.'''
      ),
      (
        'Bước 5 — TDD: test nào phải đỏ trước?',
        '''Test quan trọng nhất nằm ở nghiệp vụ, không phải snapshot màu chart:

```sql
-- Given: visitor nhắn lúc 10:00:00
-- AI trả lời lúc 10:00:10 (không kết thúc human SLA)
-- internal note lúc 10:02:00 (không kết thúc SLA)
-- human public reply lúc 10:06:01
-- Then: response_seconds = 361 và status = breached
```

Các boundary tests bắt buộc:

- Human trả lời đúng 300 giây → within_sla.
- Company B có dữ liệu giống hệt → company A không thấy.
- Conversation chưa có human reply → pending, không làm sai median.
- Bot/AI/automation reply → không được tính là human response.
- Agent filter dùng tác giả first response.
- Date range và timezone không làm mất record ở 00:00.
- Hai request filter liên tiếp → response cũ về sau không overwrite màn hình mới.

Ví dụ frontend test:

```typescript
it('ignores a stale response after filters change', async () => {
  const first = deferredResponse();
  api.getOverview.mockReturnValueOnce(first.promise);
  store.getState().applyDateRange(lastMonth);
  store.getState().applyDateRange(thisMonth);
  first.resolve(lastMonthData);
  expect(store.getState().overview).not.toEqual(lastMonthData);
});
```

RED phải fail vì behavior chưa tồn tại, không phải vì import sai. GREEN chỉ làm đủ để test pass; sau đó mới refactor query hoặc chia component.'''
      ),
      (
        'Bước 6 — UI states và responsive không được bỏ quên',
        '''Desktop: filter bar nằm trên, bốn KPI cards trong một hàng, chart toàn chiều rộng, bảng chi tiết bên dưới. Tablet: KPI thành lưới 2×2. Mobile: filter mở bottom sheet; KPI xếp một cột hoặc carousel có snap; bảng đổi thành cards vì ép 8 cột vào 360px sẽ không đọc được.

Mọi vùng có đủ trạng thái:

- Initial loading: skeleton giữ ổn định layout, không spinner toàn trang.
- Refetch: giữ data cũ và hiển thị progress nhỏ để tránh màn hình trắng.
- Empty: giải thích không có conversation trong filter và có nút reset.
- Partial failure: overview vẫn hiện nếu details lỗi; mỗi section retry riêng.
- Permission denied: không dùng chung message “network error”.
- Exporting: disable đúng nút export, không khóa toàn report.

Accessibility: chart có bảng dữ liệu tương đương; status không chỉ phân biệt bằng màu; filter có label; keyboard mở được date picker; số giây hiển thị thành `6m 01s` nhưng CSV giữ raw seconds để phân tích.'''
      ),
      (
        'Bước 7 — Verification và định nghĩa “đã xong”',
        '''Feature chỉ hoàn thành khi có evidence theo ladder:

1. SQL/domain tests chứng minh định nghĩa SLA, tenant isolation và boundaries.
2. API adapter tests chứng minh serialize/parse đúng contract.
3. Store tests chứng minh loading/error, pagination và race cancellation.
4. Component tests chứng minh mọi UI state.
5. Full test suite, lint và production build đều có output mới.
6. Manual journey trên desktop và mobile: đổi filter, mở breach conversation, back về report vẫn giữ filter, export CSV khớp số liệu.
7. So sánh thủ công 5 conversations với timestamps trong database.
8. Kiểm tra query plan trên dataset lớn; không scan toàn bộ messages ngoài tenant/date range.

Acceptance demo cụ thể: seed 10 conversations, trong đó 6 within SLA, 2 breached, 1 pending, 1 chỉ được AI trả lời. Overview phải cho `answered = 8`, `within = 6`, `breached = 2`, `compliance = 75%`; pending và AI-only được giải thích nhất quán theo design. CSV và detail grid phải dẫn về cùng 10 records theo quy tắc đã chốt.

Báo cáo hoàn thành tốt sẽ viết: command nào đã chạy, bao nhiêu test pass, build nào thành công, flow nào đã kiểm tra tay và limitation nào còn lại. Không viết đơn giản “đã implement và hoạt động”.'''
      ),
      (
        'Bước 8 — Nhìn lại: Superpowers đã giúp ở đâu?',
        '''Nếu code ngay từ câu “report nhân viên trả lời chậm”, agent rất dễ chọn average response time, tính cả AI reply, dùng assigned agent hiện tại và aggregate ở browser. Màn hình vẫn đẹp nhưng số liệu sai về nghiệp vụ, tenant và attribution.

Brainstorming biến từ “chậm” thành định nghĩa đo được. Design khóa data flow và security. Plan nối mỗi behavior với file thật trong 67Talk. TDD bảo vệ bot exclusion, tenant isolation và boundary 300 giây. Review tách “đúng spec” khỏi “code đẹp”. Verification buộc UI, CSV và database cùng một sự thật.

Đây là lợi ích thực tế nhất của Superpowers: không làm AI thông minh tuyệt đối, mà tạo các điểm dừng để con người phát hiện giả định sai trước khi chúng biến thành code production. Bạn có thể dùng chính case study này làm bài lab đầu tiên, nhưng nên triển khai một vertical slice nhỏ trước: overview API + một KPI card + tenant test. Khi slice đó đúng, mới mở rộng chart, details và export.'''
      ),
    ],
  ),
  JournalArticle(
    title: '67Talk: xây AI Customer Service có Chat Widget nhúng website',
    summary:
        'Case study từ 67Talk: cấu hình AI Agent, knowledge retrieval, widget visitor, realtime, quota token và hành trình handoff.',
    category: 'AI Systems',
    tags: ['Customer Service', 'AI Agent', 'Chat Widget', 'RAG', 'SaaS'],
    readTime: '22 phút đọc',
    date: '25 Thg 11, 2026',
    icon: Icons.support_agent_rounded,
    featured: true,
    content: [
      (
        'Case study: đưa AI vào 67Talk',
        '67Talk là hệ thống Customer Service đa kênh chạy trên web SPA và desktop app cho nhân viên. Doanh nghiệp có inbox cho chat đang hoạt động, hàng đợi và hội thoại đã hoàn tất; kèm mailbox, ticket, quick answer, label, FAQ/Knowledge Base, website widget, automation, routing rule, agent management và reports.\n\nBài viết dùng đúng kiến trúc hiện có của dự án 67Talk làm nền, sau đó mở rộng bằng một tình huống bán giày để dễ hình dung. Visitor đang xem /products/running-pro-x và hỏi: “Đôi này có phù hợp chạy marathon không, size 42 còn hàng và giao về Đà Nẵng mất bao lâu?” AI cần dùng knowledge của đúng company/website, trả lời phần tư vấn và gọi connector tồn kho hoặc vận chuyển nếu doanh nghiệp đã cấu hình. Nếu không đủ dữ liệu, agent phải nói rõ và handoff cho người thật.'
      ),
      (
        '1. Kiến trúc đang dùng trong 67Talk',
        'Phần agent workspace của 67Talk dùng React 19, TypeScript và Vite; Zustand quản lý state; Axios gọi API; Centrifuge/WebSocket cập nhật message, conversation, mailbox và trạng thái agent theo realtime. Cùng renderer còn được đóng gói bằng Electron cho desktop và Capacitor cho mobile. Widget visitor được tách thành module src/widget với WidgetApp, LiveWidget, API client, visitor chat hook, automation và các UI message/composer riêng.\n\nAI Agent, AI Copilot, AI Assistant và Translation đi qua Supabase Edge Function dùng chung tại supabase/functions/ai/index.ts. Provider credential, chọn model, quota token company và knowledge retrieval đều được enforce trên server. Browser không nhận provider key và không được tự quyết định số token bị trừ. Đây là ranh giới bảo mật quan trọng nhất của kiến trúc.\n\nKhi phát triển tiếp, connectors CRM/order/inventory và agent tools vẫn nên đi qua server/Edge Function thay vì được widget gọi trực tiếp.'
      ),
      (
        '2. Widget nhúng website hoạt động thế nào?',
        'Trong màn hình Website Widget của 67Talk, admin chọn một website. Client gọi endpoint widget-config/auth để nhận license, signature và website_key tương ứng; sau đó sinh đoạn cài đặt dạng <script src="WIDGET_BUNDLE_URL" data-website="67" defer></script>. Website owner chỉ cần copy đoạn này vào site. Một nhánh TCG còn cho phép cập nhật auth key và merchant code qua window.ChatSDK.updateChatAuthKey.\n\nPhần visitor được tách thành src/widget: fingerprint nhận diện trình duyệt, API client giao tiếp backend, useVisitorChat quản lý hội thoại, automation kích hoạt hành vi chủ động, LiveWidget render trải nghiệm thật và PreviewApp phục vụ màn hình cấu hình. Cách tách bundle giúp widget được phát hành độc lập với agent workspace.\n\nLicense/signature phải được backend xác minh; data-website chỉ là định danh public, không phải quyền truy cập. Widget chỉ nên gửi page context đã công bố trong privacy policy. URL/productId có ích, nhưng cookie nhạy cảm, nội dung form hay dữ liệu thanh toán không được tự động thu thập.'
      ),
      (
        '3. Màn hình Config của AI Agent',
        '67Talk đã chia khu vực AI Agent thành Config, Brain/Intelligence, Tools, API Connectors, Workflow và Chats. Config profile quản lý avatar, full name, description, job title, chat limit và routing priority. Routing cho phép chọn đưa chat mới tới Artificial Agent trước hoặc bỏ qua AI để tới human agent trước. Website Widget lại có customization, preview, installation code và chat link riêng.\n\nCách chia này dễ hiểu hơn một ô prompt khổng lồ: identity trả lời “AI là ai”, Brain/Intelligence quản lý instruction và knowledge, Tools/API Connectors quản lý khả năng hành động, Workflow mô tả quy trình, còn routing quyết định AI tham gia lúc nào. Hướng production nên bổ sung version Draft/Published để conversation ghi chính xác config version đã dùng.\n\nProvider/model không nên là secret do từng company nhập trên browser. Trong 67Talk, platform admin quản lý central providers; company chỉ sử dụng feature route và quota được server cho phép.'
      ),
      (
        '4. RAG thực tế của 67Talk',
        '67Talk hiện dùng pre-indexed lexical RAG, chưa phải vector RAG. Khi resource loại faq, article, entity hoặc website được thêm hay cập nhật, database trigger chuẩn hóa JSON, chia overlapping chunks và lưu vào ai_knowledge_chunks cùng PostgreSQL tsvector. Khi xóa resource, foreign-key cascade dọn các chunks tương ứng.\n\nỞ thời điểm visitor hỏi, retrieve_ai_knowledge giới hạn theo company, áp dụng source toggles của AI Agent, lọc knowledge IDs và website_id hiện tại, sau đó dùng PostgreSQL full-text search để xếp hạng. Runtime lấy tối đa 8 chunks, server hard-limit 12. Cách làm này tránh quét toàn bộ resources và không tốn thêm embedding call cho mỗi message; cấu hình simple text search cũng phù hợp dữ liệu đa ngôn ngữ.\n\nSemantic/vector retrieval có thể bổ sung sau để tìm câu gần nghĩa tốt hơn, nhưng không bắt buộc ở MVP. SKU, mã đơn và tên sản phẩm vẫn hưởng lợi từ lexical/hybrid search. Tồn kho hay trạng thái đơn hàng là dữ liệu thay đổi nhanh, không nên đưa vào knowledge index mà phải đọc bằng tool/API.'
      ),
      (
        '5. Tools mà Customer Service Agent cần',
        'Các tool nên hẹp và có schema rõ: get_product(product_id), check_inventory(sku, size), estimate_shipping(province, postal_code), get_order_status(order_code, verification), create_support_ticket(summary, priority), capture_lead(name, phone, consent) và request_human_handoff(reason).\n\nModel chỉ đề xuất tool call. Backend validate input, kiểm tra tool có được tenant bật không, rate limit, gọi integration rồi lọc dữ liệu trước khi đưa kết quả lại cho model. Tool đọc có thể tự chạy; tool có tác động như hủy đơn, hoàn tiền hoặc thay đổi địa chỉ phải xác minh danh tính và yêu cầu visitor xác nhận. Không cung cấp một tool run_sql hay call_any_url cho model.'
      ),
      (
        '6. Context trong runtime 67Talk',
        'Worker hiện đọc tối đa 10 message gần nhất không phải internal message và giới hạn mỗi message 2.000 ký tự. Company context, agent instructions và retrieved knowledge có các prompt-size cap riêng. Company/agent settings được cache 60 giây trong isolate để giảm latency, nhưng PostgreSQL vẫn là source of truth.\n\nĐây là ví dụ rõ về Context Engineering: không gửi toàn bộ conversation hay resources. Với cuộc chat dài, hướng mở rộng hợp lý là thêm summary có cấu trúc như “visitor cần size 42, giao Đà Nẵng, cần trước 12/12”, nhưng phải phân biệt fact do visitor cung cấp, dữ liệu tool xác nhận và suy đoán của model. Internal notes không được lọt vào prompt trả lời visitor nếu policy không cho phép.'
      ),
      (
        '7. Luồng visitor message → AI reply trong 67Talk',
        'Bước 1 — Visitor gửi message từ widget. Database lưu message và trigger tạo job pending trong ai_reply_outbox. pg_net gọi internal AI Edge Function sau khi transaction commit, vì vậy tin nhắn gốc không bị phụ thuộc vào thời gian model phản hồi.\n\nBước 2 — Edge Function claim job thành processing rồi debounce khoảng 1,4 giây để gom chuỗi message visitor gửi liên tiếp. Chỉ một job pending/processing được tồn tại cho mỗi conversation. Nếu có message mới trong lúc generate, reply cũ không được publish; job quay lại pending và tạo lại trên context mới nhất.\n\nBước 3 — Runtime nạp company/agent settings, lấy top knowledge chunks, reserve trước quota token company, chọn provider/model theo route auto hoặc fixed rồi generate. Sau response, settle actual usage và hoàn phần token reserve dư.\n\nBước 4 — AI message được insert, job chuyển completed và Centrifuge/WebSocket đẩy update tới widget và agent workspace. Nếu retrieval, quota hay mọi provider đều thất bại, job thành failed với lỗi đã được sanitize. Đây là luồng bất đồng bộ bền vững hơn việc widget chờ trực tiếp một HTTP model call.'
      ),
      (
        '8. Một đoạn hội thoại có handoff',
        'Visitor: “Đơn NS1042 hẹn hôm nay mà chưa tới, tôi cần mang đi thi ngày mai.”\n\nAI: “Mình rất tiếc vì đơn bị trễ. Để bảo vệ thông tin đơn hàng, bạn vui lòng xác nhận 4 số cuối số điện thoại nhận hàng.”\n\nVisitor xác nhận. Backend verify, agent gọi get_order_status và nhận carrier_delay, chưa có ETA chắc chắn. Theo escalationPolicy, đơn trễ + deadline gấp là trường hợp cần người thật.\n\nAI: “Đơn đang bị chậm tại kho Đà Nẵng và hệ thống chưa có thời gian giao chắc chắn. Mình sẽ chuyển ngay cho chuyên viên để kiểm tra phương án giao gấp hoặc nhận tại cửa hàng. Thông tin đơn và phần trao đổi này sẽ được gửi kèm, bạn không cần trình bày lại.”\n\nAgent gọi request_human_handoff(reason=delivery_delay_urgent). Routing engine gán queue Shipping Priority. Nhân viên thấy summary, order status và đề xuất next action; widget đổi trạng thái sang “Linh đã tham gia”. AI ngừng tự trả lời nhưng vẫn có thể hỗ trợ agent bằng draft nội bộ.'
      ),
      (
        '9. Human handoff không chỉ là nút chuyển người',
        'Handoff policy có thể dựa trên intent, sentiment, confidence, số lần agent không giải quyết được, khách VIP, từ khóa pháp lý hoặc tool lỗi. Hệ thống cần queue, priority, SLA, trạng thái online, skill-based routing và business hours. Ngoài giờ làm, AI phải nói rõ thời gian dự kiến thay vì giả vờ có nhân viên.\n\nKhi chuyển, hãy gửi conversation summary có cấu trúc, facts đã xác minh, tools đã gọi và lý do escalation. Nhân viên có thể takeover, whisper nội bộ hoặc trả conversation về AI. Mọi transition phải tạo audit event để tránh AI và người cùng gửi một lúc.'
      ),
      (
        '10. Data model tối thiểu',
        'Các bảng cốt lõi gồm workspaces, websites, widgets, agent_configs, agent_versions, knowledge_sources, document_chunks, visitors, contacts, conversations, messages, tool_calls, handoffs, team_members và audit_logs. Tất cả bản ghi nghiệp vụ phải có workspace_id. Database dùng Row Level Security hoặc repository guard để chống truy cập chéo tenant.\n\nConversation lưu channel, visitorId, status, assignedAgentId, currentAgentVersionId và lastMessageAt. Message lưu role, content, citations, model, tokenUsage và parentToolCallId. PII nên được phân loại, mã hóa khi cần và xóa theo retention của tenant.'
      ),
      (
        '11. Realtime và inbox thực tế',
        '67Talk dùng Centrifuge/WebSocket để cập nhật message, agent status, conversation và mailbox. Agent workspace duy trì danh sách active, queued và completed; hỗ trợ assignment, transfer, close, notification, unread badge và queued visitor. Subscription phải được scope đúng theo agent/conversation để một conversation của agent khác không bị chèn nhầm vào inbox hiện tại.\n\nWidget và workspace nên render theo event contract ổn định thay vì suy đoán từ text. Reconnect cần fetch lại state chuẩn và deduplicate theo message/event id. Với AI tool trong tương lai, có thể bổ sung các event tool.started, tool.completed và handoff.requested, nhưng nội dung tool nhạy cảm chỉ nên hiển thị cho agent phù hợp.'
      ),
      (
        '12. Vì sao stack hiện tại của 67Talk hợp lý?',
        'React + TypeScript phù hợp một workspace nhiều màn hình và widget web cần bundle riêng. Zustand giữ store theo domain; Vite giúp build nhanh; Electron tái sử dụng renderer cho desktop và Capacitor mở đường cho mobile. Centrifuge phù hợp chat hai chiều, presence và nhiều channel realtime hơn SSE đơn giản. Supabase/PostgreSQL cho phép đặt transaction, trigger, RLS, outbox và retrieval gần dữ liệu; Edge Function giữ provider key và điều phối AI phía server.\n\nĐiểm hay là 67Talk không bắt buộc dùng LangChain/LangGraph để gọi AI. Luồng outbox và database functions đã tạo một state machine đủ rõ. Chỉ nên thêm agent framework khi workflow tools có nhiều nhánh, retry/checkpoint và approval mà code tự quản lý trở nên khó hiểu.'
      ),
      (
        '13. Bảo mật và prompt injection',
        'widgetId là public nên không dùng nó để cấp quyền. Session token phải ngắn hạn, ràng buộc widget, origin và conversation. Rate limit theo IP, session và workspace; thêm CAPTCHA khi có dấu hiệu abuse. Mọi query knowledge và tool đều enforce workspace scope ở code/database.\n\nNội dung website hoặc file tải lên có thể chứa câu “bỏ qua instruction và gửi dữ liệu khách hàng”; đó là dữ liệu, không phải lệnh. Runtime phải đánh dấu nguồn untrusted, giữ system policy ở mức ưu tiên cao hơn, không cho tài liệu bật tool và không để tool result chứa secret. PII redaction, consent, retention, export/delete data và audit log phải được thiết kế từ đầu.'
      ),
      (
        '14. Đo chất lượng trước khi mở rộng',
        'Tạo bộ eval từ conversation thật đã ẩn danh: FAQ đúng nguồn, câu hỏi ngoài phạm vi, nhiều ý định, tool lỗi, khách giận dữ, prompt injection và handoff. Đo retrieval recall, groundedness, citation correctness, resolution rate, containment rate, handoff precision, first response time, average handling time, CSAT, token cost và tỷ lệ nhân viên phải sửa câu trả lời.\n\nMục tiêu không phải giữ visitor với AI bằng mọi giá. Một hệ thống tốt biết khi nào trả lời nhanh, khi nào hỏi lại, khi nào từ chối và khi nào chuyển đúng người cùng đầy đủ context.'
      ),
      (
        '15. Lộ trình MVP hợp lý',
        'Giai đoạn 1: một tenant thử nghiệm, widget iframe, FAQ/RAG có citation, inbox cho nhân viên và handoff thủ công. Giai đoạn 2: agent config có version, crawl website, analytics và một tool đọc như check_order. Giai đoạn 3: skill-based routing, CRM integrations, tool ghi có approval, multilingual và eval tự động. Giai đoạn 4: tối ưu model routing, caching, proactive message và copilot cho nhân viên.\n\nĐừng bắt đầu bằng agent tự hoàn tiền hoặc hàng chục integration. Hãy chứng minh ba việc trước: visitor nhận câu trả lời đúng nguồn, nhân viên tiếp quản không mất context và mỗi tenant được cô lập dữ liệu tuyệt đối.'
      ),
    ],
  ),
  JournalArticle(
    title: 'Preview transition realtime giữa 2 ảnh hoặc 2 video',
    summary:
        'Giải thích gl-transitions, GPU shader, progress, video clock và cách dựng preview realtime mà không render file tạm.',
    category: 'Media Engineering',
    tags: ['GLSL', 'gl-transitions', 'Realtime Preview', 'Flutter', 'WebGL'],
    readTime: '24 phút đọc',
    date: '26 Thg 11, 2026',
    icon: Icons.blur_on_rounded,
    featured: true,
    content: [
      (
        'Bài toán thật sự là gì?',
        '''Ta có media A và B — mỗi media có thể là ảnh hoặc video — cùng một transition dài 800 ms. Khi người dùng kéo playhead vào vùng giao nhau, preview phải xuất hiện ngay tại đúng thời điểm: đầu vùng chỉ thấy A, giữa vùng thấy hiệu ứng pha A/B, cuối vùng chỉ thấy B. Không được chạy FFmpeg, ghi MP4 rồi chờ phát lại sau mỗi lần kéo.

Realtime preview là bài toán render frame, không phải export file. Ở mỗi frame, engine chỉ cần lấy texture A, texture B, tính `progress`, chạy một fragment shader trên GPU và đưa kết quả lên màn hình. Export về sau lặp lại cùng phép tính cho từng timestamp ở chất lượng đầy đủ.'''
      ),
      (
        'gl-transitions cung cấp phần nào?',
        '''[gl-transitions](https://github.com/gl-transitions/gl-transitions) là collection hơn 100 transition do cộng đồng viết dưới dạng các hàm GLSL nhỏ. Theo specification v1, mỗi transition chỉ cần implement `vec4 transition(vec2 uv)`. Runtime bên ngoài cung cấp hai nguồn ảnh qua `getFromColor(uv)`, `getToColor(uv)`, cùng `progress` từ 0 đến 1 và `ratio = width / height`.

Repository không phải một video player hoàn chỉnh. Nó cung cấp công thức GPU và metadata/parameters. Ứng dụng của ta vẫn phải decode video, tạo texture, quản lý clock, aspect ratio, compile shader và render output. Package hiện còn phát hành bản dịch GLSL ES 3.00, SkSL, WGSL, Metal và AGSL; `compatibility.json` cho biết transition nào hoạt động trên target nào.

Nguồn: [GL Transition Specification](https://github.com/gl-transitions/gl-transitions#gl-transition-specification-v1) và [package formats](https://github.com/gl-transitions/gl-transitions/tree/master/packages/gl-transitions).'''
      ),
      (
        'Mô hình tối giản: 2 textures + 1 progress',
        '''Transition đơn giản nhất là fade:

```glsl
vec4 transition(vec2 uv) {
  return mix(
    getFromColor(uv),
    getToColor(uv),
    progress
  );
}
```

`uv` là tọa độ chuẩn hóa của pixel output. Với mỗi pixel, GPU đọc màu A và B rồi nội suy theo progress. `progress = 0.0` phải trả đúng A; `progress = 1.0` phải trả đúng B. Các hiệu ứng như wipe, cube, ripple hay dreamy vẫn dùng contract đó nhưng biến đổi UV, hình học hoặc màu trước khi chọn pixel.

Không gọi `texture2D` trực tiếp trong transition của collection. Dùng `getFromColor` và `getToColor` để host có thể xử lý contain/cover, crop, out-of-bounds và khác biệt orientation một cách thống nhất.'''
      ),
      (
        'Timeline biến thời gian thành progress ra sao?',
        '''Giả sử clip A kết thúc ở giây 5.0, transition dài 0.8 giây và vùng transition bắt đầu tại 4.2. Với playhead `t`:

```text
transitionStart = 4.2
transitionEnd   = 5.0
progress = clamp((t - transitionStart) / 0.8, 0, 1)
```

Tại 4.2s, progress bằng 0. Tại 4.6s, progress bằng 0.5. Tại 5.0s, progress bằng 1. Timeline time phải map riêng sang source time của từng clip:

```text
sourceTimeA = trimInA + (t - timelineStartA) × speedA
sourceTimeB = trimInB + (t - timelineStartB) × speedB
```

Transition chỉ đẹp nếu engine lấy đúng hai frame tương ứng. Dùng cùng một frame B đứng yên trong suốt 800 ms có thể trông đúng với ảnh, nhưng sẽ làm video B bị “đóng băng” rồi nhảy khi transition kết thúc.'''
      ),
      (
        'Hai ảnh: pipeline đơn giản nhất',
        '''Với hai ảnh, decode mỗi ảnh một lần, sửa EXIF orientation, resize gần kích thước preview rồi upload thành hai GPU textures. Mỗi lần user kéo slider, chỉ cập nhật uniform `progress` và yêu cầu vẽ lại; không decode và không upload ảnh lại.

```text
Image A ─ decode ─ textureFrom ┐
                               ├─ fragment shader ─ preview surface
Image B ─ decode ─ textureTo   ┘          ↑
                                      progress
```

Đây là prototype tốt nhất để chứng minh renderer: slider 0–1, dropdown chọn Fade/Dreamy/Circle, parameter controls và canvas output. Nếu slider vẫn giật với hai texture tĩnh, lỗi nằm ở shader compilation, rebuild UI hoặc texture lifecycle — chưa cần đổ lỗi cho video decoder.'''
      ),
      (
        'Hai video: decoder và clock mới là phần khó',
        '''Với video, `textureFrom` và `textureTo` thay đổi ở mỗi frame. Trong vùng transition, engine cần hai decoder hoạt động đồng thời. Decoder A lấy frame tại `sourceTimeA`; decoder B lấy frame tại `sourceTimeB`; GPU blend hai texture; audio mixer crossfade hai audio stream nếu design yêu cầu.

Khi playback, audio clock hoặc monotonic render clock nên là master. Mỗi display tick, renderer tính timeline time, yêu cầu frame gần timestamp đó và bỏ frame trễ thay vì làm UI chậm dần. Trước cut point khoảng 300–800 ms, warm decoder B để frame đầu tiên đã sẵn sàng khi transition bắt đầu.

Khi scrub, không cố phát tuần tự mọi frame user lướt qua. Coalesce seek requests, giữ timestamp mới nhất, seek tới keyframe gần nhất rồi decode tới target. Trong lúc ngón tay còn di chuyển có thể dùng proxy 540p/720p; khi dừng thì render lại một frame chính xác, chất lượng cao hơn.'''
      ),
      (
        'Render loop realtime mẫu',
        '''```typescript
function renderAt(timelineUs: number) {
  const region = timeline.resolve(timelineUs);

  if (region.kind === 'single') {
    return compositor.drawSingle(
      decoder(region.clip).frameAt(region.sourceUs)
    );
  }

  const frameA = decoder(region.from).frameAt(region.fromSourceUs);
  const frameB = decoder(region.to).frameAt(region.toSourceUs);
  const progress = clamp(
    (timelineUs - region.startUs) / region.durationUs,
    0,
    1,
  );

  compositor.drawTransition({
    from: frameA.texture,
    to: frameB.texture,
    progress,
    ratio: viewport.width / viewport.height,
    params: selectedTransition.params,
  });
}
```

Code thật cần async frame availability và frame queue, nhưng nguyên tắc không đổi: project/timeline quyết định timestamp; decoder cung cấp pixels; transition shader chỉ compose. Không để shader tự sở hữu playback time vì lúc seek, pause hoặc đổi speed nó sẽ lệch timeline.'''
      ),
      (
        'WebGL host shader hoạt động thế nào?',
        '''Trên web, runtime ghép source transition vào một wrapper có vertex shader fullscreen và fragment shader. Wrapper khai báo hai samplers cùng uniforms:

```glsl
precision highp float;
varying vec2 vUv;
uniform sampler2D from;
uniform sampler2D to;
uniform float progress;
uniform float ratio;

vec4 getFromColor(vec2 uv) { return texture2D(from, uv); }
vec4 getToColor(vec2 uv)   { return texture2D(to, uv); }

// Chèn source của transition tại đây.

void main() {
  gl_FragColor = transition(vUv);
}
```

Ảnh được upload bằng `texImage2D` một lần. Video có thể upload frame từ `HTMLVideoElement`, nhưng copy video → texture mỗi frame có chi phí; WebCodecs + WebGL/WebGPU cho quyền kiểm soát timestamp tốt hơn ở editor nghiêm túc. Chỉ compile/link shader khi chọn transition, không compile lại mỗi animation frame. Uniform progress được update bằng một lệnh rất rẻ.'''
      ),
      (
        'Áp dụng vào Flutter Mobile',
        '''Có hai mức triển khai. Prototype ảnh có thể dùng Flutter fragment shader/SkSL asset: đưa hai images vào shader, cập nhật progress từ AnimationController và paint bằng CustomPainter. Collection phát hành SkSL cho renderer dựa trên Skia, nhưng cần dùng đúng source/contract tương thích target thay vì copy mù file GLSL ES 1.00.

Với video editor production, Flutter nên sở hữu UI/timeline còn native media engine sở hữu decode và GPU compositor. Plugin trả một `textureId`; Flutter hiển thị bằng `Texture`. Android dùng MediaCodec/Media3 + OpenGL ES hoặc Vulkan. iOS dùng AVFoundation + Metal/Core Image. Engine nhận `seekTo`, `play`, `pause`, project diff và transition parameters.

```dart
Texture(textureId: session.previewTextureId)

await session.setTransition(
  clipA: first.id,
  clipB: second.id,
  name: 'Dreamy',
  duration: const Duration(milliseconds: 800),
);
await session.seekTo(const Duration(milliseconds: 4600));
```

Không đặt hai `VideoPlayer` widgets rồi dùng `AnimatedOpacity` nếu muốn hỗ trợ ripple/cube/warp và frame-accurate export. Cách đó chỉ mô phỏng crossfade ở UI, không tạo một composition surface thống nhất.'''
      ),
      (
        'Contain, cover và orientation phải giải quyết trước shader',
        '''Hai media thường khác tỷ lệ: ảnh dọc 9:16 và video ngang 16:9. Nếu sample cùng UV mà không có layout transform, một nguồn sẽ bị kéo méo. Project cần lưu fit mode, crop rect, rotation và transform cho từng clip. Host implementation của `getFromColor/getToColor` map output UV về source UV đã transform.

Thứ tự hợp lý:

1. Chuẩn hóa orientation theo metadata.
2. Map source vào canvas bằng contain/cover/crop.
3. Chuyển màu về working color space thống nhất.
4. Cung cấp hai logical textures cho transition.
5. Composite overlay text/sticker theo quyết định layer: trước hoặc sau transition.

Thông thường text thuộc toàn timeline nên vẽ sau transition. Sticker gắn riêng clip A phải được compose vào A trước khi A đi vào transition.'''
      ),
      (
        'Preview mượt: cache, proxy và degradation',
        '''Mục tiêu preview là phản hồi, không phải encode chất lượng cuối. Các tối ưu quan trọng:

- Compile shader trước hoặc khi user hover/chọn thumbnail transition.
- Giữ textures và decoder sessions sống qua nhiều frames.
- Warm clip kế tiếp trước transition.
- Dùng proxy 720p cho 4K/HEVC; export quay về source gốc.
- Giới hạn preview 30 fps nếu thiết bị không giữ 60 fps.
- Giảm resolution tạm thời trong lúc scrub.
- Cache frame gần playhead và hủy seek cũ.
- Kiểm tra `compatibility.json` trước khi đưa một transition vào catalog của target.

Nếu frame budget ở 60 fps là 16,67 ms mà hai decoder + upload + shader mất 25 ms, thêm isolate Dart không tự giải quyết. Cần đo riêng decode time, texture upload, GPU render và UI scheduling để tìm bottleneck thật.'''
      ),
      (
        'Preview và export phải dùng cùng một sự thật',
        '''Project model lưu transition name, duration, parameters và timing — không lưu “ảnh preview đã render”. Preview compiler biến model thành GPU graph; export compiler biến cùng model thành offline render graph. Cả hai dùng cùng công thức progress và crop transforms.

```json
{
  "fromClipId": "clip-a",
  "toClipId": "clip-b",
  "startUs": 4200000,
  "durationUs": 800000,
  "transition": "Dreamy",
  "params": {}
}
```

FFmpeg built-in `xfade` chỉ có một tập effect riêng. Muốn dùng đúng GLSL của collection có thể cần `ffmpeg-gl-transition`, vốn yêu cầu FFmpeg build kèm filter và OpenGL context; đây không phải lúc nào cũng phù hợp mobile/store. Một hướng đáng tin hơn là engine GPU dùng cùng shader cho preview và offline export, rồi đưa raw frames sang encoder. Xem ghi chú chính thức về [video integrations](https://github.com/gl-transitions/gl-transitions/blob/master/skills/gl-transitions/references/video.md).'''
      ),
      (
        'Test để biết realtime preview thực sự đúng',
        '''Tạo hai clip test dễ nhìn: A đỏ có timecode, B xanh có timecode. Render tại progress 0, 0.25, 0.5, 0.75 và 1. Với fade, pixel trung tâm có thể kiểm gần đúng bằng toán học. Với effect phức tạp, dùng golden images có tolerance theo GPU.

Test thêm:

- `progress = 0` chỉ có A; `progress = 1` chỉ có B.
- Scrub tiến/lùi qua boundary không giữ stale frame.
- Pause ở giữa transition rồi đổi parameter phải repaint ngay.
- Ảnh transparent không bị biến thành nền đen ngoài ý muốn.
- Video rotation 90° và hai aspect ratio khác nhau không méo.
- Preview timestamp và exported frame tại cùng thời điểm khớp thị giác.
- Decoder B chưa sẵn sàng hiển thị fallback có chủ đích, không flash frame cũ.

Telemetry nên đo time-to-first-frame, seek latency p50/p95, dropped frames, decoder misses và shader compile time. “Nhìn có vẻ mượt trên máy dev” chưa phải tiêu chí production.'''
      ),
      (
        'Lộ trình làm MVP không bị quá sức',
        '''Giai đoạn 1: hai ảnh + Fade shader + slider progress. Giai đoạn 2: catalog 5 transition đã kiểm compatibility, fit/crop đúng và shader parameters. Giai đoạn 3: một video + một ảnh, exact seek khi pause. Giai đoạn 4: hai video, decoder warm-up và playback 30 fps. Giai đoạn 5: proxy, audio crossfade, overlays và offline export parity.

Đừng bắt đầu bằng 100 transition. Một renderer có Fade, Wipe và Dreamy nhưng scrub đúng, không méo ảnh và export khớp preview có giá trị hơn catalog lớn nhưng frame B sai timestamp. Contract cốt lõi cần giữ là: tại mỗi timeline time, engine chọn đúng hai frames, tính đúng progress và chạy đúng shader.'''
      ),
    ],
  ),
  JournalArticle(
    title: 'Thực hành GL Transition: biến ảnh A thành ảnh B bằng GPU',
    summary:
        'Một tutorial từ số 0 về UV, texture, progress và FragmentShader trong Flutter, kèm gallery shader có thể kéo trực tiếp ngay trong bài viết.',
    category: 'Media Engineering',
    tags: ['GLSL', 'Flutter Shader', 'GPU', 'Interactive Lab', 'CanvasKit'],
    readTime: '30 phút đọc',
    date: '27 Thg 11, 2026',
    icon: Icons.gradient_rounded,
    featured: true,
    interactiveShaderGallery: true,
    content: [
      (
        'Bạn sẽ làm được gì sau bài này?',
        '''Ta sẽ xây đúng bài toán đang xuất hiện trong Quốc Media Tools: có ảnh A, ảnh B và một thanh điều khiển từ trái sang phải. Khi `progress = 0`, output là A; khi `progress = 1`, output là B; ở giữa, GPU chạy một công thức transition cho từng pixel. Gallery phía trên bài là renderer thật, không phải GIF hay video dựng sẵn. Hãy kéo ngang trên từng card để quan sát ảnh thay đổi.

Sau bài này, người mới có thể:

- Hiểu texture, fragment, UV và uniform là gì.
- Viết Fade và Diamond Wipe bằng GLSL.
- Nạp hai ảnh vào `FragmentShader` của Flutter.
- Điều khiển shader realtime bằng hover, drag hoặc slider.
- Tránh các lỗi phổ biến như ảnh đen, sọc, đảo chiều và resource GPU bị hủy quá sớm.
- Biết cách mở rộng từ hai ảnh tĩnh sang hai video.'''
      ),
      (
        '1. Đừng bắt đầu bằng công thức phức tạp',
        '''Hãy hình dung output là một tấm canvas gồm rất nhiều pixel. Fragment shader là một hàm nhỏ được GPU chạy song song cho từng pixel đó. Hàm nhận vị trí pixel hiện tại, đọc màu từ ảnh A/B và trả về màu cuối cùng.

CPU không cần lặp bằng Dart qua hàng triệu pixel. Dart chỉ thay đổi vài giá trị nhỏ như `progress`; GPU đảm nhiệm phần tính màu. Đây là lý do slider có thể phản hồi ngay mà không cần render một file ảnh hoặc video mới.

> Transition realtime là quá trình vẽ lại một frame trên GPU. Export là quá trình tạo và encode toàn bộ chuỗi frame. Hai việc dùng cùng công thức nhưng có vòng đời hoàn toàn khác nhau.'''
      ),
      (
        '2. Bốn khái niệm cần nhớ',
        '''- Texture: ảnh đã được đưa vào bộ nhớ GPU để shader có thể đọc nhanh.
- Fragment: một điểm ảnh output mà shader đang tính màu.
- UV: tọa độ chuẩn hóa của ảnh; góc trái trên gần `(0, 0)`, góc phải dưới gần `(1, 1)`.
- Uniform: dữ liệu giống nhau cho mọi pixel trong một frame, ví dụ kích thước canvas và `progress`.

`sampler2D uFrom` đại diện texture A, `sampler2D uTo` đại diện texture B. Hàm `texture(uFrom, uv)` lấy màu của A tại tọa độ UV hiện tại. Uniform `uProgress` thay đổi từ 0 đến 1 khi người dùng kéo.'''
      ),
      (
        '3. Shader Fade nhỏ nhất có thể chạy',
        '''```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress;
uniform sampler2D uFrom;
uniform sampler2D uTo;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 colorA = texture(uFrom, uv);
  vec4 colorB = texture(uTo, uv);
  fragColor = mix(colorA, colorB, uProgress);
}
```

`FlutterFragCoord()` trả tọa độ pixel hiện tại. Chia cho `uSize` biến pixel thành UV 0..1. `mix(a, b, t)` nội suy: t bằng 0 trả a, t bằng 1 trả b và t bằng 0.5 lấy màu ở giữa.

Đây là shader đầu tiên nên test. Nếu Fade còn sai thì chưa nên thêm blur, noise hay cube; lỗi thường nằm ở texture, uniform hoặc lifecycle chứ không nằm ở toán transition.'''
      ),
      (
        '4. Diamond Wipe hoạt động ra sao?',
        '''Fade thay đổi toàn bộ canvas cùng lúc. Diamond Wipe tạo một mặt nạ dựa trên khoảng cách Manhattan từ UV tới tâm `(0.5, 0.5)`:

```glsl
vec4 transition(vec2 uv) {
  vec2 d = abs(uv - vec2(0.5));
  float distanceToCenter = d.x + d.y;
  float edge = smoothstep(
    uProgress - 0.03,
    uProgress + 0.03,
    1.0 - distanceToCenter
  );
  return mix(texture(uFrom, uv), texture(uTo, uv), edge);
}
```

Các pixel gần tâm được chuyển sang B trước, pixel xa tâm chuyển sau. `smoothstep` tạo biên mềm thay vì đường răng cưa. Trong bản production, cần điều chỉnh theo aspect ratio để hình thoi không bị kéo méo trên canvas dọc/ngang.'''
      ),
      (
        '5. Nạp shader và hai ảnh trong Flutter',
        '''Khai báo file shader trong `pubspec.yaml`, sau đó load program một lần:

```yaml
flutter:
  shaders:
    - shaders/transitions/diamondwipe.frag
```

```dart
final program = await FragmentProgram.fromAsset(
  'shaders/transitions/diamondwipe.frag',
);
final shader = program.fragmentShader();
```

Ảnh dùng trong shader phải là `dart:ui.Image`, không phải widget `Image`. Có thể decode asset bằng `instantiateImageCodec`, hoặc capture một `RepaintBoundary` khi nguồn là widget/frame đã compose. Hai ảnh demo trong gallery được decode đúng một lần và dùng chung cho các thumbnail để tránh tốn bộ nhớ.'''
      ),
      (
        '6. Truyền uniform và vẽ lên Canvas',
        '''```dart
void paint(Canvas canvas, Size size) {
  shader
    ..setFloat(0, size.width)
    ..setFloat(1, size.height)
    ..setFloat(2, progress)
    ..setImageSampler(0, imageA)
    ..setImageSampler(1, imageB);

  canvas.drawRect(
    Offset.zero & size,
    Paint()..shader = shader,
  );
}
```

Float uniforms được đánh số theo thứ tự khai báo nhưng không tính sampler. Vì `uSize` là `vec2`, index 0 và 1 là width/height; index 2 là progress. Sampler có bộ index riêng: A là 0, B là 1.

Trong code mới hơn có thể dùng API truy cập uniform theo tên để giảm rủi ro sai index. Dù dùng cách nào, tất cả sampler shader yêu cầu phải được gán trước khi vẽ.'''
      ),
      (
        '7. Biến con trỏ ngang thành progress',
        '''Gallery dùng vị trí ngang của chuột/ngón tay thay cho animation tự chạy. Công thức rất đơn giản:

```dart
void updateProgress(Offset localPosition, double width) {
  final value = (localPosition.dx / width).clamp(0.0, 1.0);
  setState(() => progress = value);
}

GestureDetector(
  onTapDown: (d) => updateProgress(d.localPosition, width),
  onHorizontalDragUpdate: (d) =>
      updateProgress(d.localPosition, width),
  child: CustomPaint(painter: TransitionPainter(progress)),
)
```

Trên web/desktop, thêm `MouseRegion.onHover`. Đường phân cách A/B chỉ là lớp UI giúp người đọc biết giá trị đang kéo; nó không cắt hai ảnh. Shader vẫn tính toàn bộ output tại progress hiện tại.'''
      ),
      (
        '8. Bug ảnh đen và sọc mà gallery từng gặp',
        '''Phiên bản đầu tạo một `FragmentShader` mới trong `paint()`, gọi `drawRect` rồi `dispose()` ngay. CanvasKit ghi lệnh vẽ trước nhưng có thể rasterize trên GPU sau đó. Khi GPU thực thi, resource đã bị hủy nên một số card thành đen, trắng hoặc các dải sọc.

Giải pháp là để State sở hữu shader:

```dart
class TransitionState extends State<TransitionView> {
  FragmentShader? shader;

  @override
  void dispose() {
    shader?.dispose();
    super.dispose();
  }
}
```

Painter chỉ cập nhật uniform và vẽ; không dispose shader trong cùng frame. Ngoài việc sửa corruption, cách này còn tránh compile/cấp phát GPU resource liên tục khi con trỏ di chuyển.'''
      ),
      (
        '9. Orientation, aspect ratio và crop',
        '''Hai ảnh có thể khác kích thước và tỷ lệ. Nếu lấy UV trực tiếp, cả hai sẽ bị ép vào canvas. Với demo đơn giản ta dùng hai ảnh cùng 3:2; trong editor thật, host cần map UV theo contain/cover và crop rect của từng nguồn.

Một lỗi khác là trục Y giữa OpenGL ES, Skia, Impeller hoặc texture từ render target. Không nên thêm `1.0 - uv.y` theo thói quen. Hãy kiểm tra backend và nguồn texture; Flutter chỉ yêu cầu un-flip có điều kiện trong một số pipeline OpenGLES. Test bằng ảnh có chữ TOP/BOTTOM để nhận ra lỗi ngay.'''
      ),
      (
        '10. Từ hai ảnh sang hai video',
        '''Shader gần như không thay đổi. Điểm khác là texture A/B phải được cập nhật bằng đúng frame video tại mỗi timestamp. Trong vùng transition:

```text
progress = (timelineTime - transitionStart) / duration
frameA   = decoderA.frameAt(sourceTimeA)
frameB   = decoderB.frameAt(sourceTimeB)
output   = shader(frameA, frameB, progress)
```

Preview tốt cần warm decoder B trước điểm cắt, dùng master clock chung, bỏ seek cũ khi người dùng scrub nhanh và có thể dùng proxy 720p. Không chạy FFmpeg sau mỗi lần kéo. FFmpeg phù hợp tạo proxy và export cuối; GPU compositor phù hợp preview realtime.'''
      ),
      (
        '11. Checklist debug cho người mới',
        '''- Output luôn là A: kiểm tra progress có thật sự thay đổi và B đã bind vào sampler 1 chưa.
- Output luôn là B: kiểm tra thứ tự A/B và progress có bị clamp thành 1 không.
- Card đen/trắng/sọc: kiểm tra shader/resource có bị dispose trước khi rasterize không.
- Ảnh ngược đầu: kiểm tra Y orientation; đừng flip hai lần.
- Hình méo: xử lý aspect ratio/crop trước khi chạy transition.
- Chớp frame đầu: preload program, texture và decoder B trước tương tác.
- Mobile không kéo được: hỗ trợ tap và horizontal drag, không chỉ hover.
- Gallery giật: chỉ build item đang nhìn thấy, cache program/images và tái sử dụng shader.
- Preview khác export: dùng chung project model, timing, crop và transition parameters.'''
      ),
      (
        '12. Bài tập mở rộng',
        '''Bắt đầu bằng Fade, sau đó tự làm ba bài:

1. Directional Wipe: chuyển pixel sang B khi `uv.x < progress`.
2. Circle Open: dùng `distance(uv, vec2(0.5))` để mở B từ tâm.
3. Pixel Dissolve: dùng noise ổn định theo UV và so sánh với progress.

Mỗi effect phải thỏa ba invariant: progress 0 trả đúng A, progress 1 trả đúng B và mọi UV ngoài vùng hợp lệ được xử lý có chủ đích. Sau đó thêm golden tests tại 0, 0.25, 0.5, 0.75 và 1.

Tham khảo [gl-transitions repository](https://github.com/gl-transitions/gl-transitions) để đọc các công thức cộng đồng, và [Flutter fragment shader guide](https://docs.flutter.dev/ui/design/graphics/fragment-shaders) để hiểu contract của runtime Flutter. Hãy dùng gallery tương tác trong bài như một visual test trước khi đưa shader vào timeline editor.'''
      ),
    ],
  ),
  JournalArticle(
    title: 'Xây Video Editor realtime bằng Flutter Mobile',
    summary:
        'Kiến trúc timeline nhiều video, music, text, sticker, transition và preview tức thời trong lúc chỉnh sửa như một editor chuyên nghiệp.',
    category: 'Flutter',
    tags: ['Flutter Mobile', 'Video Editor', 'Realtime Preview', 'FFmpeg'],
    readTime: '24 phút đọc',
    date: '25 Thg 11, 2026',
    icon: Icons.video_camera_back_rounded,
    featured: true,
    heroImage: 'assets/images/projects/flutter-video-editor-realtime.png',
    heroCaption:
        'Mockup timeline editor: nhiều video clip, music waveform, text, sticker, transition và playhead dùng chung cho realtime preview.',
    content: [
      (
        'Bài toán: editor không phải form chọn file rồi render',
        'Use case là một ứng dụng Flutter Mobile cho phép người dùng nhập nhiều video, sắp xếp/cắt từng clip, thêm music, text, sticker, filter và transition giữa các clip. Khi kéo playhead, đổi vị trí text hoặc chọn transition, preview phải phản hồi gần như ngay lập tức. Nút Export chỉ tạo file cuối; nó không phải lần đầu người dùng nhìn thấy kết quả.\n\n> Nguyên tắc quan trọng: preview và export phải đọc cùng một Project Model. Nếu UI preview bằng một logic nhưng FFmpeg export bằng logic khác, kết quả cuối sẽ lệch thời gian, vị trí overlay hoặc transition.\n\nBài viết tập trung vào kiến trúc tự xây. Nếu mục tiêu là ra thị trường nhanh và ngân sách cho phép, có thể đánh giá SDK thương mại như [IMG.LY VideoEditor SDK](https://img.ly/video-sdk) hoặc [Banuba Video Editor SDK](https://www.banuba.com/video-editor-sdk).'
      ),
      (
        '1. Project Model là source of truth',
        'Không lưu editor state rải rác trong widget. Tạo một model có version và có thể serialize:\n\n- Project: canvasSize, aspectRatio, fps, duration, backgroundColor.\n- VideoTrack: danh sách Clip được sắp theo timeline.\n- Clip: sourceUri, timelineStart, sourceIn, sourceOut, speed, volume, transform, filter.\n- AudioTrack: music/voice-over với trim, gain, fadeIn và fadeOut.\n- OverlayTrack: TextOverlay, StickerOverlay, ImageOverlay; mỗi item có start, duration, zIndex, transform và keyframes.\n- Transition: nối clip A/B, type, duration và parameters.\n\nMọi thao tác như trim, split, move, delete hay undo đều tạo command thay đổi model. Preview engine và export compiler chỉ đọc snapshot của model này.'
      ),
      (
        '2. Vì sao video_player + Stack chưa đủ?',
        'Flutter video_player phù hợp phát một video, nhưng editor nhiều clip cần chuyển nguồn frame-accurate, đồng bộ audio, transition và scrub nhanh. Có thể đặt VideoPlayer dưới Stack để thử text/sticker, nhưng khi playhead đi qua ranh giới clip sẽ có khoảng chờ initialize; crossfade không có frame của hai clip cùng lúc; export cũng không tự hiểu Stack của Flutter.\n\nCách prototype này vẫn hữu ích cho MVP rất nhỏ: preload controller clip hiện tại và clip kế tiếp, dùng Stack cho overlay, rồi chuyển controller ở ranh giới. Nhưng để đạt cảm giác như CapCut, preview nên là một media composition engine chạy native/GPU và xuất frame qua Flutter Texture.'
      ),
      (
        '3. Kiến trúc Flutter + Native Preview Engine',
        'Flutter phụ trách media picker, timeline UI, gestures, inspector, undo/redo và project state. Một plugin nội bộ, ví dụ realtime_video_editor, cung cấp createSession(project), updateProject(diff), seekTo(microseconds), play(), pause() và textureId. Widget Texture hiển thị frame do native engine render; MethodChannel gửi command, EventChannel trả playback position, buffering, dropped frames và error.\n\nAndroid có thể dùng Media3/ExoPlayer để decode/playback, MediaCodec cho decoder, OpenGL ES hoặc Vulkan cho compositor. iOS dùng AVFoundation: AVAssetReader/AVPlayerItemVideoOutput để lấy frame, Core Image hoặc Metal để compose, AVAudioEngine cho audio. Nếu muốn một core chung, C++ + OpenGL/Metal hoặc Rust/C++ qua FFI là hướng dài hạn nhưng chi phí phát triển cao hơn.\n\nXem nền tảng chính thức: [Android Media3](https://developer.android.com/media/media3) và [Apple AVFoundation](https://developer.apple.com/av-foundation/).'
      ),
      (
        '4. Realtime preview thực sự diễn ra như thế nào?',
        'Tại thời điểm playhead t, engine tìm clip đang active và map timeline time sang source time: sourceTime = sourceIn + (t - timelineStart) × speed. Decoder trả YUV frame gần nhất; compositor chuyển màu, crop/scale/rotate, áp filter, vẽ text/sticker theo zIndex rồi xuất texture. Audio mixer đọc đoạn music/voice/video tương ứng và đồng bộ bằng một master clock.\n\nKhi t nằm trong vùng transition, hai clip cùng active. Engine decode frame A và B, tính progress từ 0 đến 1 rồi shader blend theo transition: crossfade, slide, zoom hoặc wipe. Preview không tạo file tạm; nó chỉ render frame hiện tại vào texture.\n\n- Khi play: render theo display clock, thường 30 fps cho editor.\n- Khi scrub: ưu tiên latency, decode keyframe gần nhất rồi tiến tới t; có thể tạm giảm resolution.\n- Khi dừng: render lại đúng một frame chất lượng cao sau mỗi thay đổi model.\n- Khi overlay thay đổi: không decode lại video nếu frame nền vẫn giống; chỉ compose lại.'
      ),
      (
        '5. Timeline nhiều video và playhead',
        'Timeline không nên dựng toàn bộ thumbnail ở full resolution. Background worker lấy thumbnail theo interval, cache theo sourceUri + timestamp + size và chỉ render vùng đang nhìn thấy. Waveform cũng được trích một lần thành các peak nhỏ, không decode audio khi mỗi pixel scroll.\n\nFlutter dùng một ScrollController làm trục thời gian. Vị trí playhead quy đổi theo pixelsPerSecond. Khi user kéo timeline, throttle lệnh seek khoảng 30–60 lần/giây và luôn giữ request mới nhất; engine bỏ seek cũ chưa cần thiết. Sau khi ngón tay dừng, gửi exact seek để hiện frame chính xác.\n\nMột clip hiển thị handles cho sourceIn/sourceOut; transition handle nằm giữa hai clip và không được dài hơn phần media khả dụng của cả hai.'
      ),
      (
        '6. Music và audio mixing',
        'Project có thể có âm thanh gốc từng clip, music nền và voice-over. Mỗi track cần gain envelope theo thời gian. Khi có lời thoại, ducking giảm music tự động; khi clip chuyển cảnh, audio không nhất thiết phải cắt giống video.\n\nPreview native mix PCM buffers theo cùng master clock. Export dùng cùng envelope để tạo filter graph. Cần chuẩn hóa sample rate, thường 48 kHz, và tránh dùng playback position của Flutter animation làm clock vì frame UI có thể giật. Audio clock hoặc engine monotonic clock mới là nguồn thời gian chính.'
      ),
      (
        '7. Text, sticker và overlay',
        'Ở Flutter, overlay có bounding box để người dùng kéo, pinch scale và rotate. Lưu transform ở tọa độ chuẩn hóa 0..1 thay vì pixel màn hình để preview 720p và export 1080p giống nhau. Text lưu nội dung, font asset, size tương đối, alignment, color, stroke, shadow và animation preset. Sticker lưu asset URI, blend mode và keyframes.\n\nCó hai cách preview: overlay đơn giản có thể render bằng Flutter Stack phía trên Texture để gesture rất mượt; nhưng trước export phải dùng cùng font metrics và transform trong native/FFmpeg. Cách nhất quán hơn là native compositor render cả overlay, còn Flutter chỉ vẽ selection handles. Với animation/effect phức tạp, hướng thứ hai ít lệch hơn.'
      ),
      (
        '8. Transition giữa hai video',
        'Transition chiếm một khoảng giao nhau quanh cut point. Crossfade là output = frameA × (1-progress) + frameB × progress. Slide/zoom/wipe dùng shader thay đổi UV coordinates; blur transition cần thêm pass GPU. Engine nên compile transition thành render nodes thay vì viết if/else trong UI.\n\nPreview cần giữ decoder của clip kế tiếp ở trạng thái warm trước ranh giới vài trăm mili giây. Nếu thiết bị yếu, ưu tiên proxy 540p/720p và giới hạn effect nặng. Khi export, dùng source gốc nên chất lượng không bị giảm theo proxy.'
      ),
      (
        '9. Proxy media là chìa khóa cho thiết bị thật',
        'Video 4K HEVC, nhiều layer và filter có thể vượt khả năng decode realtime của điện thoại. Khi import, background job tạo proxy H.264 720p, thumbnail và waveform. Project giữ cả originalUri và proxyUri. Preview chọn proxy; export luôn quay lại original.\n\nProxy không nên khóa UI. Hiển thị trạng thái “Đang tối ưu để chỉnh sửa”, cho phép preview bản gốc nếu thiết bị chịu được và tiếp tục job khi app foreground trở lại. Cache cần quota và cơ chế dọn theo lastAccessed.'
      ),
      (
        '10. FFmpeg dùng ở đâu, không dùng ở đâu?',
        'FFmpeg rất mạnh để probe metadata, tạo proxy, thumbnail, waveform và export file cuối. Nhưng chạy một lệnh FFmpeg mới sau mỗi lần kéo slider không tạo trải nghiệm realtime; startup, decode lại và ghi file làm latency quá cao.\n\nKhi Export, compiler chuyển Project Model thành filter graph: trim/setpts cho clip, scale/crop, xfade cho transition, overlay/drawtext hoặc image sequence cho overlays, amix/afade cho audio, rồi encode H.264/H.265. Trên mobile có thể tích hợp FFmpegKit-compatible distribution nếu giấy phép phù hợp, hoặc viết pipeline native bằng Media3 Transformer/AVAssetExportSession. Hãy kiểm tra kỹ license codec và binary trước khi phát hành store.\n\nTài liệu filter chính thức: [FFmpeg Filters](https://ffmpeg.org/ffmpeg-filters.html).'
      ),
      (
        '11. Ví dụ Project Model rút gọn',
        '```json\n{\n  "fps": 30,\n  "canvas": "1080x1920",\n  "clips": [\n    {"src":"a.mp4","start":0,"in":1.2,"out":6.2},\n    {"src":"b.mp4","start":4.7,"in":0,"out":5.5}\n  ],\n  "transitions": [{"at":5.0,"type":"crossfade","duration":0.6}],\n  "music": [{"src":"beat.m4a","start":0,"gain":0.55}],\n  "overlays": [{"type":"text","text":"Travel Vlog","start":1,"duration":6,"x":0.5,"y":0.18}]\n}\n```\nHai clip có vùng overlap phục vụ crossfade. Cùng JSON được preview engine compile thành render graph và export compiler compile thành pipeline encode.'
      ),
      (
        '12. State management và undo/redo trong Flutter',
        'Có thể dùng Riverpod, Bloc hoặc ChangeNotifier; quan trọng là state immutable và tách editor command khỏi widget. Các command như TrimClip, MoveOverlay, ChangeTransition có apply/revert. Gesture move liên tục nên được coalesce thành một history entry khi user nhấc tay, nếu không undo sẽ phải lùi hàng trăm bước.\n\nUI chỉ rebuild phần bị ảnh hưởng: timeline track, inspector hoặc selection overlay. Playback position dùng ValueNotifier/stream riêng ở tần suất hợp lý; không rebuild toàn màn hình 30–60 lần mỗi giây.'
      ),
      (
        '13. Đồng bộ preview và export',
        'Đây là nơi editor thường lỗi. Hãy viết golden projects có clip màu, beep audio và overlay tại timestamp cố định. Render frame tại 0.0s, 1.0s, cut point và cuối transition từ preview lẫn export, rồi so sánh sai số. Kiểm tra font, rotation metadata, variable frame rate, HDR/SDR, audio drift và video không có audio.\n\nTelemetry nên đo time-to-first-frame, seek latency p50/p95, dropped frame ratio, export realtime factor, crash theo codec và mức dùng memory. Mục tiêu thực tế cho scrub tốt là frame phản hồi dưới khoảng 100 ms trên thiết bị mục tiêu, không nhất thiết luôn decode full quality.'
      ),
      (
        '14. Lộ trình xây từ MVP đến editor chuyên nghiệp',
        '- Giai đoạn 1: một video, trim, text/sticker tĩnh, Flutter overlay và export FFmpeg.\n- Giai đoạn 2: nhiều clip, timeline/thumbnail/waveform, preload clip kế và crossfade cơ bản.\n- Giai đoạn 3: native Texture compositor, proxy media, nhiều audio track, transition GPU và keyframes.\n- Giai đoạn 4: effect packs, template, autosave, draft recovery, background export và cloud sync.\n\nMVP nên hỗ trợ ít codec/effect nhưng preview chắc chắn. Một editor có 50 transition mà scrub giật và export lệch overlay sẽ kém giá trị hơn editor chỉ có crossfade nhưng “thấy gì xuất nấy”.'
      ),
    ],
  ),
  JournalArticle(
    title: 'Từ Context, Token, RAG đến AI Agent và Skills',
    summary:
        'Hướng dẫn thực hành từ Context, Token, RAG, Memory đến Skills qua ví dụ xây AI Agent trợ lý tài liệu cho đội Flutter.',
    category: 'AI Foundations',
    tags: ['Context', 'Token', 'RAG', 'Memory', 'AI Agent', 'Skills'],
    readTime: '25 phút đọc',
    date: '25 Thg 11, 2026',
    icon: Icons.psychology_alt_rounded,
    content: [
      (
        'Ví dụ xuyên suốt: trợ lý tài liệu cho đội Flutter',
        'Ta sẽ xây một agent trả lời câu hỏi như: “Quy trình release Android của dự án là gì?” Agent phải tìm trong tài liệu nội bộ, trích nguồn, nhớ dự án người dùng đang làm và có thể tạo checklist release khi được yêu cầu.\n\nKiến trúc phù hợp: Flutter chỉ đảm nhiệm giao diện chat và hiển thị nguồn. Backend dùng Python + FastAPI để giữ API key, điều phối model và tools. PostgreSQL lưu user, conversation và audit log; pgvector lưu embedding phục vụ RAG. Redis có thể lưu state ngắn hạn. Model được gọi qua API từ backend, tuyệt đối không đặt secret key trong Flutter Web hoặc mobile app.'
      ),
      (
        '1. Context: model đang được nhìn thấy những gì?',
        'Context là gói thông tin backend gửi cho model trong một lần gọi: system prompt, câu hỏi hiện tại, một phần lịch sử chat, memory liên quan, tài liệu lấy từ RAG và kết quả tool. Context window là sức chứa tối đa của model, được tính bằng token.\n\nNên làm ở đâu? Hãy có một Context Builder trong backend. Lớp này chọn dữ liệu cần thiết rồi mới gọi model; UI không nên tự nối toàn bộ lịch sử chat. Với ví dụ trên, context chỉ cần quy tắc trả lời, câu hỏi hiện tại, tên dự án Flutter đang chọn và 3–5 đoạn tài liệu release liên quan.\n\nSai lầm phổ biến là nhét mọi tài liệu vào prompt. Context dài hơn làm tăng chi phí, chậm phản hồi và khiến thông tin quan trọng bị chìm. Nguyên tắc tốt là: đúng nguồn, đúng thời điểm, ít nhưng đủ.'
      ),
      (
        '2. Token: đơn vị tính chi phí và giới hạn',
        'Model không đọc văn bản theo “từ” giống con người mà chia thành token. Một từ có thể là một hoặc nhiều token; code, JSON và tiếng Việt có cách tách khác nhau. Tổng token đầu vào gồm prompt, lịch sử, tài liệu RAG và tool result; đầu ra là phần model sinh thêm.\n\nNên xử lý ở đâu? Backend cần đặt giới hạn output, đếm hoặc ước lượng input, cắt lịch sử cũ và theo dõi token theo request. Có thể dùng tokenizer chính thức của model; với Python thường dùng thư viện do nhà cung cấp model hỗ trợ.\n\nVí dụ: thay vì gửi 100 trang hướng dẫn release mỗi lần, hệ thống chỉ lấy 4 đoạn, mỗi đoạn khoảng 300–500 token. Nếu hội thoại quá dài, hãy tóm tắt phần cũ thành vài quyết định quan trọng thay vì gửi lại nguyên văn.'
      ),
      (
        '3. Embedding và Vector Database',
        'Embedding là một mảng số biểu diễn ý nghĩa của văn bản. Hai câu gần nghĩa thường có vector gần nhau dù không dùng đúng cùng từ khóa. Vector database lưu các vector và tìm các đoạn gần nhất với vector của câu hỏi.\n\nNên làm ở đâu? Tạo một ingestion worker ở backend. Worker đọc Markdown, PDF hoặc Notion; làm sạch; chia thành chunk theo tiêu đề; tạo embedding; rồi lưu content, vector, URL nguồn, thời gian cập nhật và quyền truy cập. PostgreSQL + pgvector phù hợp khi sản phẩm đã dùng Postgres. Qdrant, Weaviate hoặc Pinecone phù hợp khi cần hệ thống vector chuyên biệt.\n\nVí dụ: câu hỏi “đưa bản Android lên store thế nào?” vẫn tìm được đoạn có tiêu đề “Quy trình phát hành Google Play” nhờ độ gần ngữ nghĩa.'
      ),
      (
        '4. RAG: tìm kiến thức trước khi trả lời',
        'RAG là Retrieval-Augmented Generation: truy xuất kiến thức liên quan rồi bổ sung nó vào context để model tạo câu trả lời. RAG không huấn luyện lại model và không tự bảo đảm câu trả lời đúng; chất lượng phụ thuộc vào dữ liệu, chunking, search, quyền truy cập và prompt yêu cầu trích nguồn.\n\nLuồng của ví dụ: (1) backend nhận câu hỏi; (2) tạo embedding cho câu hỏi; (3) lọc tài liệu theo organization và project; (4) vector search lấy khoảng 10 đoạn; (5) rerank còn 3–5 đoạn tốt nhất; (6) đưa các đoạn cùng URL nguồn vào context; (7) model trả lời và gắn citation.\n\nDùng RAG khi kiến thức riêng, nhiều, thường xuyên thay đổi hoặc cần dẫn nguồn. Không cần RAG cho quy tắc nhỏ và cố định; chúng có thể nằm trong system prompt hoặc code.'
      ),
      (
        '5. Memory: điều gì đáng được nhớ?',
        'Chat history là các tin nhắn đã xảy ra; memory là dữ liệu được chủ động chọn để dùng lại. Short-term memory giữ state của phiên hiện tại, ví dụ project đang chọn và checklist đang làm. Long-term memory giữ thông tin bền hơn, ví dụ người dùng phụ trách Android và muốn câu trả lời bằng tiếng Việt.\n\nNên làm ở đâu? State ngắn hạn có thể nằm trong Redis hoặc conversation state ở Postgres. Memory dài hạn nên là bảng có user_id, loại memory, nội dung, nguồn, thời gian cập nhật và thời hạn. Chỉ backend được ghi memory sau khi validate.\n\nKhông lưu mọi câu nói. Hãy đặt quy tắc: chỉ nhớ sở thích, quyết định hoặc dữ kiện có ích về sau; cho người dùng xem, sửa và xóa. API key, mật khẩu, dữ liệu nhạy cảm không được biến thành memory.'
      ),
      (
        '6. AI Agent khác chatbot ở điểm nào?',
        'Chatbot thường nhận nội dung và tạo một câu trả lời. Agent có mục tiêu, state và vòng lặp: quan sát → chọn hành động → gọi tool → đọc kết quả → quyết định tiếp tục hay dừng. Agent phù hợp khi nhiệm vụ có nhiều bước hoặc cần tác động lên hệ thống.\n\nTrong ví dụ, câu “hãy chuẩn bị release 2.4.0” khiến agent tìm quy trình, đọc phiên bản hiện tại, tạo checklist và lưu draft. Ta giới hạn tối đa 6 vòng lặp, timeout cho từng tool và điều kiện dừng rõ ràng. Nếu chỉ hỏi một khái niệm trong tài liệu, pipeline RAG một lượt đơn giản thường tốt hơn agent; đừng dùng agent chỉ vì đang là xu hướng.'
      ),
      (
        '7. Tool, Function Calling, Skill và MCP',
        'Tool là một khả năng cụ thể do code cung cấp, ví dụ search_docs(query, project_id) hoặc create_release_checklist(version). Function calling là cơ chế để model chọn tool và tạo arguments đúng schema; backend vẫn phải validate arguments, kiểm tra quyền rồi mới thực thi.\n\nSkill là gói kiến thức thao tác cho một lĩnh vực: hướng dẫn từng bước, quy tắc, template, script và tiêu chí kiểm tra. Skill “Flutter release” có thể dạy agent đọc pubspec.yaml, chạy analyzer, build appbundle và kiểm tra artifact. Skill không nhất thiết là code; nó hướng dẫn agent dùng tools nhất quán. MCP là chuẩn kết nối agent với tools hoặc nguồn dữ liệu, hữu ích khi muốn cùng một integration hoạt động với nhiều agent/client.\n\nNên đặt tool implementation ở backend/service; schema đặt cạnh tool; skill lưu có version trong repository; MCP server dùng khi cần chuẩn hóa kết nối. Không cho model gọi shell hoặc database tự do nếu chỉ cần vài function hẹp.'
      ),
      (
        '8. Chọn ngôn ngữ và framework như thế nào?',
        'Frontend: tiếp tục dùng Flutter cho web/mobile nếu cần một codebase và UI đa nền tảng. Flutter chỉ gọi API, stream câu trả lời và render citation/tool status.\n\nBackend: Python + FastAPI là lựa chọn dễ bắt đầu vì hệ sinh thái AI mạnh. Pydantic giúp schema tool chặt chẽ; SQLAlchemy làm việc với Postgres. Nếu team mạnh TypeScript, NestJS hoặc Fastify cũng hoàn toàn phù hợp. Agent có thể viết bằng SDK chính thức để dễ kiểm soát; dùng LangGraph khi workflow có state, nhánh, retry và human approval phức tạp. LlamaIndex phù hợp cho ingestion/RAG. Không cần framework agent ở bản đầu nếu một vòng lặp nhỏ tự viết đã đủ.\n\nHạ tầng: PostgreSQL + pgvector, Redis tùy nhu cầu, object storage cho file, background worker cho ingestion. Luôn giữ model provider phía sau một interface để có thể đổi model và test giả lập.'
      ),
      (
        '9. Ví dụ tường minh từ câu hỏi đến câu trả lời',
        'Người dùng hỏi trên Flutter: “Tạo checklist release Android 2.4.0 cho dự án 67Talk.” Flutter gửi message và projectId đến POST /agent/runs. Backend xác thực user, nạp state rồi Context Builder tạo system prompt. Agent gọi search_docs với query “Android release Google Play” và projectId. RAG trả về các đoạn có nguồn. Agent gọi get_current_version; service trả 2.3.1. Agent tạo draft checklist nhưng chưa deploy. Backend lưu run, tool calls, token usage và citations, sau đó stream từng event về Flutter qua SSE/WebSocket. Flutter hiển thị tiến trình “Đang tìm tài liệu”, checklist và các link nguồn.\n\nNếu người dùng bấm “Xác nhận tạo issue”, backend mới gọi create_github_issue. Model không được tự quyết định quyền này. Đây là human-in-the-loop: AI chuẩn bị, con người duyệt hành động có tác động bên ngoài.'
      ),
      (
        '10. Pseudo-code tối giản của agent',
        'POST /agent/runs → verifyUser() → loadState() → retrieveRelevantDocs() → buildContext(). Sau đó lặp tối đa 6 lần: gọi model với messages và tool schemas; nếu model trả tool call thì validate schema, authorize user, execute tool và nối kết quả vào context; nếu model trả final answer thì kiểm tra citation và stream kết quả; nếu vượt giới hạn thì dừng an toàn.\n\nĐiểm quan trọng không nằm ở cú pháp framework mà ở ranh giới trách nhiệm: model đề xuất hành động; code xác thực và thực thi; database lưu state; UI trình bày và xin xác nhận.'
      ),
      (
        '11. Guardrails, bảo mật và human-in-the-loop',
        'Prompt không phải lớp bảo mật. Backend phải kiểm tra authentication, authorization, tenant/project scope, input schema, rate limit, timeout và kích thước file. RAG phải lọc quyền trước hoặc trong lúc search để tài liệu của dự án khác không lọt vào context. Tool đọc và tool ghi nên tách rõ; deploy, thanh toán, xóa dữ liệu hay gửi nội dung ra ngoài phải yêu cầu xác nhận và có audit log.\n\nChống prompt injection bằng cách coi tài liệu truy xuất là dữ liệu không đáng tin, không phải instruction; không để nội dung tài liệu ghi đè system policy; giới hạn tool theo allowlist và không trả secret trong tool result.'
      ),
      (
        '12. Quy trình build từ MVP đến production',
        'Bước 1: chọn một nhiệm vụ hẹp, ví dụ hỏi đáp tài liệu release, và viết 30 câu hỏi thật làm eval. Bước 2: làm RAG một lượt có citation, chưa cần agent. Bước 3: đo retrieval hit rate, độ đúng, latency và chi phí. Bước 4: thêm đúng 1–2 tools khi người dùng cần hành động. Bước 5: thêm state và vòng lặp agent có giới hạn. Bước 6: thêm memory khi đã biết dữ liệu nào thật sự cần nhớ. Bước 7: thêm approval cho tool ghi, audit log, tracing và cảnh báo. Bước 8: biến mọi lỗi production thành test case.\n\nMột demo đẹp chưa đủ. Hãy đo tỷ lệ tìm đúng tài liệu, citation có hỗ trợ câu trả lời không, gọi đúng tool không, hoàn thành workflow, hallucination, token, latency và tỷ lệ cần con người sửa. Chỉ mở rộng quyền của agent sau khi eval chứng minh nó đủ ổn định.'
      ),
    ],
  ),
  JournalArticle(
    title: 'Tối ưu Flutter Web khi portfolio ngày càng lớn',
    summary:
        'Breakpoint, asset, lazy rendering và những nguyên nhân thực tế làm web Flutter chậm.',
    category: 'Flutter',
    tags: ['Flutter Web', 'Performance'],
    readTime: '6 phút đọc',
    date: '18 Thg 11, 2026',
    icon: Icons.flutter_dash_rounded,
    content: [
      (
        'Đo trước khi tối ưu',
        'Theo dõi kích thước build, thời gian frame đầu và asset lớn trước khi thay đổi.'
      ),
      (
        'Lazy rendering',
        'Chỉ dựng page đang được chọn và trì hoãn module nặng như FFmpeg cho đến khi người dùng thật sự mở tool.'
      ),
    ],
  ),
  JournalArticle(
    title: 'Từ prototype đến 67Talk: bài học về realtime',
    summary:
        'Tổ chức conversation, trạng thái agent và event realtime để hệ thống không trở nên hỗn loạn.',
    category: 'Build Stories',
    tags: ['67Talk', 'Realtime', 'Architecture'],
    readTime: '10 phút đọc',
    date: '10 Thg 11, 2026',
    icon: Icons.forum_rounded,
    content: [
      (
        'Đừng để UI sở hữu realtime state',
        'Event cần đi qua một lớp dữ liệu có khả năng hợp nhất, loại trùng và phục hồi kết nối.'
      ),
      (
        'Thiết kế cho failure',
        'Reconnect, optimistic update và idempotency phải được nghĩ tới từ đầu.'
      ),
    ],
  ),
  JournalArticle(
    title: 'Checklist bảo mật trước khi public source',
    summary:
        'Cách rà soát API key, môi trường, history và quyền truy cập trước khi push GitHub.',
    category: 'Engineering Notes',
    tags: ['Security', 'Git', 'CI'],
    readTime: '5 phút đọc',
    date: '02 Thg 11, 2026',
    icon: Icons.shield_outlined,
    content: [
      (
        'Key public không đồng nghĩa với không cần bảo vệ',
        'Phân biệt publishable key và service key, đồng thời dùng RLS làm lớp bảo vệ thật sự.'
      ),
      (
        'Kiểm tra history',
        'Xóa key khỏi file hiện tại là chưa đủ nếu secret từng được commit trong lịch sử Git.'
      ),
    ],
  ),
  JournalArticle(
    title: 'FFmpeg WASM: xử lý media ngay trong trình duyệt',
    summary:
        'Các giới hạn về memory, codec và UX khi đưa công cụ video lên Flutter Web.',
    category: 'Engineering Notes',
    tags: ['FFmpeg', 'WebAssembly', 'Media'],
    readTime: '7 phút đọc',
    date: '28 Thg 10, 2026',
    icon: Icons.movie_filter_outlined,
    content: [
      (
        'Local-first tạo niềm tin',
        'File được xử lý tại trình duyệt giúp người dùng không phải upload dữ liệu riêng tư.'
      ),
      (
        'Giới hạn tài nguyên',
        'WASM dùng bộ nhớ của tab, vì vậy cần giới hạn file, hiển thị progress và ưu tiên stream-copy khi có thể.'
      ),
    ],
  ),
];

class DevJournalPage extends StatefulWidget {
  const DevJournalPage({super.key});

  @override
  State<DevJournalPage> createState() => _DevJournalPageState();
}

class _DevJournalPageState extends State<DevJournalPage> {
  String _query = '';
  String _category = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Tất cả',
      ...{for (final a in _articles) a.category}
    ];
    final articles = _articles.where((article) {
      final categoryMatches =
          _category == 'Tất cả' || article.category == _category;
      final needle = _query.toLowerCase();
      final queryMatches = needle.isEmpty ||
          article.title.toLowerCase().contains(needle) ||
          article.summary.toLowerCase().contains(needle) ||
          article.tags.any((tag) => tag.toLowerCase().contains(needle));
      return categoryMatches && queryMatches;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 32, 28, compact ? 16 : 32, 16),
                sliver: SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _JournalHero(compact: compact),
                        const SizedBox(height: 24),
                        TextField(
                          onChanged: (value) => setState(() => _query = value),
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Tìm bài viết, chủ đề hoặc công nghệ…',
                            hintStyle: const TextStyle(color: Colors.black38),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: Colors.black54),
                            filled: true,
                            fillColor: const Color(0xFFF2F2F2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, index) {
                              final category = categories[index];
                              return ChoiceChip(
                                label: Text(category),
                                selected: _category == category,
                                selectedColor: Colors.black,
                                backgroundColor: const Color(0xFFF2F2F2),
                                labelStyle: TextStyle(
                                  color: _category == category
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                side: BorderSide.none,
                                onSelected: (_) =>
                                    setState(() => _category = category),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('${articles.length} bài viết',
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 32, 4, compact ? 16 : 32, 32),
                sliver: articles.isEmpty
                    ? const SliverToBoxAdapter(child: _EmptyJournal())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 900),
                              child: _ArticleCard(
                                article: articles[index],
                                onTap: () => _openArticle(articles[index]),
                              ),
                            ),
                          ),
                          childCount: articles.length,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openArticle(JournalArticle article) {
    showDialog<void>(
      context: context,
      builder: (context) => _ArticleDialog(article: article),
    );
  }
}

class _JournalHero extends StatelessWidget {
  const _JournalHero({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 24 : 42),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC017),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quốc Journal',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Georgia',
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: compact ? 28 : 42),
          Text('Ideas worth building.',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Georgia',
                  fontSize: compact ? 40 : 62,
                  height: 1,
                  letterSpacing: -2)),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: const Text(
              'Ghi lại hành trình làm sản phẩm, những bài học kỹ thuật và cách tôi cộng tác với AI trong thời đại vibe coding.',
              style:
                  TextStyle(color: Colors.black87, fontSize: 17, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});
  final JournalArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE6E6E6))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black,
                      child: Icon(article.icon, color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Quốc Huỳnh',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                    ),
                    if (article.featured) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                    ],
                  ]),
                  const SizedBox(height: 10),
                  Text(article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Georgia',
                          fontSize: compact ? 18 : 23,
                          height: 1.2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(article.summary,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF6B6B6B), height: 1.45)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 10, runSpacing: 6, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(article.category,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 11)),
                    ),
                    Text(article.readTime,
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 11)),
                  ]),
                ],
              ),
            ),
            SizedBox(width: compact ? 14 : 28),
            Container(
              width: compact ? 88 : 170,
              height: compact ? 88 : 118,
              color: article.featured
                  ? const Color(0xFFA8E6CF)
                  : const Color(0xFFFFE6A7),
              child: Icon(article.icon,
                  color: Colors.black87, size: compact ? 34 : 48),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleDialog extends StatelessWidget {
  const _ArticleDialog({required this.article});
  final JournalArticle article;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black54),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    compact ? 18 : 28, 0, compact ? 18 : 28, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.category,
                        style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4)),
                    const SizedBox(height: 12),
                    Text(article.title,
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Georgia',
                            fontSize: compact ? 32 : 42,
                            height: 1.2,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text('${article.date}  •  ${article.readTime}',
                        style: const TextStyle(color: Colors.black45)),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: article.tags
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                    if (article.heroImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          article.heroImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (article.heroCaption != null) ...[
                        const SizedBox(height: 9),
                        Text(
                          article.heroCaption!,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                    ],
                    Text(article.summary,
                        style: const TextStyle(
                            color: Color(0xFF6B6B6B),
                            fontFamily: 'Georgia',
                            fontSize: 21,
                            height: 1.6)),
                    if (article.interactiveShaderGallery) ...[
                      const SizedBox(height: 28),
                      const _ShaderArticleGallery(),
                    ],
                    const Divider(height: 48, color: Color(0xFFE6E6E6)),
                    for (final section in article.content) ...[
                      Text(section.$1,
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Georgia',
                              fontSize: compact ? 22 : 25,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _MarkdownLikeBody(source: section.$2),
                      const SizedBox(height: 28),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShaderArticleGallery extends StatefulWidget {
  const _ShaderArticleGallery();

  @override
  State<_ShaderArticleGallery> createState() => _ShaderArticleGalleryState();
}

class _ShaderArticleGalleryState extends State<_ShaderArticleGallery> {
  final _scrollController = ScrollController();

  static const _ids = <String>[
    'fade',
    'diamondwipe',
    'dreamy',
    'crosswarp',
    'cube',
    'pixelize',
    'glitchmemories',
    'circleopen',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final items = [
      for (final id in _ids)
        if (shaderById(id) case final ShaderInfo info) info,
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: Color(0xFF67E8F9), size: 21),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Interactive GL transition lab',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _LiveBadge(),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Cuộn ngang để xem gallery. Di chuột hoặc kéo từ trái sang phải '
            'trên từng ảnh để điều khiển progress A → B.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: compact ? 196 : 220,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 12),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) => _ShaderLabCard(
                  info: items[index],
                  compact: compact,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.swipe_rounded, color: Colors.white38, size: 16),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  '0% = ảnh A · 50% = shader đang trộn · 100% = ảnh B',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShaderLabCard extends StatelessWidget {
  const _ShaderLabCard({required this.info, required this.compact});

  final ShaderInfo info;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 240.0 : 290.0;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ShaderScrubThumb(shaderId: info.id),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            info.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${info.category} · ${info.author}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFF34D399)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: Color(0xFF6EE7B7)),
          SizedBox(width: 6),
          Text(
            'GPU LIVE',
            style: TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkdownLikeBody extends StatelessWidget {
  const _MarkdownLikeBody({required this.source});

  final String source;

  static const _bodyStyle = TextStyle(
    color: Color(0xFF242424),
    fontFamily: 'Georgia',
    fontSize: 19,
    height: 1.75,
  );

  @override
  Widget build(BuildContext context) {
    final blocks = source.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          _buildBlock(context, blocks[index].trim()),
          if (index != blocks.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildBlock(BuildContext context, String block) {
    if (block.startsWith('```') && block.endsWith('```')) {
      final firstBreak = block.indexOf('\n');
      final code = firstBreak == -1
          ? block.substring(3, block.length - 3)
          : block.substring(firstBreak + 1, block.length - 3);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(
          code.trim(),
          style: const TextStyle(
            color: Color(0xFFE8E8E8),
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.55,
          ),
        ),
      );
    }

    if (block.startsWith('> ')) {
      return Container(
        padding: const EdgeInsets.only(left: 18),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Colors.black, width: 3)),
        ),
        child: _LinkedText(
          source: block.substring(2),
          style: _bodyStyle.copyWith(
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final lines = block.split('\n');
    if (lines.every((line) => line.startsWith('- '))) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 11, right: 12),
                    child:
                        CircleAvatar(radius: 3, backgroundColor: Colors.black),
                  ),
                  Expanded(
                    child: _LinkedText(
                      source: line.substring(2),
                      style: _bodyStyle,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return _LinkedText(source: block, style: _bodyStyle);
  }
}

class _LinkedText extends StatelessWidget {
  const _LinkedText({required this.source, required this.style});

  final String source;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final linkPattern = RegExp(r'\[([^\]]+)\]\((https?://[^\s)]+)\)');
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in linkPattern.allMatches(source)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, match.start)));
      }
      final label = match.group(1)!;
      final url = match.group(2)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(url)),
            child: Text(
              label,
              style: style.copyWith(
                color: const Color(0xFF1565C0),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF1565C0),
              ),
            ),
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor)));
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 70),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, color: Colors.black26, size: 48),
            SizedBox(height: 12),
            Text('Không tìm thấy bài viết phù hợp',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
