package main

import (
	"fmt"
	"log"
	"net/http"

	"time"
)

var ch chan int = make(chan int)
var ch_timeout <-chan time.Time = make(chan time.Time)

func thread1() {
	for {
		select {
		case cmd := <-ch:
			if cmd == 0 {
				fmt.Println("d")
				ch_timeout = nil
			} else {
				fmt.Println("e")
				ch_timeout = time.After(time.Second * time.Duration(cmd))
			}
		case <-ch_timeout:
			fmt.Println("d")
		}
	}
}
func mainHandler(w http.ResponseWriter, r *http.Request) {
	w.Header()["Content-Type"] = []string{"text/html"}
	r.ParseForm()
	act := r.Form["act"]
	if act != nil && len(act) > 0 {
		if act[0] == "5s" {
			ch <- 5
		} else if act[0] == "10s" {
			ch <- 10
		} else if act[0] == "30s" {
			ch <- 30
		} else if act[0] == "5m" {
			ch <- 5*60
		} else if act[0] == "15m" {
			ch <- 15*60
		} else if act[0] == "1h" {
			ch <- 60*60
		} else {
			ch <- 0
		}
	}
	fmt.Fprintf(w, "%s\n", `
	<html>
	<head>
		<meta name="viewport" content="width=device-width; initial-scale=2.0; user-scalable=1;" />
	</head>
	<body style="line-height: 35px;">
	`)
	fmt.Fprintf(w, "<form method=\"post\">\n")
	fmt.Fprintf(w, "<input type=\"submit\" name=\"act\" value=\"5s\" />\n")
	fmt.Fprintf(w, "<input type=\"submit\" name=\"act\" value=\"10s\" /><br />\n")
	fmt.Fprintf(w, "<input type=\"submit\" name=\"act\" value=\"30s\" />\n")
	fmt.Fprintf(w, "<input type=\"submit\" name=\"act\" value=\"5m\" /><br />\n")
	fmt.Fprintf(w, "<input type=\"submit\" name=\"act\" value=\"15m\" />\n")
	fmt.Fprintf(w, "<input type=\"submit\" name=\"act\" value=\"1h\" /><br />\n")
	fmt.Fprintf(w, "<input type=\"submit\" name=\"act\" value=\"stop\" /><br />\n")
	fmt.Fprintf(w, "</form>\n</body>\n</html>")
}
func main() {
	go thread1()
	http.HandleFunc("/rctrl123", mainHandler)
	log.Fatal(http.ListenAndServe(":8989", nil))
}
