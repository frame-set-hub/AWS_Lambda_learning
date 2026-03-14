package com.example.lambda.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.lambda.service.LambdaService;

@RestController
@RequestMapping("/api/lambda")
public class LambdaController {

    private final LambdaService lambdaService;
    private final ObjectMapper objectMapper;

    public LambdaController(LambdaService lambdaService, ObjectMapper objectMapper) {
        this.lambdaService = lambdaService;
        this.objectMapper = objectMapper;
    }

    /**
     * GET /api/lambda/greet?name=John
     * ทดสอบเรียก Lambda แบบง่ายๆ
     */
    @GetMapping("/greet")
    public ResponseEntity<String> greet(@RequestParam(defaultValue = "World") String name) {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("name", name);
        payload.put("action", "greet");

        String result = lambdaService.invoke(payload.toString());
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/lambda/time?name=Dev
     * ให้ Lambda ส่งเวลาปัจจุบันกลับมา
     */
    @GetMapping("/time")
    public ResponseEntity<String> time(@RequestParam(defaultValue = "Dev") String name) {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("name", name);
        payload.put("action", "time");

        String result = lambdaService.invoke(payload.toString());
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/lambda/calculate?name=Dev&a=10&b=20
     * ให้ Lambda คำนวณค่าแล้วส่งกลับ
     */
    @GetMapping("/calculate")
    public ResponseEntity<String> calculate(
            @RequestParam(defaultValue = "Dev") String name,
            @RequestParam(defaultValue = "0") int a,
            @RequestParam(defaultValue = "0") int b) {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("name", name);
        payload.put("action", "calculate");
        payload.put("a", a);
        payload.put("b", b);

        String result = lambdaService.invoke(payload.toString());
        return ResponseEntity.ok(result);
    }

    /**
     * POST /api/lambda/invoke
     * ส่ง custom payload ไปยัง Lambda โดยตรง
     */
    @PostMapping("/invoke")
    public ResponseEntity<String> invoke(@RequestBody String payload) {
        String result = lambdaService.invoke(payload);
        return ResponseEntity.ok(result);
    }
}
