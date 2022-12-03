package main

import (
    "fmt"
    "io"
    "net/http"
    "regexp"
    "time"
)

var IPv4RE = regexp.MustCompile(`(?:\d{1,3}\.){3}\d{1,3}`)

func publicAPI(value string) (string, error) {
    url := "https://" + value

    httpClient := http.Client{
        Timeout: 30 * time.Second,
    }

    response, err := httpClient.Get(url)
    if err != nil {
        return "", err
    }

    defer response.Body.Close()

    body, err := io.ReadAll(response.Body)
    if err != nil {
        return "", err
    }

    return firstIPv4InString(string(body))
}

func firstIPv4InString(body string) (string, error) {
    matches := IPv4RE.FindAllString(body, -1)
    if len(matches) == 0 {
        return "", fmt.Errorf("No IPv4 found in: %q", body)
    }

    return matches[0], nil
}

func publicIPStats(duration time.Duration, server string, outputCSV bool) {
    var stopAfter <-chan time.Time
    var err error

    successCount := 0
    failureCount := 0
    stopAfter = time.After(duration)
    publicIP := ""

    for {
        select {
        case <-stopAfter:
            if outputCSV {
                fmt.Printf("%q, %d, %d\n", server, successCount, failureCount)
            } else {
                fmt.Printf("Server: %q, public IP is %s, number of successful API calls: %d, failureCount: %d\n", server, publicIP, successCount, failureCount)
            }
            return
        default:
            publicIP, err = publicAPI(server)
            if err != nil {
                //fmt.Println("Error resolving the public IP: %v", err)
                failureCount++
            } else {
                successCount++
            }
        }
    }
    return
}

func main() {
    serverList := []string{"ip4.seeip.org", "ipecho.net/plain", "ifconfig.me", "ipinfo.io/ip", "4.ident.me",
        "checkip.amazonaws.com", "4.icanhazip.com", "myexternalip.com/raw", "4.tnedi.me", "api.ipify.org",
    }

    duration := 1 * time.Second

    fmt.Println("Test duration: ", duration)
    for _, server := range serverList {
        publicIPStats(duration, server, true)
    }

    return
}