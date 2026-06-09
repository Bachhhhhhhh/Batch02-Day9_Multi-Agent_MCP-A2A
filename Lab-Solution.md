# Lab Solution - Day 09 Multi-Agent, MCP & A2A

## 1. Thông tin đối chiếu

- Repo gốc: [VinUni-AI20k/Batch02-Day9_Multi-Agent_MCP-A2A](https://github.com/VinUni-AI20k/Batch02-Day9_Multi-Agent_MCP-A2A)
- Nhánh đối chiếu: `upstream/main`
- Commit upstream đã đối chiếu: `8ddde6c` (`add checklist for lab assignment`)
- Nội dung thực hiện dựa trên `CODELAB.md`, `exercises/README.md` và
  [`Lab-assignment-checklist.md`](https://github.com/VinUni-AI20k/Batch02-Day9_Multi-Agent_MCP-A2A/blob/main/Lab-assignment-checklist.md)
  từ upstream.

Checklist yêu cầu nộp:

- Có file `Lab-Solution.md` ghi lại lời giải các bài lab trên lớp.
- Có folder `Lab_Assignment` chứa bài cải tiến Agent Day08 theo mô hình Supervisor - Workers, tối thiểu 2-3 workers.

## 2. Kết quả tổng quan

Đã hoàn thành lộ trình từ Direct LLM đến hệ thống Multi-Agent phân tán:

1. Stage 1: Direct LLM.
2. Stage 2: LLM kết hợp RAG/Tools.
3. Stage 3: Single ReAct Agent.
4. Stage 4: Multi-Agent in-process.
5. Stage 5: Distributed Multi-Agent qua A2A.
6. Bài tập cộng điểm đo và tối ưu latency.
7. Bài cải tiến Day08 trong folder `Lab_Assignment`.

## 3. Bài tập theo CODELAB

### Stage 1 - Direct LLM

**Bài 1.1: Thay đổi câu hỏi**

Đã đổi câu hỏi mẫu sang tình huống pháp luật lao động Việt Nam:

> Theo pháp luật Việt Nam, hợp đồng lao động giao kết bằng lời nói có giá trị pháp lý không?

File: `stages/stage_1_direct_llm/main.py`

**Bài 1.2: Temperature control**

Đã cấu hình LLM dùng:

```python
max_tokens=1000
temperature=0.3
```

`temperature=0.3` giúp câu trả lời ổn định và ít ngẫu nhiên hơn.

File: `common/llm.py`

### Stage 2 - LLM + RAG & Tools

**Bài 2.1: Thêm dữ liệu luật lao động**

Đã thêm entry `labor_law` vào `LEGAL_KNOWLEDGE`, gồm các từ khóa:

- `lao động`
- `sa thải`
- `hợp đồng lao động`
- `labor`
- `termination`

Nội dung mô tả các trường hợp người sử dụng lao động có thể đơn phương chấm dứt hợp đồng theo Bộ luật Lao động Việt Nam 2019.

**Bài 2.2: Tool kiểm tra thời hiệu**

Đã triển khai tool:

```python
check_statute_of_limitations(case_type: str)
```

Tool hỗ trợ các loại vụ án:

| Loại vụ án | Thời hiệu trả về |
|---|---|
| `contract` | 4 năm, UCC § 2-725 |
| `tort` | 2-3 năm tùy bang |
| `property` | 5 năm |

Tool đã được:

- Thêm vào danh sách tools.
- Bind vào LLM.
- Xử lý khi LLM phát sinh tool call.
- Test bằng câu hỏi về thời hiệu vi phạm hợp đồng.

Files:

- `exercises/exercise_2_tools.py`
- `stages/stage_2_rag_tools/main.py`

### Stage 3 - Single Agent với ReAct

**Bài 3.1: Tool tra cứu án lệ**

Đã thêm tool:

```python
search_case_law(keywords: str)
```

Các án lệ mẫu:

- `Hadley v. Baxendale (1854)` cho breach/consequential damages.
- `Donoghue v. Stevenson (1932)` cho negligence/duty of care.
- `Carlill v. Carbolic Smoke Ball Co (1893)` cho unilateral contract.

Tool được thêm vào `TOOLS` và test bằng câu hỏi về breach of contract.

**Bài 3.2: Theo dõi quá trình ReAct**

Phiên bản LangGraph đang dùng hỗ trợ `debug=True`, vì vậy agent được khởi tạo bằng:

```python
create_react_agent(
    model=llm,
    tools=TOOLS,
    prompt=SYSTEM_PROMPT,
    debug=True,
)
```

Chế độ này hiển thị các bước agent quyết định tool, gọi tool, nhận kết quả và tổng hợp câu trả lời.

File: `stages/stage_3_single_agent/main.py`

### Stage 4 - Multi-Agent In-Process

**Bài 4.1: Privacy Agent**

Đã bổ sung `privacy_agent` chuyên xử lý:

- GDPR.
- Data protection.
- Privacy rights.
- Data breach.

State được mở rộng với `privacy_analysis`; kết quả Privacy Agent được đưa vào báo cáo tổng hợp.

**Bài 4.2: Conditional routing**

Đã triển khai routing theo từ khóa:

- Tax Agent: `tax`, `irs`, `thuế`.
- Compliance Agent: `compliance`, `sec`, `regulation`.
- Privacy Agent: `data`, `privacy`, `gdpr`, `dữ liệu`.

Các specialist được dispatch bằng LangGraph `Send` API và hội tụ tại node aggregate.

Đã thêm:

- Node `privacy_agent`.
- Edge từ Privacy Agent đến aggregate.
- Phần Privacy Analysis trong final response.
- Xuất graph thành `stages/stage_4_milti_agent/graph_stage4.png`.

Files:

- `exercises/exercise_4_multiagent.py`
- `stages/stage_4_milti_agent/main.py`
- `stages/stage_4_milti_agent/graph_stage4.png`

### Stage 5 - Distributed A2A

Hệ thống gồm 5 service:

| Service | Port | Trách nhiệm |
|---|---:|---|
| Registry | 10000 | Đăng ký và discovery service |
| Customer Agent | 10100 | Nhận yêu cầu từ người dùng |
| Law Agent | 10101 | Orchestrator/Supervisor |
| Tax Agent | 10102 | Worker chuyên gia thuế |
| Compliance Agent | 10103 | Worker chuyên gia tuân thủ |

Các agent giao tiếp qua HTTP/A2A, dùng Registry để tìm endpoint động thay vì hardcode URL.

**Bài 5.1: Trace request flow**

Đã theo dõi luồng:

```text
User
  -> Customer Agent
  -> Registry discovery
  -> Law Agent
  -> Registry discovery
  -> Tax Agent và Compliance Agent chạy song song
  -> Law Agent aggregate
  -> Customer Agent
  -> User
```

Sequence diagram được lưu tại:

`stages/stage_5_a2a_protocol/sequence_diagram.md`

Hệ thống gốc cũng truyền `trace_id`, `context_id` và giới hạn `MAX_DELEGATION_DEPTH=3` qua các A2A hop để hỗ trợ debug và tránh vòng lặp delegation vô hạn.

**Bài 5.2: Dynamic discovery**

Tax Agent và Compliance Agent đăng ký capability với Registry. Law Agent gọi `discover()` trước khi delegate. Nếu worker không hoạt động, lời gọi A2A được bắt lỗi và aggregate vẫn nhận thông báo specialist unavailable thay vì làm hỏng toàn bộ tiến trình.

**Bài 5.3: Thay đổi hành vi Tax Agent**

Đã cập nhật system prompt của Tax Agent:

- Trả lời cực kỳ ngắn gọn.
- Ưu tiên bullet points.
- Giới hạn dưới 100 từ.

File: `tax_agent/graph.py`

Đã bổ sung `start_all.ps1` để khởi động toàn bộ service thuận tiện trên Windows.

## 4. Bài tập trong folder exercises

### Exercise 2 - Tools và Knowledge Base

Đã hoàn thành toàn bộ TODO:

- Thêm knowledge entry luật lao động.
- Tạo `check_statute_of_limitations`.
- Bind tool mới vào LLM.
- Execute đúng tool call.
- Test câu hỏi về thời hiệu.

File: `exercises/exercise_2_tools.py`

### Exercise 4 - Multi-Agent với Privacy Agent

Đã hoàn thành toàn bộ TODO:

- Implement `privacy_agent`.
- Thêm conditional routing.
- Thêm Privacy Agent vào graph.
- Thêm edge về aggregate.
- Tổng hợp `privacy_analysis`.
- Test với câu hỏi về rò rỉ dữ liệu.

File: `exercises/exercise_4_multiagent.py`

## 5. Bài tập cộng điểm - Latency Optimization

### Đo latency ban đầu

Đã thêm đo thời gian quanh lời gọi A2A trong `test_client.py`:

```python
start_time = time.time()
response = await client.send_message(request)
latency = time.time() - start_time
```

Kết quả đo với topology ban đầu:

**42.94 giây**

### Phân tích bottleneck

Topology cũ:

```text
analyze_law
  -> check_routing
  -> Tax/Compliance chạy song song
  -> aggregate
```

`analyze_law` phải hoàn thành trước khi các worker bắt đầu, khiến latency của các bước bị cộng dồn.

### Phương án tối ưu

Đã đổi `check_routing` thành entry point và dispatch đồng thời:

- `analyze_law`
- `call_tax`
- `call_compliance`

Ba nhánh cùng hội tụ tại `aggregate`.

Topology mới:

```text
check_routing
  -> analyze_law ---------\
  -> call_tax -------------+-> aggregate
  -> call_compliance -----/
```

File: `law_agent/graph.py`

### Kết quả sau tối ưu

| Chỉ số | Trước | Sau |
|---|---:|---:|
| Latency | 42.94 giây | 23.70 giây |
| Thời gian giảm |  | 19.24 giây |
| Tỷ lệ giảm |  | khoảng 44.8% |

Kết quả chi tiết: `stages/bonus_answers.md`

Demo trực quan: `bonus_demos/bonus_demo_latency_optimization.html`

## 6. Demo trực quan bổ sung

Đã xây dựng ba demo HTML độc lập:

| Demo | Nội dung |
|---|---|
| `bonus_demo_stage4_in_process.html` | Minh họa graph Multi-Agent Stage 4 |
| `bonus_demo_stage5_a2a.html` | Minh họa service discovery và A2A HTTP Stage 5 |
| `bonus_demo_latency_optimization.html` | So sánh sequential và parallel flow |

Các demo giúp quan sát node đang chạy, luồng request và sự khác biệt latency giữa hai topology.

## 7. Lab Assignment - Cải tiến Agent Day08

Toàn bộ bài cải tiến Day08 được đặt trong folder:

`Lab_Assignment`

Phần này nâng cấp hệ thống RAG + LLM của Day08 thành kiến trúc Supervisor - Workers và hỗ trợ hai chế độ:

- Stage 4: Multi-Agent in-process.
- Stage 5: Multi-Agent phân tán qua A2A.

### Kiến trúc Supervisor - Workers

Supervisor/Orchestrator:

- Law Agent/Router nhận yêu cầu, phân loại và điều phối.
- Aggregator tổng hợp kết quả từ các worker.

Workers:

- Law Agent: phân tích pháp luật chung.
- Criminal Agent: phân tích trách nhiệm hình sự.
- Rehab Agent: phân tích cai nghiện và phục hồi.

Customer Agent là entry point; Registry đảm nhiệm discovery khi chạy Stage 5.

### Observability

Đã bổ sung giao diện theo dõi:

- Graph riêng cho Stage 4 và Stage 5.
- Node đang chạy được highlight theo thời gian thực.
- Hiển thị trạng thái `idle`, `running`, `completed`, `error`.
- Đo latency từng node và toàn bộ request.
- Trace log ghi rõ agent, action, tool call và output.
- Cho phép chuyển đổi giữa Stage 4 và Stage 5 trên giao diện.

Các thành phần chính:

- `Lab_Assignment/app.py`
- `Lab_Assignment/frontend/index.html`
- `Lab_Assignment/common/telemetry.py`
- `Lab_Assignment/src/multi_agent_stage4.py`
- `Lab_Assignment/law_agent/graph.py`
- `Lab_Assignment/customer_agent/`
- `Lab_Assignment/criminal_agent/`
- `Lab_Assignment/rehab_agent/`

Folder không chứa `.env`, `.venv`, nested `.git`, cache hoặc database local.

## 8. Kiểm thử

Các kiểm tra đã thực hiện:

- Compile toàn bộ Python trong repo Day09 thành công.
- Hoàn thành import smoke test cho `Lab_Assignment/app.py`.
- Kiểm tra cú pháp `start_all.ps1` thành công.
- Khởi động giao diện `Lab_Assignment` ở cổng test và nhận HTTP `200`.
- Chạy Stage 5 để ghi nhận latency trước và sau tối ưu.
- Kiểm tra `.env` và `.venv` được Git ignore.

## 9. Kết luận

Bài lab đã đáp ứng các phần bắt buộc trong `CODELAB.md`, hai exercise trong `exercises/README.md`, checklist nộp bài mới nhất và phần bài tập cộng điểm. Ngoài việc hoàn thành skeleton code, bài làm còn mở rộng hệ thống bằng graph trực quan, trace log, latency telemetry, demo HTML và bài cải tiến Day08 theo mô hình Supervisor - Workers trong `Lab_Assignment`.
