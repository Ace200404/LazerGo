package main

import "fmt"

// HealthCheck returns the operational status of the server placeholder.
func HealthCheck() string {
	return "OK"
}

func main() {
	fmt.Println("Server status:", HealthCheck())
}
