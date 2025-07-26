## LOW POWER DESIGN
這個lab主要是用Clock Gating的方式來節省動態功耗

---

### Clock Gating
Clock Gating分成OR gate跟AND gate兩種, 會將clock訊號皆在其中一個input, 另一個input則是接上控制訊號
但為了防止控制訊號的glitch導致電路function出問題, 會加上latch來避免glitch的影響, 如下圖

<img width="1291" height="256" alt="image" src="https://github.com/user-attachments/assets/3ca3311a-c3c2-47da-a3b6-57d86f53d15e" />

而在節省功耗這方面, OR-gating會比AND-gating省下更多的power, 因為在OR-gating中Gated clock會被維持在high, 這使得flip flop中第一個latch不會隨input做改變, 但在AND-gating中要到第二個latch才不隨input變化

因此在這次lab中使用的是OR-gating來做low power design

