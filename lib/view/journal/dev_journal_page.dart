import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    const Text('Quốc Huỳnh',
                        style: TextStyle(color: Colors.black87, fontSize: 12)),
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
                  Row(children: [
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
                    const SizedBox(width: 10),
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
