# AWS Lambda Learning

สถาปัตยกรรม Serverless สู่ความยืดหยุ่นที่ไร้ขีดจำกัด — คู่มือฉบับสมบูรณ์สำหรับผู้บริหารและนักพัฒนา

## สารบัญ

- [เอกสารประกอบการเรียนรู้](#เอกสารประกอบการเรียนรู้)
- [POC: เรียกใช้ AWS Lambda จาก Spring Boot](#poc-เรียกใช้-aws-lambda-จาก-spring-boot)
- [ภาพรวมเนื้อหา](#ภาพรวมเนื้อหา)
  - [1. Serverless Paradigm](#1-serverless-paradigm--จาก-server-based-สู่-serverless)
  - [2. 7 เสาหลักของสถาปัตยกรรม AWS Lambda](#2-7-เสาหลักของสถาปัตยกรรม-aws-lambda)
  - [3. โครงสร้างภายในของ Lambda Function](#3-โครงสร้างภายในของ-lambda-function)
  - [4. หลักการออกแบบฟังก์ชัน](#4-หลักการออกแบบฟังก์ชัน)
  - [5. Invocation Models](#5-invocation-models--3-รูปแบบการเรียกใช้งาน)
  - [6. Configuring & Billing](#6-configuring--billing--จ่ายตามทรัพยากรที่จัดสรร)
  - [7. Concurrency](#7-concurrency--กลไกรองรับผู้ใช้งานพร้อมกันจำนวนมหาศาล)
  - [8. Deploying](#8-deploying--การปรับใช้ระบบใหม่อย่างปลอดภัย)
  - [9. Security](#9-security--ระบบรักษาความปลอดภัย-2-ชั้น-dual-layer-security)
  - [10. Monitoring](#10-monitoring--ระบบตรวจสอบและติดตามสถานะแบบ-360-องศา)
- [เนื้อหาระดับ Enterprise](#เนื้อหาระดับ-enterprise)
  - [11. Event-Driven Architecture](#11-event-driven-architecture--ขับเคลื่อนระบบด้วยเหตุการณ์)
  - [12. AWS SAM](#12-aws-sam--จัดการโครงสร้างพื้นฐานอย่างเป็นระบบ)
  - [13. Anatomy of an Invocation](#13-anatomy-of-an-invocation--วงจรชีวิตและ-cold-start)
  - [14. Conquering Cold Starts](#14-conquering-cold-starts)
  - [15. Connecting to the World](#15-connecting-to-the-world--ประตูเชื่อมสู่ภายนอก)
  - [16. The Observability Triad](#16-the-observability-triad--สามง่ามแห่งการตรวจสอบระบบ)
- [วงจรแห่งสถาปัตยกรรม Serverless ที่สมบูรณ์แบบ](#วงจรแห่งสถาปัตยกรรม-serverless-ที่สมบูรณ์แบบ)


---

## เอกสารประกอบการเรียนรู้

- [AWS Lambda Blueprint (พื้นฐาน)](./AWS_Lambda_Blueprint.pdf) — 14 หน้า
- [AWS Lambda Enterprise Blueprint (ระดับองค์กร)](./AWS_Lambda_Enterprise_Blueprint.pdf) — 15 หน้า

---

## ภาพรวมเนื้อหา

### 1. Serverless Paradigm — จาก Server-based สู่ Serverless

เปรียบเทียบสถาปัตยกรรมแบบเดิม (Server-based) ที่ต้องจ่ายค่าเซิร์ฟเวอร์ตลอดเวลา กับ AWS Lambda ที่ทำงานแบบ Event-Driven — สร้างขึ้นเมื่อมีความต้องการใช้งาน และสลายไปเมื่อทำงานเสร็จสิ้น

**Business Value:**
- Pay-per-use: จ่ายตามการประมวลผลจริงระดับมิลลิวินาที
- Zero Maintenance: ไร้ภาระการจัดการเซิร์ฟเวอร์
- Auto-scaling: ขยายตัวรับทราฟฟิกมหาศาลได้ทันที

### 2. 7 เสาหลักของสถาปัตยกรรม AWS Lambda

| กลุ่ม | เสาหลัก | คำอธิบาย |
|---|---|---|
| **Build** (สร้างกลไก) | 1. Authoring | เข้าใจโครงสร้างและรูปแบบการเรียกใช้งาน |
| | 7. Invocation Models | รูปแบบการเรียกใช้: Synchronous, Asynchronous, Polling |
| **Scale** (บริหารขุมพลัง) | 2. Configuring & Billing | จัดการทรัพยากร Memory/CPU และรูปแบบการคิดเงิน |
| | 3. Concurrency | กลไกรองรับผู้ใช้งานพร้อมกัน (Standard, Burst, Reserved) |
| **Govern** (ควบคุมและตรวจสอบ) | 4. Deploying | การปรับใช้ระบบใหม่ด้วย Versions, Aliases และ Traffic Shifting |
| | 5. Monitoring | ระบบตรวจสอบและติดตามสถานะแบบ 360 องศา |
| | 6. Security | ระบบรักษาความปลอดภัย 2 ชั้น (Dual-Layer Security) |

### 3. โครงสร้างภายในของ Lambda Function

- **Trigger (Event):** ข้อมูลจากผู้เรียกใช้งาน (เช่น ไฟล์ S3)
- **Handler Method:** ประตูรับข้อมูล (Entry Point)
- **Business Logic:** ส่วนประมวลผลหลักที่ต้องถูกแยกออกอย่างเด็ดขาด
- **Context:** สภาวะแวดล้อม (เช่น เวลาที่เหลือ)
- รองรับหลายภาษา: Node.js, Python, Java, Go, C#, Ruby, PowerShell และ Custom Runtimes

### 4. หลักการออกแบบฟังก์ชัน

- **Modular Design** — 1 ฟังก์ชัน = 1 หน้าที่ ออกแบบให้ทำหน้าที่เดียวอย่างสมบูรณ์
- **Separate Business Logic** — แยกโค้ดประมวลผลออกจาก Handler เพื่อให้ Unit Test ได้ง่ายและนำโค้ดไปใช้ซ้ำได้
- **Statelessness** — ฟังก์ชันจะดำรงอยู่เมื่อถูกเรียกใช้เท่านั้น ห้ามบันทึกข้อมูลสถานะใดๆ ไว้ใน Execution Environment (ทุกการเรียกใช้คือการเริ่มต้นใหม่)

### 5. Invocation Models — 3 รูปแบบการเรียกใช้งาน

| รูปแบบ | กลไก | ลักษณะ | ตัวอย่าง |
|---|---|---|---|
| **Synchronous** | สั่งงานแล้วรอคำตอบกลับทันที | ระบบจะหยุดรอจนกว่าฟังก์ชันจะทำงานเสร็จ | Amazon API Gateway |
| **Asynchronous** | สั่งงานแล้วลืม (Fire and forget) | ส่งข้อมูลเข้าระบบแล้วไปทำงานอื่นต่อได้เลย ไม่ต้องรอผลลัพธ์ | Amazon S3 Events |
| **Polling** | ดึงข้อมูลมาประมวลผลอย่างต่อเนื่อง | Lambda เป็นผู้ดึงข้อมูลจาก Stream หรือ Queue ทีละชุด | Amazon SQS, DynamoDB Streams |

### 6. Configuring & Billing — จ่ายตามทรัพยากรที่จัดสรร

- **Memory Allocation:** สามารถกำหนด Memory ได้สูงสุด 10 GB (ระบบจะจัดสรร CPU และเครือข่ายให้แปรผันตาม Memory โดยอัตโนมัติ)
- **Billing:** จ่ายตาม 'ทรัพยากรที่ตั้งค่าไว้ (Allocated)' ไม่ใช่ตามที่ 'ใช้จริง (Used)' โดยคิดรอบละ 1 มิลลิวินาที
- **Timeout (Fail Fast):** ตั้งเวลา Timeout ได้สูงสุด 15 นาที แต่ควรตั้งค่าให้สั้นที่สุดหลังจากการทดสอบโหลด เพื่อป้องกันระบบค้างและเกิดค่าใช้จ่ายบานปลาย

**Power Tuning — ปรากฏการณ์ที่การเพิ่มสเปคช่วยลดต้นทุน:**
- การตั้งค่า Memory ต่ำสุดไม่ได้แปลว่าประหยัดที่สุดเสมอไป
- การเพิ่ม Memory = เพิ่มความแรง CPU = ฟังก์ชันทำงานเสร็จเร็วขึ้นอย่างก้าวกระโดด
- เมื่อระยะเวลาทำงานลดลงฮวบ ค่าใช้จ่ายรวมต่อครั้งลดลง แม้จะใช้ Memory สูงขึ้นก็ตาม
- ใช้เครื่องมือ **AWS Lambda Power Tuning** เพื่อค้นหาจุดสมดุลที่สมบูรณ์แบบนี้โดยอัตโนมัติ

### 7. Concurrency — กลไกรองรับผู้ใช้งานพร้อมกันจำนวนมหาศาล

- **Standard Concurrency:** ความจุที่นั่งปกติของระบบในเสี้ยววินาทีนั้นๆ
- **Burst Concurrency:** รองรับทราฟฟิกพุ่งกะทันหัน (เช่น 3,000 requests) และขยายเพิ่ม 1,000 อินสแตนซ์ทุกๆ 10 วินาที
- **Reserved Concurrency:** การันตีทรัพยากรไว้ให้ฟังก์ชันที่สำคัญที่สุด ป้องกันไม่ให้ถูกแย่งโควตาจนหมด

**Rate Limiting — ทำไม Lambda ที่ขยายตัวได้ไร้ขีดจำกัดจึงต้องถูกจำกัดความเร็ว?**
1. ป้องกันคอขวดของระบบปลายทาง (เช่น RDS ล่ม)
2. ควบคุมงบประมาณ
3. จัดระเบียบ Batch Processing

### 8. Deploying — การปรับใช้ระบบใหม่อย่างปลอดภัย

- **Versions & Aliases:** สร้าง Snapshot ของโค้ดที่ไม่สามารถแก้ไขได้ (Immutable) และใช้ Alias เป็นเสมือน 'ป้ายบอกทาง' ไปยังเวอร์ชันที่ต้องการ
- **Traffic Shifting:** ลดความเสี่ยงในการขึ้นระบบใหม่ด้วยการทยอยย้ายผู้ใช้งาน แบบค่อยเป็นค่อยไป (Canary หรือ Linear)
- **AWS SAM:** เครื่องมือสร้าง Blueprint แบบย่อที่แปลงคำสั่งสั้นๆ ให้กลายเป็น AWS CloudFormation ขั้นสูง

### 9. Security — ระบบรักษาความปลอดภัย 2 ชั้น (Dual-Layer Security)

- **ประตูขาเข้า — Resource-based Policy:** กำหนดว่าใคร หรือ บริการใด (เช่น S3) ที่ได้รับอนุญาตให้ส่งคำสั่ง Invoke ฟังก์ชันนี้
- **ประตูขาออก — Execution Role (IAM):** กำหนดว่าตัวฟังก์ชันนี้มีสิทธิ์ที่จะไปกระทำการใดๆ กับบริการอื่นของ AWS บ้าง (เช่น เขียนข้อมูลลง Database)

### 10. Monitoring — ระบบตรวจสอบและติดตามสถานะแบบ 360 องศา

- **CloudWatch:** Metrics & Diagnostics — หน้าปัดรถยนต์ดูความร้อนและความเร็ว (Ops)
- **Lambda Insights:** CPU/Memory & Cold Starts
- **AWS X-Ray:** Service Map & Bottlenecks — กล้องเอกซเรย์สแกนทะลุหาจุดคอขวด (Dev)
- **AWS CloudTrail:** Audit & Security Trace — กล้องวงจรปิดบันทึกประวัติการเข้าออก (Sec)
- **Dead-letter queues (DLQ):** ตะกร้าเก็บตกรองรับรายการที่ประมวลผลล้มเหลวเพื่อนำกลับมาตรวจสอบและแก้ไข

---

## เนื้อหาระดับ Enterprise

### 11. Event-Driven Architecture — ขับเคลื่อนระบบด้วยเหตุการณ์

ตัวอย่าง Flow: ผู้ใช้งานอัปโหลดไฟล์ (Trigger) → Amazon S3 สร้าง Event → AWS Lambda ถูกปลุกขึ้นมาประมวลผลทันที (เช่น เข้ารหัสไฟล์) → เก็บไฟล์ที่ประมวลผลเสร็จแล้ว

> **Insight:** ระบบไม่ต้องเปิดสแตนด์บายตลอดเวลา Lambda จะรันโค้ดก็ต่อเมื่อมีกริ่งเตือน (Event) จากบริการอื่นๆ เช่น S3, API Gateway หรือ DynamoDB เท่านั้น

### 12. AWS SAM — จัดการโครงสร้างพื้นฐานอย่างเป็นระบบ

**AWS Serverless Application Model (SAM)** คือเครื่องมือแปลงโค้ด (YAML/JSON) ให้กลายเป็นโครงสร้างพื้นฐานจริงบน AWS (Infrastructure as Code - IaC)

ทำไมระดับองค์กรถึงต้องใช้ SAM?
- **All-in-One:** รวบรวม Lambda, S3 บัคเก็ต, และ API ไว้ในเทมเพลตเดียว
- **Repeatable:** สร้างสภาพแวดล้อม (Dev, Test, Prod) ซ้ำได้เหมือนเดิม 100%
- **Zero Human Error:** ลดความผิดพลาดจากการตั้งค่าผ่านหน้าเว็บ Console ด้วยมือ

```yaml
Resources:
  MyProcessorFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: index.handler
      Runtime: python3.9
      Events:
        FileUpload: S3Event
```

### 13. Anatomy of an Invocation — วงจรชีวิตและ Cold Start

**3 ช่วงของวงจรชีวิต:**
1. **INIT** — ช่วงสตาร์ทเครื่อง: โหลด Extension, บูต Runtime, รับโค้ดตั้งค่า (Static Code)
2. **INVOKE** — ช่วงเร่งเครื่อง: รันฟังก์ชัน Handler ประมวลผลข้อมูลจริง
3. **SHUTDOWN** — ช่วงดับเครื่อง: ล้างข้อมูลและปิดระบบ

**The Challenge: Cold Start**
- การเรียกใช้งานครั้งแรก (Cold Start) กินเวลานานกว่าปกติเพราะต้องวิ่งผ่านรอบ INIT ก่อน
- การเรียกซ้ำ (Warm Start) จะข้ามไปที่ INVOKE ทันที
- มักเกิดน้อยกว่า 1% แต่เป็นศัตรูตัวฉกาจของแอปพลิเคชันที่ต้องการความหน่วงต่ำ (Low Latency)

### 14. Conquering Cold Starts

#### Provisioned Concurrency
- เป็นการจองและเตรียมพร้อม (Pre-initialized) สภาพแวดล้อมไว้ล่วงหน้า
- ข้ามช่วง INIT ทั้งหมด รันโค้ด INVOKE ได้ทันทีเมื่อ Request เข้ามา
- กำจัดปัญหา Cold Start 100% แต่มีค่าใช้จ่ายเพิ่มเติมแม้จะไม่มีทราฟฟิก

#### Lambda SnapStart
- ระบบจะรัน INIT ไว้ล่วงหน้าตั้งแต่ตอน Deploy แล้วถ่ายภาพ Snapshot เก็บสถานะของ Memory และ Disk ไว้ในแคชความเร็วสูง
- เมื่อมีผู้ใช้งาน ระบบจะ Resume จาก Snapshot ทันที ลดเวลา Startup Performance ลงได้สูงสุดถึง 10 เท่า
- **ฟรี** ไม่มีค่าใช้จ่ายเพิ่มเติม แต่ปัจจุบันรองรับเฉพาะ Java 11 และ 17

#### Decision Matrix: เลือกเครื่องมือใดจัดการ Cold Start?

| | Provisioned Concurrency | Lambda SnapStart |
|---|---|---|
| **กลไกการทำงาน** | เตรียมสภาพแวดล้อมรอไว้ล่วงหน้า | Resume จาก Snapshot ที่บันทึกไว้ตอน Deploy |
| **ผลลัพธ์ Latency** | ต่ำและคงที่ที่สุดตลอดเวลา 100% | ลด Latency ลงอย่างมีนัยสำคัญ แต่อาจแปรปรวนเล็กน้อย |
| **ค่าใช้จ่าย** | มีค่าใช้จ่ายล่วงหน้า แม้ไม่มีทราฟฟิก | ฟรี จ่ายตาม Invocations ปกติ |
| **ภาษาที่รองรับ** | รองรับทุกภาษา | เฉพาะ Java 11/17+ |

> **กรอบการตัดสินใจ:** หากต้องการ Latency นิ่งสนิทในระบบที่ทราฟฟิกพุ่งกระฉูด ให้ยอมจ่ายค่า Provisioned Concurrency แต่หากใช้ Java และต้องการลดเวลา Init แบบฟรีๆ ให้เปิด SnapStart ทันที

### 15. Connecting to the World — ประตูเชื่อมสู่ภายนอก

เมื่อเขียนโค้ดเสร็จสิ้น เราต้องเลือกวิธีให้ระบบภายนอกสามารถเรียกใช้ (Invoke) ฟังก์ชันของเราผ่าน HTTP(S)

| | Amazon API Gateway | Lambda Function URLs |
|---|---|---|
| **Features** | ระบบครบวงจร (Rate limiting, WAF Security, Custom Domains, Auth แบบซับซ้อนอย่าง Cognito/OAuth 2.0) | สร้าง endpoint ได้ภายในคลิกเดียว, ใช้สิทธิ์ Auth ผ่าน AWS IAM หรือเปิด Public |
| **Cost** | คิดค่าใช้จ่ายตามจำนวน Request | ฟรี (จ่ายแค่ค่ารัน Lambda เท่านั้น) |
| **Best For** | Enterprise APIs, แอปพลิเคชันที่ต้องการความปลอดภัยและการจัดการทราฟฟิกขั้นสูง | Webhooks, Microservices ภายในองค์กร, หรืองานทดสอบระบบ |

> **Architectural Decision:** เลือก Function URLs เพื่อความรวดเร็วและประหยัด แต่จงเลือก API Gateway เมื่อต้องการบริหารจัดการระบบขนาดใหญ่

### 16. The Observability Triad — สามง่ามแห่งการตรวจสอบระบบ

สถาปัตยกรรม Serverless ไม่มีเซิร์ฟเวอร์ให้เราล็อกอินเข้าไปดู Log ได้ตรงๆ จึงมอบเครื่องมือ 3 ตัวเพื่อตอบโจทย์ Operations, Developers, และ Security แบบกระจายตัว (Distributed)

**Amazon CloudWatch — ศูนย์ควบคุมและแจ้งเตือน:**
- Metrics & Alarms: ติดตามตัวชี้วัดอัตโนมัติ และสามารถตั้ง Alarm แจ้งเตือนไปยังทีมเมื่อ Error พุ่งสูงเกิน Threshold
- CloudWatch Logs: ข้อมูลการรันทุกบรรทัด (console.log, logger.error) จะถูกสตรีมมาเก็บที่ Log Group อัตโนมัติ
- Executive Insight: ผู้บริหารสามารถใช้ CloudWatch เพื่อประเมินความคุ้มค่าของการทำงาน (Billed Duration) และควบคุมระดับคุณภาพบริการ (SLA)

**AWS X-Ray — เอกซเรย์ค้นหาคอขวดในสถาปัตยกรรม:**
- Distributed Tracing: ติดตาม Request 1 รายการตั้งแต่ต้นทางจนจบกระบวนการผ่านหลายบริการ
- Bottleneck Identification: เผยให้เห็นชัดเจนว่าระบบ 'ช้า' ที่ไหน
- Subsegments Analysis: เจาะลึกทะลุระดับโค้ด เพื่อดูว่าการโหลด SDK หรือการรันฟังก์ชันย่อยกินเวลาเท่าไหร่

**AWS CloudTrail — กล้องวงจรปิดบันทึกทุกความเคลื่อนไหว:**
- บันทึกประวัติ API (Who, What, When, Where) ทุกการเรียกใช้ API และการเปลี่ยนแปลงภายใน AWS Account อย่างละเอียด
- หัวใจสำคัญที่สุดระดับ Enterprise สำหรับ Security Audit, การสืบสวนสาเหตุเบื้องหลัง (Forensics), และการผ่าเร่ฐานข้อบังคับขององค์กร

---

## วงจรแห่งสถาปัตยกรรม Serverless ที่สมบูรณ์แบบ

```
BUILD: สร้างกลไก
  ├── ออกแบบฟังก์ชันแบบ Modular, ไร้สถานะ
  └── ใช้ SAM สร้าง Blueprint

SCALE: บริหารขุมพลัง
  ├── หาจุดคุ้มทุนด้วย Power Tuning
  └── จัดระเบียบด้วย Concurrency Limit

GOVERN: ควบคุมและตรวจสอบ
  ├── ป้องกันระบบด้วย Dual-Layer Security
  └── ตรวจสอบย้อนหลังด้วย X-Ray & CloudTrail
```

> **Ultimate Takeaway:** AWS Lambda ไม่ใช่แค่เซิร์ฟเวอร์รูปแบบใหม่ แต่เป็น 'สถาปัตยกรรม' ที่ปลดล็อกให้องค์กรสามารถพัฒนานวัตกรรมได้อย่างรวดเร็ว ขยายตัวได้ไร้ขีดจำกัด ปลอดภัย และจ่ายเงินเฉพาะเวลาที่สร้างมูลค่าทางธุรกิจเท่านั้น

---

## POC: เรียกใช้ AWS Lambda จาก Spring Boot

โปรเจกต์ตัวอย่าง (Proof of Concept) สำหรับทดสอบเรียกใช้ AWS Lambda จริงผ่าน Spring Boot + AWS SDK for Java v2

### สถาปัตยกรรม POC

```
┌─────────────────┐     HTTP      ┌──────────────────────┐    AWS SDK    ┌─────────────────┐
│   Client/curl   │ ──────────▶  │  Spring Boot App     │ ──────────▶  │  AWS Lambda     │
│                 │  :8080       │  (Java 17 + SDK v2)  │   Invoke     │  (Python 3.12)  │
└─────────────────┘              └──────────────────────┘              └─────────────────┘
```

### Tech Stack

| Component | Technology |
|---|---|
| Lambda Function | Python 3.12 |
| Client Application | Spring Boot 3.3 + Java 17 |
| AWS SDK | AWS SDK for Java v2 |
| Credentials | `.env` file (via spring-dotenv) |
| Deploy | AWS CLI + Bash script |

### Quick Start

```bash
# 1. ตั้งค่า credentials
cd poc
cp .env.example .env   # แก้ไขใส่ AWS credentials

# 2. Deploy Lambda ขึ้น AWS
chmod +x deploy-lambda.sh
./deploy-lambda.sh

# 3. รัน Spring Boot
cd spring-boot-invoker
set -a && source ../.env && set +a
mvn spring-boot:run

# 4. ทดสอบ
curl http://localhost:8080/api/lambda/greet?name=John
curl "http://localhost:8080/api/lambda/calculate?name=Dev&a=10&b=20"
```

> รายละเอียดเพิ่มเติมดูที่ [poc/README.md](./poc/README.md)
