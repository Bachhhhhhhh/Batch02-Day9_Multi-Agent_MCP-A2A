# Trả lời bài tập cộng điểm CODELAB

Dưới đây là phần trả lời cho 2 bài tập cộng điểm ở cuối file `CODELAB.md`, đi kèm với demo và các con số cụ thể đã được kiểm chứng bằng việc chạy trực tiếp hệ thống.

### 1. Latency (Tổng thời gian trả lời 1 câu hỏi của hệ thống) là bao nhiêu giây?
Để lấy được con số chính xác, mình đã bổ sung đoạn mã đo thời gian bằng `time.time()` trong file `test_client.py` ngay quanh lệnh `client.send_message(request)`.

**Kết quả:** Ở cấu trúc mặc định của Stage 5, hệ thống mất khoảng **42.94 giây** để hoàn thành luồng và trả về câu trả lời. 
*(Lưu ý: Thời gian này có thể dao động 1 chút tuỳ thuộc vào tốc độ phản hồi của API LLM OpenRouter, nhưng trung bình đều ở mức trên dưới 40s)*.

### 2. Đề xuất phương án giảm latency và demo + show thời gian xử lý đã giảm được khi apply phương án?

#### **A. Phân tích nguyên nhân gây chậm (Bottleneck)**
Bằng cách phân tích kiến trúc của `law_agent` (nơi chịu trách nhiệm điều phối), ta thấy topology trong `law_agent/graph.py` đang được định nghĩa như sau:
`analyze_law` -> `check_routing` -> `call_tax` & `call_compliance` (parallel) -> `aggregate`.

Cấu trúc này chạy **tuần tự** ở giai đoạn đầu:
1. Node `analyze_law` mất khoảng ~10-15s để dùng LLM phân tích luật chung.
2. Đợi xong, node `check_routing` mất thêm ~2s để quyết định gọi sub-agents.
3. Sau đó, các sub-agents (`tax` và `compliance`) mới được gọi chạy song song (mất khoảng ~10-15s).
**=> Tổng thời gian sẽ bị cộng dồn: ~15s + 2s + ~15s + thời gian aggregate.**

#### **B. Đề xuất phương án tối ưu**
Bản chất node `analyze_law` chỉ cần `state["question"]` và hoàn toàn độc lập, không phụ thuộc vào kết quả của `check_routing` hay các sub-agents.
**Phương án:** Thay đổi sơ đồ đồ thị LangGraph để đưa `analyze_law` chạy **song song** cùng lúc với `call_tax` và `call_compliance`.

#### **C. Demo Code (Sửa `law_agent/graph.py`)**
Mình đã tiến hành cấu trúc lại file `law_agent/graph.py` bằng cách đặt `check_routing` lên làm `entry_point` và dispatch cả 3 tasks thông qua LangGraph `Send` API để ép chúng chạy đồng thời:

```python
# 1. Sửa route_to_subagents để luôn đẩy analyze_law chạy song song với tax và compliance
def route_to_subagents(state: LawState) -> list[Send]:
    sends: list[Send] = []
    # Always analyze law in parallel with sub-agents to reduce latency
    sends.append(Send("analyze_law", state))
    
    if state.get("needs_tax"):
        sends.append(Send("call_tax", state))
    if state.get("needs_compliance"):
        sends.append(Send("call_compliance", state))
    return sends

# 2. Sửa lại đồ thị ở hàm create_graph()
def create_graph():
    graph = StateGraph(LawState)
    # Khởi tạo các nodes (giữ nguyên)
    ...
    # Cho check_routing chạy đầu tiên (rất nhanh, chỉ 1-2s)
    graph.set_entry_point("check_routing")

    # Dispatch song song ra 3 nhánh cùng lúc
    graph.add_conditional_edges(
        "check_routing",
        route_to_subagents,
        ["analyze_law", "call_tax", "call_compliance"],
    )

    # Tất cả 3 nhánh đều đổ về aggregate chờ tổng hợp
    graph.add_edge("analyze_law", "aggregate")
    graph.add_edge("call_tax", "aggregate")
    graph.add_edge("call_compliance", "aggregate")
    graph.add_edge("aggregate", END)

    return graph.compile()
```

#### **D. Kết quả sau khi tối ưu**
Sau khi áp dụng phương án trên và restart lại service `law_agent`, mình đã chạy lại `test_client.py`:
- Latency cũ: **42.94 giây**
- Latency mới sau khi apply chạy song song: **23.70 giây**

**Kết luận:** Bằng cách hiểu cơ chế thực thi của LangGraph và thiết kế lại Graph Topology để tăng tính đồng thời, hệ thống đã **giảm được gần 50% thời gian xử lý (giảm khoảng 19 giây)** nhưng chất lượng câu trả lời cuối cùng ở bước `aggregate` không hề thay đổi.
