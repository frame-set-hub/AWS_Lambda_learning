package com.example.lambda.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.lambda.LambdaClient;
import software.amazon.awssdk.services.lambda.model.InvokeRequest;
import software.amazon.awssdk.services.lambda.model.InvokeResponse;

@Service
public class LambdaService {

    private static final Logger log = LoggerFactory.getLogger(LambdaService.class);

    private final LambdaClient lambdaClient;
    private final String functionName;

    public LambdaService(LambdaClient lambdaClient,
                         @Value("${aws.lambda.function-name}") String functionName) {
        this.lambdaClient = lambdaClient;
        this.functionName = functionName;
    }

    /**
     * Invoke Lambda synchronously and return the response body.
     */
    public String invoke(String payload) {
        log.info("Invoking Lambda [{}] with payload: {}", functionName, payload);

        InvokeRequest request = InvokeRequest.builder()
                .functionName(functionName)
                .payload(SdkBytes.fromUtf8String(payload))
                .build();

        InvokeResponse response = lambdaClient.invoke(request);

        String responseBody = response.payload().asUtf8String();
        int statusCode = response.statusCode();

        log.info("Lambda response (HTTP {}): {}", statusCode, responseBody);

        if (response.functionError() != null) {
            log.error("Lambda function error: {}", response.functionError());
            throw new RuntimeException("Lambda invocation failed: " + response.functionError());
        }

        return responseBody;
    }
}
