package main

import "testing"

func TestAddistion(t *testing.T) {
	result := 1 + 1
	expected := 2
	if result != expected {
		t.Errorf("Expected %d, but got %d", expected, result)
	}
}
