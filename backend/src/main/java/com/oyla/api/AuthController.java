package com.oyla.api;

import com.oyla.service.AuthService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthService auth;
    public AuthController(AuthService auth) { this.auth = auth; }

    @PostMapping("/code/request") public ResponseEntity<CodeRequested> request(@Valid @RequestBody CodeRequest body) {
        final var developmentCode = auth.requestCode(body.email());
        return ResponseEntity.accepted().body(new CodeRequested("If the address can receive mail, a code has been sent.", developmentCode.orElse(null)));
    }
    @PostMapping("/code/verify") public AuthService.TokenPair verify(@Valid @RequestBody CodeVerify body) { return auth.verify(body.email(), body.code()); }
    @PostMapping("/refresh") public AuthService.TokenPair refresh(@Valid @RequestBody TokenRequest body) { return auth.refresh(body.refreshToken()); }
    @PostMapping("/logout") @ResponseStatus(HttpStatus.NO_CONTENT) public void logout(@Valid @RequestBody TokenRequest body) { auth.revoke(body.refreshToken()); }

    public record CodeRequest(@NotBlank @Email @Size(max=320) String email) {}
    public record CodeVerify(@NotBlank @Email @Size(max=320) String email, @Pattern(regexp="[0-9]{6}") String code) {}
    public record TokenRequest(@NotBlank @Size(max=200) String refreshToken) {}
    public record CodeRequested(String message, String developmentCode) {}
}
