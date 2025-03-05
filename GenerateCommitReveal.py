import random
import hashlib

def generate_commit(choice):
    """
    สร้างค่า commit โดยใช้ random value + choice และคำนวณ keccak256 hash
    """
    # สร้าง random value 31 ไบต์ (62 ตัวอักษร Hex) และเติม choice 2 ตัวอักษรท้าย
    rand_num = random.getrandbits(256 - 8)
    rand_hex = hex(rand_num)[2:]  # ตัด '0x' ออก

    # ทำให้ random hex มีความยาว 62 ตัวอักษร (31 bytes)
    rand_hex = rand_hex.zfill(62)

    # เติม choice 2 หลัก (00 - Rock, 01 - Paper, 02 - Scissors, 03 - Lizard, 04 - Spock)
    data_input = rand_hex + choice.zfill(2)

    # ตรวจสอบว่า data_input มีความยาว 64 ตัวอักษร (32 bytes)
    assert len(data_input) == 64

    # คำนวณ keccak256 hash
    commit_hash = hashlib.sha3_256(bytes.fromhex(data_input)).hexdigest()

    return commit_hash, data_input

def reveal(data_input):
    """
    ใช้ data_input ที่เก็บค่า random + choice เพื่อนำไปใช้ในฟังก์ชัน reveal บน Solidity
    """
    return bytes.fromhex(data_input)  # แปลงกลับเป็น bytes32 เพื่อนำไปใช้บน Solidity

# 📝 **ตัวเลือกเกม**
choices = {
    "0": "Rock",
    "1": "Paper",
    "2": "Scissors",
    "3": "Lizard",
    "4": "Spock"
}

# 🔹 **รับค่าตัวเลือกจากผู้เล่น**
print("เลือกตัวเลือกของคุณ:")
for key, value in choices.items():
    print(f"{key}: {value}")

user_choice = input("ป้อนตัวเลือก (0-4): ").strip()
if user_choice not in choices:
    print("❌ ตัวเลือกไม่ถูกต้อง! กรุณาเลือก 0-4")
    exit()

# 🔹 **สร้างค่า Commit**
commit_hash, data_input = generate_commit(user_choice)
print("\n✅ ค่าที่ต้องใช้สำหรับ commit() ใน Solidity:", commit_hash)
print("✅ ค่าที่ต้องใช้สำหรับ reveal() ใน Solidity:", data_input)
print("\n📌 ใช้ data_input นี้เป็น parameter `bytes32 revealHash` ในฟังก์ชัน reveal()")
