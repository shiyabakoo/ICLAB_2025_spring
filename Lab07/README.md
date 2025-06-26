## CDC (Clock Domain Crossing)
這個Lab用到的CDC解法有兩個, 第一個是The Handshake synchronizer, 第二個是FIFO synchronizer

---

### The Handshake synchronizer
Handshake synchronizer 是一種利用handshake的方式來確保data有成功在不同clock domain中傳遞的synchronizer
當有data要從sclk傳到dclk時Src Ctrl會發出sreq並把sclk的MUX設為0讓data保持不變, 當Dest Ctrl收到dreg時會發出dack並接收從sclk傳來的data, 
最後Src Ctrl收到sack後將MUX改回1來傳下一筆data
![image](https://github.com/user-attachments/assets/c05ccf6b-c12a-4548-ab5f-031f354e1f3a)

### FIFO synchronizer
