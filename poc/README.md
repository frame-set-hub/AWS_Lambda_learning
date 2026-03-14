# AWS Lambda POC — Spring Boot Invoker

POC สำหรับเรียกใช้งาน AWS Lambda จาก Spring Boot Application ผ่าน AWS SDK for Java v2

## สารบัญ

- [โครงสร้างโปรเจกต์](#โครงสร้างโปรเจกต์)
- [Prerequisites](#prerequisites)
- [ขั้นตอนการใช้งาน](#ขั้นตอนการใช้งาน)
  - [1. ตั้งค่า Credentials](#1-ตั้งค่า-credentials)
  - [2. Deploy Lambda Function](#2-deploy-lambda-function)
  - [3. รัน Spring Boot Application](#3-รัน-spring-boot-application)
  - [4. ทดสอบเรียก API](#4-ทดสอบเรียก-api)
- [สถาปัตยกรรม](#สถาปัตยกรรม)
  - [Overview Diagram](#overview-diagram)
  - [Tech Stack](#tech-stack)
  - [Request Flow (Sequence)](#request-flow-sequence)
  - [Spring Boot Internal Flow](#spring-boot-internal-flow)
  - [Deploy Flow](#deploy-flow)
  - [Security & Credentials Flow](#security--credentials-flow)
- [Cleanup](#cleanup)

---

## โครงสร้างโปรเจกต์

```
poc/
├── .env.example              # ตัวอย่างไฟล์ credentials
├── .gitignore                # ป้องกัน .env ขึ้น git
├── deploy-lambda.sh          # Script deploy Lambda ขึ้น AWS
├── cleanup-lambda.sh         # Script ลบ resources ทั้งหมด
├── lambda-function/
│   └── lambda_function.py    # Lambda function code (Python)
└── spring-boot-invoker/
    ├── pom.xml
    └── src/main/
        ├── java/com/example/lambda/
        │   ├── LambdaInvokerApplication.java
        │   ├── config/AwsConfig.java
        │   ├── controller/LambdaController.java
        │   └── service/LambdaService.java
        └── resources/application.yml
```

## Prerequisites

- Java 17+
- Maven
- AWS CLI (`aws configure` หรือใช้ `.env`)
- AWS Account ที่มีสิทธิ์สร้าง Lambda + IAM Role

## ขั้นตอนการใช้งาน

### 1. ตั้งค่า Credentials

```bash
cp .env.example .env
```

แก้ไขไฟล์ `.env` ใส่ credentials ของคุณ:

```env
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJal...
AWS_REGION=ap-southeast-1
LAMBDA_FUNCTION_NAME=poc-hello-lambda
```

### 2. Deploy Lambda Function

```bash
chmod +x deploy-lambda.sh
./deploy-lambda.sh
```

Script จะทำ 4 ขั้นตอนอัตโนมัติ:
1. สร้าง IAM Execution Role
2. Package โค้ด Lambda เป็น `.zip`
3. สร้าง/อัปเดต Lambda function บน AWS
4. ทดสอบ invoke ครั้งแรก

### 3. รัน Spring Boot Application

```bash
cd spring-boot-invoker

# Load .env แล้วรัน
set -a && source ../.env && set +a
./mvnw spring-boot:run
```

หรือถ้าใช้ Maven ปกติ:

```bash
set -a && source ../.env && set +a
mvn spring-boot:run
```

### 4. ทดสอบเรียก API

```bash
# Greet — เรียก Lambda ให้ทักทาย
curl http://localhost:8080/api/lambda/greet?name=John

# Time — ให้ Lambda ส่งเวลา UTC กลับมา
curl http://localhost:8080/api/lambda/time?name=Dev

# Calculate — ให้ Lambda คำนวณผลบวก
curl "http://localhost:8080/api/lambda/calculate?name=Dev&a=10&b=20"

# Custom Payload — ส่ง JSON ตรงๆ
curl -X POST http://localhost:8080/api/lambda/invoke \
  -H "Content-Type: application/json" \
  -d '{"name": "Boss", "action": "greet"}'
```

## สถาปัตยกรรม

### Overview Diagram

```
                          ┌─── LOCAL MACHINE ───────────────────────┐
                          │                                         │
┌──────────┐   HTTP GET   │  ┌──────────────────────────────────┐   │   HTTPS (AWS SDK)
│  Client  │ ────────────▶│  │     Spring Boot App (:8080)      │   │──────────────────┐
│  (curl/  │              │  │                                  │   │                  │
│  Browser/│              │  │  ┌────────────┐ ┌─────────────┐  │   │                  ▼
│  Postman)│◀────────────│  │  │ Controller │→│   Service   │  │   │    ┌──── AWS Cloud ────────┐
│          │  JSON resp   │  │  └────────────┘ └──────┬──────┘  │   │    │                       │
└──────────┘              │  │                        │         │   │    │  ┌─────────────────┐  │
                          │  │  ┌──────────┐   ┌──────┴──────┐  │   │    │  │  AWS Lambda     │  │
                          │  │  │  .env    │──▶│ AWS Config  │  │   │    │  │  (Python 3.12)  │  │
                          │  │  │ (creds)  │   │ (LambdaClient)│ │   │    │  │                 │  │
                          │  │  └──────────┘   └─────────────┘  │   │    │  │  lambda_handler │  │
                          │  └──────────────────────────────────┘   │    │  └────────┬────────┘  │
                          └─────────────────────────────────────────┘    │           │           │
                                                                        │     JSON response     │
                                                                        └───────────────────────┘
```

### Tech Stack

```
┌────────────────────────────────────────────────────────────────────┐
│                        POC Tech Stack                              │
├────────────────┬───────────────────────────────────────────────────┤
│   Layer        │   Technology                                      │
├────────────────┼───────────────────────────────────────────────────┤
│   Client       │   curl / Browser / Postman                       │
├────────────────┼───────────────────────────────────────────────────┤
│   Web Layer    │   Spring Boot 3.3 + Spring Web (REST Controller) │
├────────────────┼───────────────────────────────────────────────────┤
│   Service      │   LambdaService (business logic)                 │
├────────────────┼───────────────────────────────────────────────────┤
│   AWS SDK      │   AWS SDK for Java v2 (software.amazon.awssdk)   │
├────────────────┼───────────────────────────────────────────────────┤
│   Auth         │   .env → DefaultCredentialsProvider              │
├────────────────┼───────────────────────────────────────────────────┤
│   Runtime      │   Java 17                                        │
├────────────────┼───────────────────────────────────────────────────┤
│   Lambda       │   Python 3.12 (deployed via AWS CLI)             │
├────────────────┼───────────────────────────────────────────────────┤
│   IaC/Deploy   │   Bash script + AWS CLI                          │
└────────────────┴───────────────────────────────────────────────────┘
```

### Request Flow (Sequence)

```
  Client              Spring Boot                    AWS
    │                     │                           │
    │  GET /api/lambda/   │                           │
    │  greet?name=John    │                           │
    │────────────────────▶│                           │
    │                     │                           │
    │              ┌──────┴──────┐                    │
    │              │ Controller  │                    │
    │              │ สร้าง JSON   │                    │
    │              │ payload     │                    │
    │              └──────┬──────┘                    │
    │                     │                           │
    │              ┌──────┴──────┐                    │
    │              │  Service    │  InvokeRequest     │
    │              │  LambdaClient─────────────────▶│
    │              │  .invoke()  │                    │
    │              └──────┬──────┘                    │
    │                     │                    ┌──────┴──────┐
    │                     │                    │   Lambda    │
    │                     │                    │  handler()  │
    │                     │                    │  ประมวลผล    │
    │                     │                    └──────┬──────┘
    │                     │                           │
    │                     │   InvokeResponse          │
    │                     │◀──────────────────────────│
    │                     │   {statusCode, body}      │
    │                     │                           │
    │   200 OK            │                           │
    │   {"message":...}   │                           │
    │◀────────────────────│                           │
    │                     │                           │
```

### Spring Boot Internal Flow

```
                    ┌─────────────────────────────────────────────┐
                    │            Spring Boot Application           │
                    │                                             │
  HTTP Request ────▶│  ┌───────────────────┐                     │
                    │  │  LambdaController  │                     │
                    │  │                   │                     │
                    │  │  /api/lambda/greet │  @GetMapping        │
                    │  │  /api/lambda/time  │  @PostMapping       │
                    │  │  /api/lambda/calc  │                     │
                    │  │  /api/lambda/invoke│                     │
                    │  └────────┬──────────┘                     │
                    │           │ calls                           │
                    │           ▼                                 │
                    │  ┌───────────────────┐                     │
                    │  │  LambdaService    │  @Service            │
                    │  │                   │                     │
                    │  │  invoke(payload)  │──▶ สร้าง InvokeRequest│
                    │  │                   │──▶ เรียก LambdaClient │
                    │  │                   │──▶ จัดการ error       │
                    │  └────────┬──────────┘                     │
                    │           │ uses                            │
                    │           ▼                                 │
                    │  ┌───────────────────┐                     │
                    │  │  AwsConfig        │  @Configuration     │
                    │  │                   │                     │
                    │  │  @Bean            │                     │
                    │  │  LambdaClient     │──▶ Region from .env  │
                    │  │                   │──▶ Credentials       │
                    │  └───────────────────┘     from .env        │
                    └─────────────────────────────────────────────┘
```

### Deploy Flow

```
  Developer                  deploy-lambda.sh                     AWS
      │                           │                                │
      │  ./deploy-lambda.sh       │                                │
      │──────────────────────────▶│                                │
      │                           │                                │
      │                    ┌──────┴──────┐                         │
      │                    │ Load .env   │                         │
      │                    │ credentials │                         │
      │                    └──────┬──────┘                         │
      │                           │                                │
      │                    [1] Create IAM Role                     │
      │                           │────────────────────────────▶│
      │                           │   iam create-role              │
      │                           │   + attach policy              │
      │                           │                                │
      │                    [2] Package Code                        │
      │                           │                                │
      │                    ┌──────┴──────┐                         │
      │                    │ zip -j      │                         │
      │                    │ lambda_func │                         │
      │                    └──────┬──────┘                         │
      │                           │                                │
      │                    [3] Deploy Lambda                       │
      │                           │────────────────────────────▶│
      │                           │   lambda create-function       │
      │                           │   --zip-file --runtime         │
      │                           │                                │
      │                    [4] Test Invoke                         │
      │                           │────────────────────────────▶│
      │                           │   lambda invoke                │
      │                           │◀───────────────────────────────│
      │                           │   response.json                │
      │  ✅ Deploy Complete        │                                │
      │◀──────────────────────────│                                │
```

### Security & Credentials Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    Credentials Flow                              │
│                                                                  │
│   .env (LOCAL ONLY — never committed to git)                    │
│   ┌──────────────────────────────────────┐                      │
│   │ AWS_ACCESS_KEY_ID=AKIA...            │                      │
│   │ AWS_SECRET_ACCESS_KEY=wJal...        │                      │
│   │ AWS_REGION=ap-southeast-1            │                      │
│   │ LAMBDA_FUNCTION_NAME=poc-hello-lambda│                      │
│   └──────────┬───────────────────────────┘                      │
│              │                                                   │
│    ┌─────────┴──────────┐                                       │
│    ▼                    ▼                                        │
│  deploy-lambda.sh    Spring Boot                                │
│  (source .env)       (spring-dotenv)                            │
│    │                    │                                        │
│    ▼                    ▼                                        │
│  AWS CLI             DefaultCredentialsProvider                  │
│  (aws lambda...)     (reads env vars automatically)             │
│    │                    │                                        │
│    └────────┬───────────┘                                       │
│             ▼                                                    │
│  ┌─────────────────────┐        ┌──────────────────────┐        │
│  │   AWS IAM Auth      │───────▶│  Lambda Execution    │        │
│  │   (your account)    │        │  Role (IAM)          │        │
│  └─────────────────────┘        │  ขาออก: CloudWatch   │        │
│                                 │  Logs เท่านั้น        │        │
│                                 └──────────────────────┘        │
│                                                                  │
│  .gitignore ป้องกัน .env ไม่ให้ถูก commit ขึ้น repository      │
└──────────────────────────────────────────────────────────────────┘
```

## Cleanup

ลบ resources ทั้งหมดออกจาก AWS:

```bash
chmod +x cleanup-lambda.sh
./cleanup-lambda.sh
```
