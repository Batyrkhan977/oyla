package com.oyla.api;

import com.oyla.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(AuthService.InvalidCodeException.class)
    ResponseEntity<ApiError> invalidCode(HttpServletRequest request) { return error(HttpStatus.UNAUTHORIZED, "INVALID_CODE", "The code is invalid or expired.", request); }
    @ExceptionHandler(AuthService.InvalidTokenException.class)
    ResponseEntity<ApiError> invalidToken(HttpServletRequest request) { return error(HttpStatus.UNAUTHORIZED, "INVALID_TOKEN", "The session is invalid or expired.", request); }
    @ExceptionHandler(AuthService.TooManyRequestsException.class)
    ResponseEntity<ApiError> rateLimited(HttpServletRequest request) { return error(HttpStatus.TOO_MANY_REQUESTS, "TRY_LATER", "Please wait before requesting another code.", request); }
    @ExceptionHandler(SyncController.SyncConflictException.class)
    ResponseEntity<ApiError> syncConflict(HttpServletRequest request) { return error(HttpStatus.CONFLICT, "SYNC_CONFLICT", "A record with this identifier has different content or ownership.", request); }
    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<ApiError> integrityConflict(HttpServletRequest request) { return error(HttpStatus.CONFLICT, "DATA_CONFLICT", "The requested change conflicts with existing data.", request); }
    @ExceptionHandler({MethodArgumentNotValidException.class, IllegalArgumentException.class})
    ResponseEntity<ApiError> invalidRequest(Exception ignored, HttpServletRequest request) { return error(HttpStatus.BAD_REQUEST, "INVALID_REQUEST", "Check the request and try again.", request); }
    private ResponseEntity<ApiError> error(HttpStatus status, String code, String message, HttpServletRequest request) {
        final String requestId = request.getHeader("X-Request-ID") == null ? UUID.randomUUID().toString() : request.getHeader("X-Request-ID");
        return ResponseEntity.status(status).body(new ApiError(code, message, requestId));
    }
    public record ApiError(String code, String message, String requestId) {}
}
