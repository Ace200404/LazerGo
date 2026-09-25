package main

import "testing"

func TestHealthCheck(t *testing.T) {
	status := HealthCheck()
	expected := "OK"

	if status != expected {
		t.Errorf("HealthCheck() = %s; want %s", status, expected)
	}
}

func TestMainFunction(t *testing.T) {
	main()
}
