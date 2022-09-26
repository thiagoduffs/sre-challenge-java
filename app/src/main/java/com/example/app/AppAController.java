package com.example.app;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AppAController {

	@GetMapping(path = "/")
	public String helloWorld() {
		return "{\"message\":\"Olá mundo!\"}";
	}
}