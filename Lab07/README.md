## CDC (Clock Domain Crossing)
這個Lab用到的CDC解法有兩個, 第一個是The Handshake synchronizer, 第二個是FIFO synchronizer, 而這兩個方法都會用到NDFF synchronizer

---
### NDFF synchronizer
NDFF sync是最簡單處理CDC問題的synchronizer
![image](https://github.com/user-attachments/assets/e5b08717-049f-4d74-9ca6-123010b9979b)
CDC的問題是metastability(signal會處在一個unstable的狀態, 本來應該要為1的最後有可能掉到0), 當兩個不同clock的flip flop要傳data時, 很大機率會遇到timing violation造成destination clock 的data不穩定進而產生錯誤, 因此會在destination clock端再多加一級flip flop來穩定data, 如下圖

![image](https://github.com/user-attachments/assets/acb65318-a764-4610-b5bb-2cb317bac074)

第一級的ff處在metastability, 用第二級的ff來讓signal穩定在1
### The Handshake synchronizer
Handshake synchronizer 是一種利用handshake的方式來確保data有成功在不同clock domain中傳遞的synchronizer
當有data要從sclk傳到dclk時Src Ctrl會發出sreq並把sclk的MUX設為0讓data保持不變, 當Dest Ctrl收到dreg時會發出dack並接收從sclk傳來的data, 
最後Src Ctrl收到sack後將MUX改回1來傳下一筆data
![image](https://github.com/user-attachments/assets/c05ccf6b-c12a-4548-ab5f-031f354e1f3a)

### FIFO synchronizer
FIFO synchronizer是一個可以提高throughput的方法, 利用FIFO當作兩個clock domain傳遞data的橋樑, 讀寫分別在不同的clock domain並用double flipflop的方式去同步write pointer跟read pointer來判斷full跟empty, 但為了避免convergence(double flipflop同步多bit的data的過程中可能會出現錯誤的值)的問題, 因此wptr跟rptr會用gray code的方式設計
![image](https://github.com/user-attachments/assets/bcb119cf-4569-483d-9ec3-88185ed9387a)
