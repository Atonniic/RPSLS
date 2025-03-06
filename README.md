# **README - เกม RPSLS (Rock, Paper, Scissors, Lizard, Spock) บน Solidity**

โปรเจกต์นี้เป็น **Smart Contract** ที่ใช้ Solidity ในการพัฒนาเกม **Rock, Paper, Scissors, Lizard, Spock** โดยมีเป้าหมายหลักคือ:

✅ ใช้ **Commit-Reveal Scheme** เพื่อป้องกันการโกง  
✅ ป้องกัน **ETH ติดค้าง** ในสัญญาโดยให้ผู้เล่นสามารถขอคืนเงินได้  
✅ ควบคุม **ระยะเวลา** เพื่อให้เกมดำเนินไปอย่างราบรื่น  
✅ ใช้ **ระบบแฮช (keccak256)** เพื่อซ่อนค่าเลือกของผู้เล่น  
✅ ตัดสินผู้ชนะและโอนเงินรางวัลโดยอัตโนมัติ  

---
## **🔹 การป้องกันการ lock เงินไว้ใน contract**
### **ปัญหา:**  
หากผู้เล่นเข้าเกมแต่ไม่ทำการ commit หรือ reveal เกมจะไม่สามารถดำเนินต่อไปได้ และ ETH จะติดอยู่ในสัญญา

### **วิธีแก้ไข:**  
เพิ่มฟังก์ชัน `refund()` เพื่อให้ผู้เล่นสามารถขอคืนเงินได้ หากเกมหยุดชะงักเป็นเวลานาน

```solidity
function refund() public {
    require(timeUnit.isTimeExceeded(), "Refund period not elapsed");
    require(numPlayer > 0, "No active game");

    address payable account0 = payable(players[0]);

    if (numPlayer == 1) {
        require(msg.sender == players[0], "Only player can refund");
        account0.transfer(reward);
    } else {
        require(msg.sender == players[0] || msg.sender == players[1], "Unauthorized refund");
        address payable account1 = payable(players[1]);
        account0.transfer(reward / 2);
        account1.transfer(reward / 2);
    }

    _resetGame();
}
```
**วิธีทำงาน:**  
- หากมี **ผู้เล่นแค่คนเดียว** พวกเขาสามารถขอเงินคืนทั้งหมด  
- หากมี **ผู้เล่นสองคน** แต่เกมไม่เดินหน้า พวกเขาสามารถขอเงินคืน **คนละครึ่ง**  
- ฟังก์ชัน `timeUnit.isTimeExceeded()` ป้องกันการขอคืนเงินก่อนเวลา  

---

## **🔹 การซ่อนค่า choice และ commit**
### **ปัญหา:**  
หากผู้เล่นส่งค่าเลือกของตนทันที อาจทำให้ฝ่ายตรงข้าม **frontrunning** ได้  

### **วิธีแก้ไข:**  
ใช้ **Commit-Reveal** โดยให้ผู้เล่นทำการ **commit (ส่งค่าแฮช)** ก่อน แล้วค่อย **reveal (เปิดเผยค่า)** ภายหลัง  

### **ขั้นตอน Commit (ซ่อนค่าเลือก)**
```solidity
function inputCommit(bytes32 commitHash) public {
    require(numPlayer == 2, "Game is not ready.");

    commitReveal.commit(commitHash, msg.sender);
    numCommits++;

    timeUnit.updateActionTime();
}
```
- `commitHash` คือค่า **keccak256(abi.encodePacked(rand_bytes, choice))**  
- ส่งไปที่ smart contract โดยไม่เปิดเผยค่าเลือกของตน  

### **ตัวอย่างการสร้างค่า Commit ด้วย Python**
```python
import random
# generate 31 random bytes
rand_num = random.getrandbits(256 - 8)
rand_bytes = hex(rand_num)

# choice: '00', '01', '02', '03', '04' (Scissors, Paper, Rock, Lizard, Spock)
# concatenate choice to rand_bytes to make 32 bytes data_input
choice = '01'
data_input = rand_bytes + choice
print(data_input)
print(len(data_input))
print()

# need padding if data_input has less than 66 symbols (< 32 bytes)
if len(data_input) < 66:
  print("Need padding.")
  data_input = data_input[0:2] + '0' * (66 - len(data_input)) + data_input[2:]
  assert(len(data_input) == 66)
else:
  print("Need no padding.")
print("Choice is", choice)
print("Use the following bytes32 as an input to the getHash function:", data_input)
print(len(data_input))
```

---

## **🔹 การจัดการกับเกมที่ผู้เล่นล่าช้า**
### **ปัญหา:**  
- ผู้เล่นอาจเข้ามา **แค่คนเดียว** แล้วรอเป็นเวลานาน  
- อีกฝ่ายอาจ commit แต่ไม่ reveal ทำให้เกมไม่สามารถดำเนินต่อไป  

### **วิธีแก้ไข:**  
- ใช้ตัวแปร `latestActionTime` เพื่อติดตามเวลาการทำงานล่าสุด  
- หากไม่มีการกระทำเป็นเวลา **1 นาที** ผู้เล่นสามารถขอคืนเงินได้  

### **โค้ดการจัดการเวลา (TimeUnit.sol)**
```solidity
function updateActionTime() public {
    latestActionTime = block.timestamp;
}

function isTimeExceeded() public view returns (bool) {
    return (block.timestamp - latestActionTime) > delayTime;
}
```
- ทุกครั้งที่ผู้เล่นทำ **commit, reveal, addPlayer** เวลาจะถูกอัปเดต  
- ฟังก์ชัน `isTimeExceeded()` จะตรวจสอบว่าครบ **1 นาที** หรือไม่  

---

## **🔹 การเปิดเผยค่าเลือกและตัดสินผู้ชนะ**
### **ปัญหา:**  
- ผู้เล่นต้องเปิดเผยค่าที่เลือกในลักษณะที่ปลอดภัย  
- ระบบต้องตรวจสอบว่าการเปิดเผยค่านั้น **ตรงกับ commit** ที่ทำไว้ก่อนหน้า  

### **วิธีแก้ไข:**  
- ผู้เล่นต้องส่ง **rand_bytes + choice** ที่ใช้ใน commit  
- Smart contract จะคำนวณค่าแฮชและตรวจสอบว่าตรงกันหรือไม่  

### **ฟังก์ชัน Reveal**
```solidity
function revealChoice(bytes32 revealHash) public {
    require(numCommits == 2, "Both players must commit before revealing.");

    commitReveal.reveal(revealHash, msg.sender);
    uint8 choiceFromHash = getChoiceFromHash(revealHash);
    player_choice[msg.sender] = choiceFromHash;
    numReveals++;

    if (numReveals == 2) {
        _checkWinnerAndPay();
    }

    timeUnit.updateActionTime();
}
```
