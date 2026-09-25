package main

import "testing"

func TestSanity(t *testing.T) {
	result := 1 + 1
	expected := 2
	if result != expected {
		t.Errorf("Sanity check failed: got %d, want %d", result, expected)
	}
}
